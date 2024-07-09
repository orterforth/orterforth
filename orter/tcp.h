#ifndef ORTER_TCP_H_
#define ORTER_TCP_H_

extern int orter_tcp_fd;

int orter_tcp_client_open(int port);

int orter_tcp_open(int port);

int orter_tcp_close(void);

#endif /* ORTER_TCP_H_ */
