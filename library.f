















































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







( library                                                     )
7 LOAD ;S














( str: Forth/Pascal string handling                           )
FORTH VOCABULARY str IMMEDIATE str DEFINITIONS DECIMAL
: (") R> DUP COUNT + >R ;      ( return string and advance IP )
: "                            ( -- )
  ?COMP                        ( compilation only             )
  COMPILE (")                  ( execution time routine       )
  34 WORD                      ( read until "                 )
  HERE C@ 1+ ALLOT             ( compile the string           )
; IMMEDIATE

: copy                         ( a b -- )
  OVER C@                      ( get length                   )
  1+ CMOVE ;                   ( copy length+1 bytes          )

-->

( str: append                                                 )
: append                       ( a b -- )
  OVER C@ OVER C@              ( get the two lengths          )
  255 SWAP - MIN >R            ( limit append to max length   )
  OVER OVER                    ( dup both string addrs        )
  COUNT +                      ( move to the end of b         )
  SWAP 1+ R                    ( count a                      )
  ROT SWAP CMOVE               ( copy into b                  )
  SWAP C@ OVER C@ +            ( get the total count          )
  SWAP C!                      ( write it to b                )
  R> DROP
; ( TODO optimise now R is used to hold length )



-->
( str: take, drop                                             )
: take                         ( a n -- )
  OVER C@ MIN                  ( limit to the string length )
  SWAP C!                      ( write new length )
;

: drop                         ( a n -- )
  OVER C@ MIN                  ( limit to the string length )
  >R DUP                       ( save a and modified n )
  DUP 1+ R +                   ( from )
  OVER 1+                      ( to )
  ROT C@ R -                   ( count )
  CMOVE                        ( copy the rest )         
  DUP C@ R> - SWAP C!          ( update the length )
;
-->
( str: new                                                    )

: alloc HERE SWAP ALLOT ;       ( size -- addr )
: new 1+ alloc ;                ( length -- addr )











-->
