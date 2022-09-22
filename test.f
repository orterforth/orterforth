
















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
: test-U/ >R >R U/ R> = SWAP R> = AND assert ."  U/" ;
HEX
: tests-U/
  8 0 4                2  0 test-U/ ."  high word zero" CR
  8 1 4 rcll 8 = IF
        4000000000000002 ENDIF
        rcll 4 = IF
                40000002 ENDIF
        rcll 2 = IF
                    4002 ENDIF
                          0 test-U/ ."  high word nonzero" CR
  0 4 1               -1 -1 test-U/ ."  overflow" CR
  1 0 0               -1 -1 test-U/ ."  division by zero" CR
;
tests-U/ -->
( summary                                                     )
DECIMAL
10 SPACES ." tests complete " failures ? ." failures" CR
( segfault if failures to exit nonzero )
: exit failures @ IF 100 100 ! ENDIF ; exit
;S
