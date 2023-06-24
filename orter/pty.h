#ifndef ORTER_PTY_H_
#define ORTER_PTY_H_

extern int orter_pty_master_fd;

int orter_pty_close(void);

int orter_pty_open(char *link);

int orter_pty(char *link);

#endif /* ORTER_PTY_H_ */
