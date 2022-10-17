#define _DEFAULT_SOURCE
#include <arpa/inet.h>
#include <err.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <unistd.h>

#include "orter/fuse.h"
#include "orter/io.h"
#include "orter/serial.h"
#include "rf_persci.h"

#define RF_BBLK 128

static int disclinetoblock(char *line, int *lineno, FILE *stream, char *block)
{
  size_t len;

  /* read line from input file */
  if (!fgets(line, 80, stream)) {
    if (feof(stream)) {
      return 0;
    }
    perror("fgets failed");
    return errno;
  }

  /* fail if too long */
  (*lineno)++;
  len = strlen(line);
  if (len > 65) {
    fprintf(stderr, "line %u too long\n", *lineno);
    return 1;
  }

  /* write to the block */
  memcpy(block, line, len - 1);

  /* ok */
  return 0;
}

static int disc_create(void)
{
	char line[82]; 
  int lineno = 0;
  char block[RF_BBLK];
  int i, status;

  /* 77 tracks x 26 sectors */
  for (i = 0; i < 2002; i++) {

    /* clear buffer with spaces */
    memset(&block, ' ', RF_BBLK);

    /* read two lines */
    if ((status = disclinetoblock(line, &lineno, stdin, block))) {
      return status;
    }
    if ((status = disclinetoblock(line, &lineno, stdin, block + 64))) {
      return status;
    }

    /* write block to stdout */
    if (fwrite(block, 1, RF_BBLK, stdout) != RF_BBLK) {
      perror("fwrite failed");
      return errno;
    }
  }

  /* ok */
  return 0;
}

/* DISPATCH SERIAL READ/WRITE TO FUNCTION POINTERS */

static orter_io_rdwr_t rd;

static orter_io_rdwr_t wr;

static char fetch = 0;

static size_t disc_wr(char *off, size_t len)
{
  char c;
  size_t i;

  /* log */
  fputs("\033[0;33m", stderr);
  fwrite(off, 1, len, stderr);

  for (i = 0; i < len; i++) {
    c = *(off++);
    rf_persci_putc(c);
    if (c == RF_ASCII_EOT) {
      i++;
      fetch = 1;
      /* log line */
      fputs("\033[0m\n", stderr);
      fflush(stderr);
      break;
    }
  }

  return i;
}

static size_t disc_rd(char *off, size_t len)
{
  char c;
  size_t i;

  /* only attempt to read after EOT sent */
  if (!fetch) {
    return 0;
  }

  for (i = 0; i < len; i++) {
    c = rf_persci_getc();
    *(off++) = c;
    if (c == RF_ASCII_EOT) {
      i++;
      fetch = 0;
      break;
    }
  }

  /* log */
  fwrite(off - i, 1, i, stderr);
  fputc('\n', stderr);
  fflush(stderr);

  return i;
}

static size_t fuse_rd(char *off, size_t len)
{
  size_t i;
  int c;

  for (i = 0; i < len; i++) {
    c = orter_fuse_serial_getc(stdin);
    /* EOF */
    if (c == -1) {
      break;
    }
    off[i] = c;
    /* blocking, but EOT as a terminator */
    if (c == RF_ASCII_EOT) {
      i++;
      break;
    }
  }

  return i;
}

static size_t fuse_wr(char *off, size_t len)
{
  size_t i;

  for (i = 0; i < len; i++) {
    orter_fuse_serial_putc(off[i], stdout);
  }  

  return len;
}

static int tcp_fd;

static size_t tcp_rd(char *off, size_t len)
{
  return orter_io_fd_rd(tcp_fd, off, len);
}

static size_t tcp_wr(char *off, size_t len)
{
  return orter_io_fd_wr(tcp_fd, off, len);
}

/* Server loop */
static int serve(char *dr0, char *dr1)
{
  char           in_buf[256];
  size_t         in_pending = 0;
  char *         in_offset = in_buf;

  char           out_buf[256];
  size_t         out_pending = 0;
  char *         out_offset = out_buf;

  rf_persci_insert(0, dr0);
  rf_persci_insert(1, dr1);

  /* TODO make signal handling general */
  while (!orter_io_finished) {

    /* TODO use select */
    /* don't wait on write fd if input buffer empty */
    /* don't wait on read fd if output buffer full */
    /* sleep if no fds to wait on */
    usleep(100000);

    orter_io_relay(rd, disc_wr, in_buf, &in_offset, &in_pending);
    orter_io_relay(disc_rd, wr, out_buf, &out_offset, &out_pending);
  }

  /* finished */
  return 0;
}

