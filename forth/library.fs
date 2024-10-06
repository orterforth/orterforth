















( orterforth library                                          )
6 LOAD ;S














( orterforth library                                          )















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







( examples index                                      example )
FORTH DEFINITIONS VOCABULARY example IMMEDIATE
example DEFINITIONS DECIMAL

: loader <BUILDS , DOES> DUP CFA NFA 32 TOGGLE @ LOAD ;
 7 loader hw          8 loader collatz     9 loader fib
10 loader fac        11 loader rev        12 loader roman
14 loader mandelbrot 16 loader pascal     17 loader about
19 loader primes
: help
  ." about collatz fac fib hw mandelbrot "
  ." pascal primes rev roman" CR ;
FORTH DEFINITIONS DECIMAL ;S



( Hello World                                              hw )
example DEFINITIONS
: hw ." Hello World" CR ;
hw ;S












( Collatz sequences                                   collatz )
example DEFINITIONS DECIMAL

: step
  BEGIN DUP . DUP 1 - WHILE
    DUP 2 MOD IF 3 * 1+ ELSE 2 / ENDIF REPEAT DROP CR ;
: collatz 50 1 DO I step LOOP ;
collatz ;S








( Fibonacci sequence                                      fib )
example DEFINITIONS DECIMAL

: length                        ( Overflows after this point  )
  cl 2 = IF 23 ENDIF
  cl 4 = IF 46 ENDIF
  cl 8 = IF 92 ENDIF ;
: fib                           ( Print the whole sequence    )
  0 1
  length 0 DO
    SWAP OVER + DUP 0 D. LOOP ;

fib ;S



( Factorial sequence                                      fac )
example DEFINITIONS DECIMAL

: length                        ( Overflows after this point  )
  cl 2 = IF 9 ENDIF
  cl 4 = IF 14 ENDIF
  cl 8 = IF 22 ENDIF ;
: fac
  1 length 1 DO
    I * DUP 0 D. LOOP ;

fac ;S




( Reverse a string                                        rev )
DECIMAL 20 LOAD                ( load str vocabulary          )
example DEFINITIONS DECIMAL
: s1 str " Hello World, this is a string." ;
s1 C@ str new CONSTANT s2
: reverse                      ( s1 s2 --                     )
  OVER C@ >R                   ( save length                  )
  R OVER C!                    ( write length                 )
  R + SWAP                     ( get pointer to end of str 2  )
  1+ DUP R + SWAP DO           ( iterate over string 1        )
    I C@ OVER C! -1 +          ( copy byte, decrement ptr     )
  LOOP DROP R> DROP ;          ( done, discard len and ptr    )
: rev s1 s2 reverse CR         ( reverse s1 into s2           )
  ." s1: " s1 COUNT TYPE CR    ( print them both              )
  ." s2: " s2 COUNT TYPE CR ;
rev ;S
( Roman numerals                                        roman )
example DEFINITIONS DECIMAL
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
(                                                             )
: step M CM D CD C XC L XL X IX V IV I ; ( handle places      )
: number BEGIN -DUP WHILE step REPEAT SPACE ; ( until zero    )
: list
  CR 1+ 1 DO
    FORTH I number              ( use I from FORTH, output no )
    ?TERMINAL IF LEAVE ENDIF    ( stop if break pressed       )
  LOOP CR ;

: roman 2023 list ;
roman
FORGET place                    ( redefining I causes probs   )



;S
( Mandelbrot - derived from fract.fs in openbios   mandelbrot )
DECIMAL 24 LOAD ( sys vocabulary )
example DEFINITIONS HEX
: mandelbrot
    sys cls
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
(                                                             )
                DUP DUP 400 */ ROT
                DUP DUP 400 */ ROT
                SWAP OVER OVER + 1000 > IF ( if diverging     )
                    DROP DROP DROP DROP DROP
                    BL 0 DUP OVER OVER LEAVE ( space          )
                ENDIF
            LOOP
            DROP DROP DROP DROP
            EMIT                ( * or space                  )
        400 3 * sys columns 2 - / ( compute step from cols    )
        +LOOP
        CR DROP                 ( end of line                 )
    466 2+ 2 * sys rows / +LOOP ;

