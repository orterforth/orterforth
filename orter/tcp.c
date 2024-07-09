#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#include "tcp.h"

static int orter_tcp_sock_fd = -1;

int orter_tcp_fd = -1;

int orter_tcp_client_open(int port)
{
  char *host = "127.0.0.1";
  int exit = 0;
  struct sockaddr_in serv_addr; 

  /* socket */
  if (orter_tcp_fd >= 0) {
    fputs("tcp already open", stderr);
    return 1;
  }
  if ((orter_tcp_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
    perror("socket failed");
    return errno;
  }

  /* connect */
  memset(&serv_addr, '0', sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_port = htons(port);
  exit = inet_pton(AF_INET, host, &serv_addr.sin_addr);
  if (exit < 0) {
    exit = errno;
    perror("inet_pton failed");
    orter_tcp_close();
    return exit;
  }
  if (!exit) {
    fprintf(stderr, "inet_pton failed: host=%s\n", host);       
    orter_tcp_close();
    return exit;
  } 
  if (connect(orter_tcp_fd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0) {
    exit = errno;
    perror("connect failed");
    orter_tcp_close();
    return exit;
  } 

  /* nonblocking */
  if (fcntl(orter_tcp_fd, F_SETFL, fcntl(orter_tcp_fd, F_GETFL, 0) | O_NONBLOCK) == -1) {
    exit = errno;
    perror("fcntl failed");
    orter_tcp_close();
    return exit;
  }

  return 0;
}

int orter_tcp_close(void)
{
  int ret = 0;

  if (orter_tcp_fd != -1) {
    ret = close(orter_tcp_fd);
    if (ret) {
      perror("tcp fd close failed");
    }
    orter_tcp_fd = -1;
  }
  if (orter_tcp_sock_fd != -1) {
    ret = close(orter_tcp_sock_fd);
    if (ret) {
      perror("tcp sock close failed");
    }
    orter_tcp_sock_fd = -1;
  }
  return ret;
}

int orter_tcp_open(int port)
{
  int exit = 0;
  int optval = 1;
  struct sockaddr_in svr_addr, cli_addr;
  socklen_t sin_len = sizeof(cli_addr);

  /* validate */
  if (orter_tcp_fd >= 0) {
    fputs("tcp already open", stderr);
    return 1;
  }
  if (orter_tcp_sock_fd >= 0) {
    fputs("tcp socket already open", stderr);
    return 1;
  }
  /* socket */
  orter_tcp_sock_fd = socket(AF_INET, SOCK_STREAM, 0);
  if (orter_tcp_sock_fd < 0) {
    perror("socket failed");
    return errno;
  }
  if (setsockopt(orter_tcp_sock_fd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(int))) {
    exit = errno;
    perror("setsockopt failed");
    orter_tcp_close();
    return exit;
  }

  /* bind, listen, accept */
  svr_addr.sin_family = AF_INET;
  svr_addr.sin_addr.s_addr = INADDR_ANY;
  svr_addr.sin_port = htons(port);
  if (bind(orter_tcp_sock_fd, (struct sockaddr *) &svr_addr, sizeof(svr_addr)) == -1) {
    exit = errno;
    perror("bind failed");
    orter_tcp_close();
    return exit;
  }
  if (listen(orter_tcp_sock_fd, 2)) {
    exit = errno;
    perror("listen failed");
    orter_tcp_close();
    return exit;
  }
  orter_tcp_fd = accept(orter_tcp_sock_fd, (struct sockaddr *) &cli_addr, &sin_len);
  if (orter_tcp_fd == -1) {
    exit = errno;
    perror("accept failed");
    orter_tcp_close();
    return exit;
  }

  /* nonblocking */
  if (fcntl(orter_tcp_fd, F_SETFL, fcntl(orter_tcp_fd, F_GETFL, 0) | O_NONBLOCK) == -1) {
    exit = errno;
    perror("fcntl failed");
    orter_tcp_close();
    return exit;
  }

  return 0;
}
