#ifdef _CMOC_VERSION_
#include <cmoc.h>
#else
#ifndef CC6303
#include <stdio.h>
#endif
#endif

/* Hello World is useful when implementing a new target. */
int main(int argc, char **argv)
{
#ifndef CC6303
  printf("Hello World\n");
#endif
  return 0;
}
