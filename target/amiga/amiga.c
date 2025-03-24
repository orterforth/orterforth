#include <stdint.h>

#include <devices/conunit.h>
#include <devices/keyboard.h>
#include <devices/serial.h>

#include <clib/exec_protos.h>
#include <clib/alib_protos.h>
#include <clib/intuition_protos.h>

#include "../../rf.h"

char *rf_origin = 0;

static struct MsgPort  *ConsoleMP;
static struct IOStdReq *ConsIO;
static struct Window   *win;
static struct NewWindow nw = {
    0, 0,
    640, 200,
    -1, -1,
    CLOSEWINDOW,
    WINDOWDEPTH|WINDOWDRAG|WINDOWCLOSE|SIMPLE_REFRESH|ACTIVATE,
    0,
    0,
    "orterforth",
    0,
    0,
    100, 45,
    640, 200,
    WBENCHSCREEN
};

#define MATRIX_SIZE 16L

extern struct Library  *SysBase;
static struct IOStdReq *KeyIO;
static struct MsgPort  *KeyMP;
static uint8_t         keyMatrix[16];
static uint8_t         keyIOLength;

static struct MsgPort  *SerialMP;
static struct IOExtSer *SerialIO;
static struct IOStdReq *IOSer;

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
    OpenDevice("console.device", CONU_STANDARD, (struct IORequest *) ConsIO, CONFLAG_DEFAULT);

    /* keyboard */
    KeyMP = CreatePort(0, 0);
    KeyIO = (struct IOStdReq *) CreateExtIO(KeyMP, sizeof(struct IOStdReq));
    OpenDevice("keyboard.device", NULL, (struct IORequest *) KeyIO, NULL);
    keyIOLength = SysBase->lib_Version >= 36 ? MATRIX_SIZE : 13;

    /* serial port */
    SerialMP = CreatePort(0, 0);
    SerialIO = (struct IOExtSer *) CreateExtIO(SerialMP, sizeof(struct IOExtSer));
    SerialIO->io_SerFlags = SERF_SHARED;
    IOSer = &SerialIO->IOSer;
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
    KeyIO->io_Data    = (APTR) &keyMatrix;
    KeyIO->io_Length  = keyIOLength;
    KeyIO->io_Command = KBD_READMATRIX;
    DoIO((struct IORequest *) KeyIO);
    /* ESC, key code 0x45 */
    return (keyMatrix[8] & 0x20) != 0;
}

void rf_console_cr(void)
{
    rf_console_put('\n');
}

uint8_t rf_serial_get(void)
{
    IOSer->io_Length   = 1;
    IOSer->io_Data     = (APTR) &b;
    IOSer->io_Command  = CMD_READ;
    DoIO((struct IORequest *) SerialIO);
    return b;
}

void rf_serial_put(uint8_t c)
{
    IOSer->io_Length   = 1;
    IOSer->io_Data     = (APTR) &c;
    IOSer->io_Command  = CMD_WRITE;
    DoIO((struct IORequest *) SerialIO);
}

void rf_fin(void)
{
    CloseDevice((struct IORequest *) SerialIO);
    DeletePort(SerialMP);

    CloseDevice((struct IORequest *) KeyIO);
    DeleteExtIO((struct IORequest *) KeyIO);
    DeletePort(KeyMP);

    CloseDevice((struct IORequest *) ConsIO);
    CloseWindow(win);
    DeletePort(ConsoleMP);
    FreeMem(rf_origin, RF_MEMORY_SIZE);
}