static int setconsoleunbuffered(void)
{
  if (setvbuf(stdin, NULL, _IONBF, 0)) {
    perror("setvbuf stdin failed");
    return errno;
  }
  if (setvbuf(stdout, NULL, _IONBF, 0)) {
    perror("setvbuf stdout failed");
    return errno;
  }
  return 0;
}

static int disc_fuse(int argc, char **argv)
{
  if (setconsoleunbuffered()) {
    return 1;
  }
  rd = fuse_rd;
  wr = fuse_wr;

  return serve(argv[2], argv[3]);
}

static int disc_serial(int argc, char **argv)
{
  orter_serial_open(argv[2], atoi(argv[3]));
  rd = orter_serial_rd;
  wr = orter_serial_wr;

  serve(argv[4], argv[5]);
  orter_serial_close();
  /* TODO pass exit codes */
  return 0;
}

static int disc_standard(int argc, char **argv)
{
  if (setconsoleunbuffered()) {
    return 1;
  }
  rd = orter_io_stdin_rd;
  wr = orter_io_stdout_wr;

  return serve(argv[2], argv[3]);
}

static int disc_tcp(int argc, char **argv)
{
  int optval = 1;
  int sock;
  int port;
  int status;
  struct sockaddr_in svr_addr, cli_addr;
  socklen_t sin_len = sizeof(cli_addr);

  /* socket */
  sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0) {
    perror("socket failed");
    return 1;
  }
  if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(int))) {
    perror("setsockopt failed");
    close(sock);
    return 1;
  }

  /* bind, listen, accept */
  port = atoi(argv[2]);
  svr_addr.sin_family = AF_INET;
  svr_addr.sin_addr.s_addr = INADDR_ANY;
  svr_addr.sin_port = htons(port);
  if (bind(sock, (struct sockaddr *) &svr_addr, sizeof(svr_addr)) == -1) {
    perror("bind failed");
    close(sock);
    return 1;
  }
  if (listen(sock, 2)) {
    perror("listen failed");
    close(sock);
    return 1;
  }
  tcp_fd = accept(sock, (struct sockaddr *) &cli_addr, &sin_len);
  if (tcp_fd == -1) {
    perror("accept failed");
    close(sock);
    return 1;
  }

  /* nonblocking */
  status = fcntl(tcp_fd, F_SETFL, fcntl(tcp_fd, F_GETFL, 0) | O_NONBLOCK);
  if (status == -1) {
    perror("fcntl failed");
    close(sock);
    return 1;
  }

  /* bind the fps */
  rd = tcp_rd;
  wr = tcp_wr;

  return serve(argv[3], argv[4]);

  /* TODO close socket */
}

int main(int argc, char *argv[])
{
  /* Text file to Forth block disc image */
  if (argc == 2 && !strcmp("create", argv[1])) {
    return disc_create();
  }

  /* Console with Fuse Emulator RS232 fifo escape */
  if (argc == 4 && !strcmp("fuse", argv[1])) {
    return disc_fuse(argc, argv);
  }

  /* Physical serial port */
  if (argc == 6 && !strcmp("serial", argv[1])) {
    return disc_serial(argc, argv);
  }

  /* Console */
  if (argc == 4 && !strcmp("standard", argv[1])) {
    return disc_standard(argc, argv);
  }

  /* TCP */
  if (argc == 5 && !strcmp("tcp", argv[1])) {
    return disc_tcp(argc, argv);
  }

  /* Usage */
  fputs("Usage: disc create                           Convert text file (stdin) into Forth block format (stdout)\n", stderr);
  fputs("       disc fuse <dr0> <dr1>                 Run disc controller over stdin/stdout with Fuse Emulator escape\n", stderr);
  fputs("       disc serial <name> <baud> <dr0> <dr1> Run disc controller over physical serial port\n", stderr);
  fputs("       disc standard <dr0> <dr1>             Run disc controller over stdin/stdout\n", stderr);
  fputs("       disc tcp <port> <dr0> <dr1>           Run disc controller over tcp port\n", stderr);
  return 1;
}
