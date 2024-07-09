#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include <exec/types.h>
#include <exec/memory.h>
#include <exec/io.h>
#include <devices/serial.h>

#include <clib/exec_protos.h>
#include <clib/alib_protos.h>

char *rf_origin = 0;

static struct MsgPort  *SerialMP;
static struct IOExtSer *SerialIO;

void rf_init(void)
{
    /* memory */
    rf_origin = malloc(131072);

    /* serial port */
    SerialMP = CreatePort(0, 0);
    SerialIO = (struct IOExtSer *) CreateExtIO(SerialMP, sizeof(struct IOExtSer));
    SerialIO->io_SerFlags = SERF_SHARED;
    OpenDevice(SERIALNAME, 0L, (struct IORequest *) SerialIO, 0);
}

void rf_console_put(uint8_t c)
{
    putchar(c);
}

uint8_t rf_console_get(void)
{
    uint8_t b = getchar();

    /* LF -> CR */
    if (b == 10) {
      b = 13;
    }

    return b;
}

uint8_t rf_console_qterm(void)
{
    return 0;
}

void rf_console_cr(void)
{
    putchar('\n');
}

uint8_t rf_serial_get(void)
{
    uint8_t b;

    SerialIO->IOSer.io_Length   = 1;
    SerialIO->IOSer.io_Data     = (APTR) &b;
    SerialIO->IOSer.io_Command  = CMD_READ;

    DoIO((struct IORequest *)SerialIO);

    return b;
}

void rf_serial_put(uint8_t b)
{
    SerialIO->IOSer.io_Length   = 1;
    SerialIO->IOSer.io_Data     = (APTR) &b;
    SerialIO->IOSer.io_Command  = CMD_WRITE;

    DoIO((struct IORequest *)SerialIO);
}

void rf_fin(void)
{
    CloseDevice((struct IORequest *)SerialIO);
    DeleteMsgPort(SerialMP);
}