mandelbrot DECIMAL ;S
( Pascal's Triangle                                    pascal )
example DEFINITIONS DECIMAL
18 CONSTANT size
HERE size cs ALLOT CONSTANT buf
: init buf size cs ERASE 1 buf ! ;
: .line CR buf SWAP 0 DO DUP @ . cl + LOOP DROP ;
: next
  DUP cs buf + SWAP 0 DO
    DUP cl - DUP @ ROT +! LOOP DROP ;
: pascal init size 1 DO I .line I next LOOP ;

pascal ;S




(                                                       about )
0 WARNING ! HEX
CR : lit@ cs +ORIGIN @ ; : .. 0 0 D.R ;
: d36. BASE @ >R 24 BASE ! D. R> BASE ! ;

: vers. 4 lit@ 100 /MOD .. 2E EMIT .. 5 lit@ EMIT ;

: endn 5 lit@ 0200 AND IF ." Little" ELSE ." Big" ENDIF ;

: addr 5 lit@ 0100 AND IF ." Word" ELSE ." Byte" ENDIF ;
: ad. 0 cl DUP + D.R ;
: voc. 2 cs + NFA CFA NFA ID. ;
: about
  ." Version    : " vers. CR
  ." Platform   : " 14 lit@ 13 lit@ d36. CR
-->
(                                                             )
  ." CPU        : " 12 lit@ 11 lit@ d36. CR
  ." Cell size  : " cl . ." bytes" CR
  ." Byte order : " endn ." -endian" CR
  ." Addressing : " addr CR
  ." Origin     : " 0 +ORIGIN ad. CR
  ." DP         : " DP @ ad. CR
  ." SP         : " SP@ ad. CR 
  ." TIB        : " TIB @ ad. CR
  ." USER       : " TIB 5 cs - ad. CR
  ." FIRST      : " FIRST ad. CR
  ." LIMIT      : " LIMIT ad. CR
  ." CONTEXT    : " CONTEXT @ voc. CR
  ." CURRENT    : " CURRENT @ voc. CR ;
about
;S
( Sieve of Eratosthenes from rosettacode.org           primes )
example DEFINITIONS DECIMAL
: prime? ( n -- ? ) HERE + C@ 0= ;
: composite! ( n -- ) HERE + 1 SWAP C! ;
: sieve ( n -- )
  HERE OVER ERASE
  2 BEGIN OVER OVER DUP * > WHILE
    DUP prime? IF
      OVER OVER DUP * DO
        I composite! DUP +LOOP
    THEN 1+
  REPEAT DROP
  ." Primes: " 2 DO I prime? IF I . THEN LOOP ;
: primes CR 1000 sieve CR ;
primes
;S
( string handling: ", copy                                str )
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
( append                                                      )
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
( take, drop                                                  )
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
( alloc, new                                                  )

: alloc HERE SWAP ALLOT ;       ( size -- addr                )
: new 1+ ln alloc ;             ( length -- addr              )











;S
( system dependent operations: BBC                        sys )
FORTH DEFINITIONS VOCABULARY sys IMMEDIATE sys DEFINITIONS
: D= SWAP >R = SWAP R> = AND ;  ( compare double numbers      )
: tg 20 cs +ORIGIN @ 19 cs +ORIGIN @ ;
: only tg D= 0= IF [COMPILE] --> ENDIF ;
36 BASE ! BBC. HEX only
: mode 0355 C@ ;
HERE 50 C, 28 C, 14 C, 50 C, 28 C, 14 C, 28 C, 28 C,
20 C, 20 C, 20 C, 19 C, 20 C, 20 C, 19 C, 19 C, CONSTANT tbl
: columns tbl mode + C@ ; : rows tbl 8 + mode + C@ ;
: cls 0C EMIT ;
DECIMAL
;S


;S
( Commodore 64                                                )
36 BASE ! C64. DECIMAL only
40 CONSTANT columns 25 CONSTANT rows
HEX
: cls 0400 03E8 BLANKS D800 03E8 0286 C@ FILL 13 EMIT ;
DECIMAL ;S









;S
( Dragon                                                      )
36 BASE ! DRAGON. DECIMAL only
32 CONSTANT columns 16 CONSTANT rows
HEX
: cls 0400 0200 60 FILL 0400 0088 ! ;
DECIMAL ;S









;S
( Spectrum                                                    )
36 BASE ! SPECTR. DECIMAL only
32 CONSTANT columns 24 CONSTANT rows
HEX
: cls 4000 1800 ERASE
  5800 0400 5C8D C@ FILL
  16 EMIT 0 EMIT 0 EMIT ;
DECIMAL
;S






;S
( default                                                     )
DECIMAL
80 CONSTANT columns 24 CONSTANT rows
: cls 27 EMIT ." [2J" 27 EMIT ." [H" ;
;S











































































































































































































































































































































































































































































































































































































































































































































































































































































































































































(  TEXT,  LINE                                    WFR-79MAY01 )
FORTH  DEFINITIONS   HEX
: TEXT                        ( ACCEPT FOLLOWING TEXT TO PAD *)
     HERE  C/L  1+   BLANKS  WORD  HERE  PAD  C/L  1+  CMOVE  ;

: LINE              ( RELATIVE TO SCR, LEAVE ADDRESS OF LINE *)
      DUP  FFF0  AND  17  ?ERROR   ( KEEP ON THIS SCREEN )
      SCR  @  (LINE)  DROP  ;
-->







(  LINE EDITOR                                    WFR-79MAY03 )
VOCABULARY  EDITOR  IMMEDIATE    HEX
: WHERE                  ( PRINT SCREEN # AND IMAGE OF ERROR *)
    DUP  B/SCR  /  DUP  SCR  !  ." SCR # "  DECIMAL  .
    SWAP  C/L  /MOD  C/L  *  ROT  BLOCK  +  CR  C/L  TYPE
    CR  HERE  C@  -  SPACES  5E EMIT  [COMPILE] EDITOR  QUIT  ;

EDITOR  DEFINITIONS
: #LOCATE                    ( LEAVE CURSOR OFFSET-2, LINE-1 *)
         R#  @  C/L  /MOD  ;
: #LEAD                 ( LINE ADDRESS-2, OFFSET-1 TO CURSOR *)
         #LOCATE  LINE  SWAP  ;
: #LAG              ( CURSOR ADDRESS-2, COUNT-1 AFTER CURSOR *)
         #LEAD  DUP  >R  +  C/L  R>  -  ;
: -MOVE      ( MOVE IN BLOCK BUFFER ADDR FROM-2,  LINE TO-1 *)
         LINE  C/L  CMOVE  UPDATE  ;  -->
(  LINE EDITING COMMANDS                          WFR-79MAY03 )
: H                              ( HOLD NUMBERED LINE AT PAD *)
      LINE  PAD  1+  C/L  DUP  PAD  C!  CMOVE  ;

: E                               ( ERASE LINE-1 WITH BLANKS *)
      LINE  C/L  BLANKS  UPDATE  ;

: S                             ( SPREAD MAKING LINE # BLANK *)
      DUP  1  -  ( LIMIT )  0E ( FIRST TO MOVE )
      DO  I  LINE  I  1+  -MOVE  -1  +LOOP  E  ;

: D                         ( DELETE LINE-1, BUT HOLD IN PAD *)
      DUP  H  0F  DUP  ROT
      DO  I  1+  LINE  I  -MOVE  LOOP  E  ;

-->
(  LINE EDITING COMMANDS                          WFR-79MAY03 )

: M    ( MOVE CURSOR BY SIGNED AMOUNT-1, PRINT ITS LINE *)
     R#  +!  CR  SPACE  #LEAD  TYPE  5F  EMIT
                        #LAG   TYPE  #LOCATE  .  DROP  ;

: T    ( TYPE LINE BY #-1,  SAVE ALSO IN PAD *)
     DUP  C/L  *  R#  !  DUP  H  0  M  ;

: L     ( RE-LIST SCREEN *)
        SCR  @  LIST  0  M  ;
-->




(  LINE EDITING COMMANDS                           WFR-790105 )
: R                          ( REPLACE ON LINE #-1, FROM PAD *)
      PAD  1+  SWAP  -MOVE  ;

: P                           ( PUT FOLLOWING TEXT ON LINE-1 *)
      1  TEXT  R  ;

: I                       ( INSERT TEXT FROM PAD ONTO LINE # *)
      DUP  S  R  ;
                            CR
: TOP                    ( HOME CURSOR TO TOP LEFT OF SCREEN *)
      0  R#  !  ;
-->



(  SCREEN EDITING COMMANDS                        WFR-79APR27 )
: CLEAR                           ( CLEAR SCREEN BY NUMBER-1 *)
      SCR  !  10  0  DO  FORTH  I  EDITOR  E  LOOP  ;

: FLUSH                   ( WRITE ALL UPDATED BLOCKS TO DISC *)
    [  LIMIT  FIRST  -  B/BUF 2 cs + /  ]  ( NUMBER OF BUFFERS)
    LITERAL  0  DO  7FFF  BUFFER  DROP  LOOP  ;

: COPY                   ( DUPLICATE SCREEN-2, ONTO SCREEN-1 *)
   B/SCR  *  OFFSET  @  +  SWAP  B/SCR  *  B/SCR  OVER  +  SWAP
   DO  DUP  FORTH  I  BLOCK  cl -  !  1+   UPDATE  LOOP
   DROP  FLUSH  ;
-->



(  DOUBLE NUMBER SUPPORT                          WFR-80APR24 )
(  OPERATES ON 32 BIT DOUBLE NUMBERS   OR TWO 16-BIT INTEGERS )
FORTH DEFINITIONS

: 2DROP   DROP    DROP  ;  ( DROP DOUBLE NUMBER )

: 2DUP    OVER    OVER  ;  ( DUPLICATE A DOUBLE NUMBER )

: 2SWAP   ROT     >R    ROT   R>  ;
        ( BRING SECOND DOUBLE TO TOP OF STACK )
EDITOR DEFINITIONS  -->





(  STRING MATCH FOR EDITOR                     PM-WFR-80APR25 )
: -TEXT                   ( ADDRESS-3, COUNT-2, ADDRESS-1 --- )
 SWAP   -DUP  IF  ( LEAVE BOOLEAN MATCHED-NON-ZERO, NOPE-ZERO )
              OVER + SWAP      ( NEITHER ADDRESS MAY BE ZERO! )
        DO  DUP  C@  FORTH  I  C@  -
            IF  0=  LEAVE  ELSE  1+  THEN    LOOP
        ELSE  DROP  0=  THEN  ;
: MATCH   ( CURSOR ADDRESS-4, BYTES LEFT-3, STRING ADDRESS-2, )
          ( STRING COUNT-1, ---  BOOLEAN-2, CURSOR MOVEMENT-1 )
  >R  >R  2DUP  R>  R>  2SWAP  OVER  +  SWAP
  ( CADDR-6, BLEFT-5, $ADDR-4, $LEN-3, CADDR+BLEFT-2, CADDR-1 )
  DO  2DUP  FORTH   I   -TEXT
    IF  >R  2DROP  R>  -  I  SWAP  -  0  SWAP  0  0  LEAVE
        (  CADDR BLEFT  $ADDR  $LEN  OR ELSE 0  OFFSET  0  0  )
      THEN  LOOP 2DROP   ( CADDR-2, BLEFT-1, OR 0-2, OFFSET-1 )
    SWAP  0=  SWAP  ;    -->
(  STRING EDITING COMMANDS                        WFR-79MAR24 )
: 1LINE       ( SCAN LINE WITH CURSOR FOR MATCH TO PAD TEXT, *)
                             ( UPDATE CURSOR, RETURN BOOLEAN *)
       #LAG  PAD  COUNT  MATCH  R#   +!   ;

:  FIND   ( STRING AT PAD OVER FULL SCREEN RANGE, ELSE ERROR *)
     BEGIN  3FF  R#  @  <
         IF  TOP  PAD  HERE  C/L  1+  CMOVE  0  ERROR  ENDIF
         1LINE   UNTIL   ;

: DELETE                    ( BACKWARDS AT CURSOR BY COUNT-1 *)
    >R  #LAG  +  FORTH  R  -  ( SAVE BLANK FILL LOCATION )
    #LAG  R MINUS  R#  +!     ( BACKUP CURSOR )
    #LEAD  +  SWAP  CMOVE
    R>  BLANKS  UPDATE  ;   ( FILL FROM END OF TEXT )
-->
(  STRING EDITOR COMMANDS                         WFR-79MAR24 )
: N     ( FIND NEXT OCCURANCE OF PREVIOUS TEXT *)
      FIND  0  M  ;

: F      ( FIND OCCURANCE OF FOLLOWING TEXT *)
      1  TEXT  N  ;

: B      ( BACKUP CURSOR BY TEXT IN PAD *)
      PAD  C@  MINUS  M  ;

: X     ( DELETE FOLLOWING TEXT *)
      1  TEXT  FIND  PAD  C@  DELETE  0  M  ;

: TILL      ( DELETE ON CURSOR LINE, FROM CURSOR TO TEXT END *)
      #LEAD  +  1  TEXT  1LINE  0=  0  ?ERROR
      #LEAD  +  SWAP  -  DELETE  0  M  ;     -->
(  STRING EDITOR COMMANDS                         WFR-79MAR23 )
: C        ( SPREAD AT CURSOR AND COPY IN THE FOLLOWING TEXT *)
    1  TEXT  PAD  COUNT
    #LAG  ROT  OVER  MIN  >R
    FORTH  R  R#  +!  ( BUMP CURSOR )
    R  -  >R          ( CHARS TO SAVE )
    DUP  HERE  R  CMOVE  ( FROM OLD CURSOR TO HERE )
    HERE  #LEAD  +  R>  CMOVE  ( HERE TO CURSOR LOCATION )
    R>  CMOVE  UPDATE   ( PAD TO OLD CURSOR )
    0  M  ( LOOK AT NEW LINE )  ;
FORTH  DEFINITIONS   DECIMAL
LATEST 6 cs  +ORIGIN  !   ( TOP NFA )
HERE  14 cs  +ORIGIN  !   ( FENCE )
HERE  15 cs  +ORIGIN  !   ( DP )
'  EDITOR  2 ln + 2 cs + 16 cs  +ORIGIN  !  ( VOC-LINK )
HERE  FENCE   !      ;S