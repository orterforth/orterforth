















































( orterforth library                                          )















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







( Hello World                                                 )
." Hello World" CR













;S
( Fibonacci sequence                                          )
FORTH DEFINITIONS VOCABULARY fib IMMEDIATE fib DEFINITIONS
: length                        ( Overflows after this point  )
  cl 2 = IF 23 ENDIF
  cl 4 = IF 46 ENDIF
  cl 8 = IF 92 ENDIF ;
: list                          ( Print the whole sequence    )
  0 1
  length 0 DO
    SWAP OVER + DUP 0 D.
  LOOP ;

CR fib list CR


;S
( Factorial                                                   )
FORTH DEFINITIONS VOCABULARY fac IMMEDIATE fac DEFINITIONS
: length                        ( Overflows after this point  )
  cl 2 = IF 9 ENDIF
  cl 4 = IF 14 ENDIF
  cl 8 = IF 22 ENDIF ;
: list
  1 length 1 DO
    I * DUP 0 D.
  LOOP ;

CR fac list CR



;S
( Reverse a string                                            )
10 LOAD                        ( load str vocabulary          )
FORTH
: s1 str " Hello World, this is a string." ;
HERE s1 C@ 1+ ln ALLOT CONSTANT s2
: reverse                      ( s1 s2 --                     )
  OVER C@ >R                   ( save length                  )
  R OVER C!                    ( write length                 )
  R + SWAP                     ( get pointer to end of str 2  )
  1+ DUP R + SWAP DO           ( iterate over string 1        )
    I C@ OVER C! -1 +          ( copy byte, decrement ptr     )
  LOOP DROP R> DROP ;          ( done, discard len and ptr    )
s1 s2 reverse CR               ( reverse s1 into s2           )
." s1: " s1 COUNT TYPE CR      ( print them both              )
." s2: " s2 COUNT TYPE CR
;S
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
