#ifdef _CMOC_VERSION_
#include <cmoc.h>
#else
#ifndef HX20
#include <stdio.h>
#endif
#endif

/* Hello World is useful when implementing a new target. */
int main(int argc, char **argv)
{
#ifndef HX20
  printf("Hello World\n");
#endif
  return 0;
}
