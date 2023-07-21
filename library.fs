















































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







( examples index                                              )
FORTH DEFINITIONS VOCABULARY example IMMEDIATE
example DEFINITIONS
: hw 7 LOAD ;
: fib 8 LOAD ;
: fac 9 LOAD ;
: reverse 10 LOAD ;
: roman 11 LOAD ;
: mandelbrot 13 LOAD ;
FORTH DEFINITIONS





;S
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
15 LOAD                        ( load str vocabulary          )
FORTH DEFINITIONS
: s1 str " Hello World, this is a string." ;
s1 C@ str new CONSTANT s2
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
( Roman numerals                                              )
FORTH DEFINITIONS VOCABULARY roman IMMEDIATE roman DEFINITIONS
: place <BUILDS , DOES>         ( n --                        )
  OVER OVER @ < IF              ( less than place value?      )
    DROP                        ( yes, drop place value addr  )
  ELSE
    DUP CFA NFA                 ( no, get name field          )
    COUNT 31 AND TYPE           ( print name, no spaces       )
    @ -                         ( subtract place value        )
    R> DROP ;S                  ( return and break            )
  ENDIF ;
1000 place M 900 place CM 500 place D 400 place CD
 100 place C  90 place XC  50 place L  40 place XL
  10 place X   9 place IX   5 place V   4 place IV
   1 place I
-->
( Roman numerals                                              )
: step M CM D CD C XC L XL X IX V IV I ; ( handle places      )
: number BEGIN -DUP WHILE step REPEAT SPACE ; ( until zero    )
: list
  CR 1+ 1 DO
    FORTH I number              ( use I from FORTH, output no )
    ?TERMINAL IF LEAVE ENDIF    ( stop if break pressed       )
  LOOP CR ;

2023 roman list





;S
( Mandelbrot - derived from fract.fs in openbios              )
19 LOAD ( sys vocabulary ) HEX
FORTH DEFINITIONS
: mandelbrot
    CR
    466 DUP MINUS DO            ( y axis                      )
        I
        400 DUP DUP + MINUS DO  ( x axis                      )
            2A 0 DUP OVER OVER  ( * 0 0 0 0                   )
            1E 0 DO             ( iterate                     )
                ROT >R ROT R> 200 */ ( 2SWAP * 200 / )
                5 cs SP@ + @ +  ( 4 PICK +                    )
                ROT ROT -       ( -ROT - )
                R> R> R SWAP >R SWAP >R ( J                   )
                +
-->
( Mandelbrot - derived from fract.fs in openbios              )
                DUP DUP 400 */ ROT
                DUP DUP 400 */ ROT
                SWAP OVER OVER + 1000 > IF ( if diverging     )
                    DROP DROP DROP DROP DROP
                    BL 0 DUP OVER OVER LEAVE ( space          )
                ENDIF
            LOOP
            DROP DROP DROP DROP
            EMIT                ( * or space                  )
        [ 400 3 * sys columns 2 - / ] ( compute step from cols)
        LITERAL +LOOP
        CR DROP                 ( end of line                 )
    [ 466 2+ 2 * sys rows / ] LITERAL +LOOP ;

mandelbrot DECIMAL ;S
( str: Forth/Pascal string handling                           )
FORTH DEFINITIONS VOCABULARY str IMMEDIATE str DEFINITIONS
: (") R> DUP COUNT + ln >R ;    ( return string and advance IP)
: "                             ( --                          )
  ?COMP                         ( compilation only            )
  COMPILE (")                   ( execution time routine      )
  34 WORD                       ( read until "                )
  HERE C@ 1+ ln ALLOT           ( compile the string          )
; IMMEDIATE

: copy                          ( a b --                      )
  OVER C@                       ( get length                  )
  1+ CMOVE ;                    ( copy length+1 bytes         )


-->
( str: Forth/Pascal string handling                           )
: append                        ( a b --                      )
  OVER C@ OVER C@               ( get the two lengths         )
  255 SWAP - MIN >R             ( limit append to max length  )
  OVER OVER                     ( dup both string addrs       )
  COUNT +                       ( move to the end of b        )
  SWAP 1+                       ( then from a                 )
  SWAP R> CMOVE                 ( copy into b                 )
  SWAP C@ OVER C@ +             ( get the total count         )
  SWAP C!                       ( write it to b               )
;




-->
( str: Forth/Pascal string handling                           )
: take                          ( a n --                      )
  OVER C@ MIN                   ( limit to the string length  )
  SWAP C!                       ( write new length )
;

: drop                          ( a n --                      )
  OVER C@ MIN                   ( limit to the string length  )
  >R DUP                        ( save a and modified n       )
  DUP 1+ R +                    ( from                        )
  OVER 1+                       ( to                          )
  ROT C@ R -                    ( count                       )
  CMOVE                         ( copy the rest               )
  DUP C@ R> - SWAP C!           ( update the length           )
;
-->
( str: Forth/Pascal string handling                           )

: alloc HERE SWAP ALLOT ;       ( size -- addr                )
: new 1+ ln alloc ;             ( length -- addr              )











;S
( sys: system dependent operations - BBC                      )
FORTH DEFINITIONS VOCABULARY sys IMMEDIATE sys DEFINITIONS
: D= SWAP >R = SWAP R> = AND ;  ( compare double numbers      )
: tg 20 cs +ORIGIN @ 19 cs +ORIGIN @ ;
: only tg D= 0= IF [COMPILE] --> ENDIF ;
36 BASE ! BBC. DECIMAL only
40 CONSTANT columns 25 CONSTANT rows
;S







;S
( sys: Dragon                                                 )
36 BASE ! DRAGON. DECIMAL only
32 CONSTANT columns 16 CONSTANT rows
;S











;S
( sys: Spectrum                                               )
36 BASE ! SPECTR. DECIMAL only
32 CONSTANT columns 24 CONSTANT rows
;S











;S
( sys: defaults                                               )
DECIMAL
80 CONSTANT columns 24 CONSTANT rows
;S
