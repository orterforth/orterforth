#include <stdint.h>

#include <exec/types.h>
#include <exec/memory.h>
#include <exec/io.h>
#include <exec/ports.h>
#include <devices/conunit.h>
#include <devices/serial.h>

#include <clib/exec_protos.h>
#include <clib/alib_protos.h>
#include <clib/intuition_protos.h>

#include <intuition/intuition.h>

#include "../../rf.h"

char *rf_origin = 0;

static struct MsgPort  *ConsoleMP;
static struct IOStdReq *ConsIO;
static struct Window   *win = 0;
static struct NewWindow nw = {
    10, 10,
    620, 180,
    -1, -1,
    CLOSEWINDOW,
    WINDOWDEPTH|WINDOWSIZING|WINDOWDRAG|WINDOWCLOSE|SIMPLE_REFRESH|ACTIVATE,
    0,
    0,
    "orterforth",
    0,
    0,
    100, 45,
    640, 200,
    WBENCHSCREEN
};

static struct MsgPort  *SerialMP;
static struct IOExtSer *SerialIO;

static uint8_t          b;

void rf_init(void)
{
    /* memory */
    rf_origin = AllocMem(RF_MEMORY_SIZE, MEMF_ANY);

    /* console */
    ConsoleMP = CreatePort("RKM.Console",0);
    ConsIO = (struct IOStdReq *) CreateExtIO(ConsoleMP, sizeof(struct IOStdReq));
    win = OpenWindow(&nw);
    ConsIO->io_Data = (APTR) win;
    ConsIO->io_Length = sizeof(struct Window);
    OpenDevice("console.device", CONU_CHARMAP, (struct IORequest *) ConsIO, CONFLAG_DEFAULT);

    /* serial port */
    SerialMP = CreatePort(0, 0);
    SerialIO = (struct IOExtSer *) CreateExtIO(SerialMP, sizeof(struct IOExtSer));
    SerialIO->io_SerFlags = SERF_SHARED;
    OpenDevice(SERIALNAME, 0L, (struct IORequest *) SerialIO, 0);
}

void rf_console_put(uint8_t c)
{
    ConsIO->io_Data    = (APTR) &c;
    ConsIO->io_Length  = 1;
    ConsIO->io_Command = CMD_WRITE;
    DoIO((struct IORequest *) ConsIO);

    if (c == 0x08) {
        rf_console_put(0x20);
        c = 0x08;
        ConsIO->io_Data    = (APTR) &c;
        ConsIO->io_Length  = 1;
        ConsIO->io_Command = CMD_WRITE;
        DoIO((struct IORequest *) ConsIO);
    }
}

uint8_t rf_console_get(void)
{
    ConsIO->io_Data    = (APTR) &b;
    ConsIO->io_Length  = 1;
    ConsIO->io_Command = CMD_READ;
    DoIO((struct IORequest *) ConsIO);

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
    rf_console_put('\n');
}

uint8_t rf_serial_get(void)
{
    SerialIO->IOSer.io_Length   = 1;
    SerialIO->IOSer.io_Data     = (APTR) &b;
    SerialIO->IOSer.io_Command  = CMD_READ;
    DoIO((struct IORequest *) SerialIO);

    return b;
}

void rf_serial_put(uint8_t c)
{
    SerialIO->IOSer.io_Length   = 1;
    SerialIO->IOSer.io_Data     = (APTR) &c;
    SerialIO->IOSer.io_Command  = CMD_WRITE;
    DoIO((struct IORequest *) SerialIO);
}

void rf_fin(void)
{
    CloseDevice((struct IORequest *) SerialIO);
    DeleteMsgPort(SerialMP);
    CloseDevice((struct IORequest *) ConsIO);
    DeleteMsgPort(ConsoleMP);
    FreeMem(rf_origin, RF_MEMORY_SIZE);
}
