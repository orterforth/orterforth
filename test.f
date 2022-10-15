
















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
: test-U/ >R >R U/ R> = SWAP R> = AND assert ."  U/" ;
70000000. FFFF 7000 7000 test-U/ ."  16 1" CR
60000000. FFFF 6000 6000 test-U/ ."  16 2" CR
20000000. FFFF 2000 2000 test-U/ ."  16 3" CR
20000000. EFFF 2222 4222 test-U/ ."  16 4" CR
7FFFFFFF. EFFF 8889 1888 test-U/ ."  16 5" CR
7FFFFFFF. FFFF 8000 7FFF test-U/ ."  16 6" CR
7FFFFFFF. 8FFF E38F 738E test-U/ ."  16 7" CR
7FFFFFFF. 800F FFE2 01C1 test-U/ ."  16 8" CR
90000000. A000 E666 4000 test-U/ ."  16 9" CR
0000 0004 0004   -1   -1 test-U/ ."  overflow" CR
00000001. 0000   -1   -1 test-U/ ."  division by zero" CR

-->
( D+                                                          )
HEX
: D= ROT = >R = R> AND ;
: test-D+ >R >R D+ R> R> D= assert ."  D+" ;
0000F000. 0000E000. 0001D000. test-D+ ."  16 1" CR
FFFFFFFE. 00000001. FFFFFFFF. test-D+ ."  16 2" CR









-->
( summary                                                     )
DECIMAL
10 SPACES ." tests complete " failures ? ." failures" CR
( segfault if failures to exit nonzero )
: exit failures @ IF ( 100 100 ! )  ENDIF ; exit
;S
