
















6 LOAD ;S






























**********************  fig-FORTH  MODEL  **********************

                     Through the courtesy of

                      FORTH INTEREST GROUP
                         P. O. BOX 1105
                     SAN CARLOS, CA. 94070


                           RELEASE 1
                     WITH COMPILER SECURITY
                             AND
                     VARIABLE LENGTH NAMES


       Further distribution must include the above notice.
(  ERROR MESSAGES  )
EMPTY STACK
DICTIONARY FULL
HAS INCORRECT ADDRESS MODE
ISN'T UNIQUE

DISC RANGE ?
FULL STACK
DISC ERROR !







(  ERROR MESSAGES  )
COMPILATION ONLY, USE IN DEFINITION
EXECUTION ONLY
CONDITIONALS NOT PAIRED
DEFINITION NOT FINISHED
IN PROTECTED DICTIONARY
USE ONLY WHEN LOADING
OFF CURRENT EDITING SCREEN
DECLARE VOCABULARY







( test                                                        )
0 VARIABLE failures
: assert
  IF ." [SUCCESS]" ELSE ." [FAILURE]" 1 failures +! ENDIF
;
CR
-->









( U/                                                          )
HEX
: d32 cl 2 = IF ELSE 10000 * + 0 ENDIF ; ( for word size )
: test-U/ >R >R U/ R> = SWAP R> = AND assert ."  U/" ;
0000 7000 d32 FFFF 7000 7000 test-U/ ."  often wrong 1 " CR
0000 6000 d32 FFFF 6000 6000 test-U/ ."  often wrong 2 " CR
0000 2000 d32 FFFF 2000 2000 test-U/ ."  often wrong 3 " CR
0000 2000 d32 EFFF 2222 4222 test-U/ ."  often wrong 4 " CR
FFFF 7FFF d32 EFFF 8889 1888 test-U/ ."  often wrong 5 " CR
FFFF 7FFF d32 FFFF 8000 7FFF test-U/ ."  often wrong 6 " CR
FFFF 7FFF d32 8FFF E38F 738E test-U/ ."  often wrong 7 " CR
FFFF 7FFF d32 800F FFE2 01C1 test-U/ ."  often wrong 8 " CR
0000 9000 d32 A000 E666 4000 test-U/ ."  often wrong 9 " CR
0000 0004     0004   -1   -1 test-U/ ."  overflow" CR
0001 0000 d32 0000   -1   -1 test-U/ ."  division by zero" CR
-->
( summary                                                     )
DECIMAL
10 SPACES ." tests complete " failures ? ." failures" CR
( segfault if failures to exit nonzero )
: exit failures @ IF ( 100 100 ! )  ENDIF ; exit
;S
