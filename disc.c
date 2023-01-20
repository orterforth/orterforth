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

#include "orter/io.h"
#include "orter/serial.h"
#include "orter/spectrum.h"
#include "persci.h"

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

static int in_fd = -1;

static int out_fd = -1;

static orter_io_rdwr_t rd;

static orter_io_rdwr_t wr;

static char fetch = 0;

static char log = 1;

static size_t disc_wr(char *off, size_t len)
{
  char c;
  size_t i;

  /* log */
  if (log) {
    fputs("\033[0;33m", stderr);
    fwrite(off, 1, len, stderr);
  }

  for (i = 0; i < len; i++) {
    c = *(off++);
    rf_persci_putc(c);
    if (c == RF_ASCII_EOT) {
      i++;
      fetch = 1;
      /* log line */
      if (log) {
        fputs("\033[0m\n", stderr);
        fflush(stderr);
      }
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
  if (log) {
    fwrite(off - i, 1, i, stderr);
    fputc('\n', stderr);
    fflush(stderr);
  }

  return i;
}

static size_t fuse_rd(char *off, size_t len)
{
  size_t i;
  int c;

  for (i = 0; i < len; i++) {
    c = orter_spectrum_fuse_serial_getc(stdin);
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
    orter_spectrum_fuse_serial_putc(off[i], stdout);
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

static size_t serial_mux_rd(char *off, size_t len)
{
  char buf[256], out[256];
  size_t i, j = 0, k = 0;
  /* read for disc and console output */
  size_t size = orter_io_fd_rd(orter_serial_fd, buf, len);
  for (i = 0; i < size; i++) {
    char c = buf[i];
    if (c & 0x80) {
      off[j++] = c & 0x7F;
    } else {
      out[k++] = c;
    }
  }
  /* console output */
  size = orter_io_fd_wr(1, out, k);
  return j;
}

static size_t serial_mux_wr(char *off, size_t len)
{
  char buf[256];
  size_t i, k = 0, size;
  /* console input */
  k = orter_io_fd_rd(0, buf, 256);
  size = orter_io_fd_wr(orter_serial_fd, buf, k);
  /* if any issue writing keys then fail */
  if (size != k) {
    return 0;
  }
  /* disc */
  for (i = 0; i < len; i++) {
    buf[i] = off[i] | 0x80;
  }
  size = orter_io_fd_wr(orter_serial_fd, buf, len);
  return size;
}

/* Server loop */
static int serve(char *dr0, char *dr1)
{
  orter_io_pipe_t in;
  orter_io_pipe_t out;

  /* insert the disc image files */
  rf_persci_insert(0, dr0);
  rf_persci_insert(1, dr1);

  /* create pipes */
  orter_io_pipe_init(&in, in_fd, rd, disc_wr, -1);
  orter_io_pipe_init(&out, -1, disc_rd, wr, out_fd);

  while (!orter_io_finished) {

    /* NB not completely converted to select */
    if (in_fd == -1 && out_fd == -1) {
      usleep(1000000);
    } else {
      /* init fd sets */
      orter_io_select_zero();

      /* add to fd sets */
      orter_io_pipe_fdset(&in);
      orter_io_pipe_fdset(&out);

      /* select */
      if (orter_io_select() < 0) {
        break;
      }
    }

    /* disc in to disc controller */
    orter_io_pipe_move(&in);
    /* disc controller to disc out */
    orter_io_pipe_move(&out);
  }

  /* finished */
  return orter_io_exit;
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
  int exit = 0;

  /* signals TODO explain */
  orter_io_signal_init();

  /* serial port */
  exit = orter_serial_open(argv[2], atoi(argv[3]));
  if (exit) {
    return exit;
  }

  /* create pipelines */
  rd = orter_serial_rd;
  in_fd = orter_serial_fd;
  wr = orter_serial_wr;
  out_fd = orter_serial_fd;

  /* run */
  exit = serve(argv[4], argv[5]);

  /* close and exit */
  orter_serial_close();
  return exit;
}

static int disc_mux(int argc, char **argv)
{
  int exit = 0;

  /* stdin/stdout */
  exit = setconsoleunbuffered();
  if (exit) {
    return exit;
  }
  exit = orter_io_std_open();
  if (exit) {
    return exit;
  }

  /* signals TODO explain */
  orter_io_signal_init();

  /* serial port */
  exit = orter_serial_open(argv[2], atoi(argv[3]));
  if (exit) {
    orter_io_std_close();
    return exit;
  }

  /* create pipelines */
  rd = serial_mux_rd;
  in_fd = orter_serial_fd;
  wr = serial_mux_wr;
  out_fd = orter_serial_fd;

  /* don't log as we are using the console for output */
  log = 0;

  /* run */
  exit = serve(argv[4], argv[5]);

  /* close and exit */
  orter_serial_close();
  orter_io_std_close();
  return exit;
}

static int disc_standard(int argc, char **argv)
{
  if (setconsoleunbuffered()) {
    return 1;
  }
  rd = orter_io_stdin_rd;
  in_fd = 0;
  wr = orter_io_stdout_wr;
  out_fd = 1;

  return serve(argv[2], argv[3]);
}

static int disc_tcp(int argc, char **argv)
{
  int exit = 0;

  int optval = 1;
  int sock;
  int port;
  struct sockaddr_in svr_addr, cli_addr;
  socklen_t sin_len = sizeof(cli_addr);

  /* socket */
  sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock < 0) {
    perror("socket failed");
    return 1;
  }
  if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(int))) {
    exit = errno;
    perror("setsockopt failed");
    close(sock);
    return exit;
  }

  /* bind, listen, accept */
  port = atoi(argv[2]);
  svr_addr.sin_family = AF_INET;
  svr_addr.sin_addr.s_addr = INADDR_ANY;
  svr_addr.sin_port = htons(port);
  if (bind(sock, (struct sockaddr *) &svr_addr, sizeof(svr_addr)) == -1) {
    exit = errno;
    perror("bind failed");
    close(sock);
    return exit;
  }
  if (listen(sock, 2)) {
    exit = errno;
    perror("listen failed");
    close(sock);
    return exit;
  }
  tcp_fd = accept(sock, (struct sockaddr *) &cli_addr, &sin_len);
  if (tcp_fd == -1) {
    exit = errno;
    perror("accept failed");
    close(sock);
    return exit;
  }

  /* nonblocking */
  if (fcntl(tcp_fd, F_SETFL, fcntl(tcp_fd, F_GETFL, 0) | O_NONBLOCK) == -1) {
    exit = errno;
    perror("fcntl failed");
    close(sock);
    return exit;
  }

  /* bind the fps */
  rd = tcp_rd;
  in_fd = tcp_fd;
  wr = tcp_wr;
  out_fd = tcp_fd;

  exit = serve(argv[3], argv[4]);

  close(sock);

  return exit;
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

  /* Physical serial port but multiplex serial and disc */
  if (argc == 6 && !strcmp("mux", argv[1])) {
    return disc_mux(argc, argv);
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
  fputs("       disc mux <name> <baud> <dr0> <dr1>    Run disc controller over physical serial port and multiplex with the console\n", stderr);
  fputs("       disc serial <name> <baud> <dr0> <dr1> Run disc controller over physical serial port\n", stderr);
  fputs("       disc standard <dr0> <dr1>             Run disc controller over stdin/stdout\n", stderr);
  fputs("       disc tcp <port> <dr0> <dr1>           Run disc controller over tcp port\n", stderr);
  return 1;
}
