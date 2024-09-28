#ifndef ORTER_TCP_H_
#define ORTER_TCP_H_

extern int orter_tcp_fd;

int orter_tcp_client_open(int port);

int orter_tcp_server_open(int port);

int orter_tcp_close(void);

int orter_tcp(int argc, char *argv[]);

#endif /* ORTER_TCP_H_ */
