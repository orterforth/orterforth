( orterforth library                                          )
6 LOAD ;S














( orterforth library                                          )
6 LOAD ;S














( orterforth library                                          )
6 LOAD ;S














( orterforth library                                          )
6 LOAD ;S














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







( library importer                                     IMPORT )
FORTH DEFINITIONS VOCABULARY IMPORT IMMEDIATE
IMPORT DEFINITIONS DECIMAL

( load a library from a specified screen and mark once done   )
: LIBRARY <BUILDS , DOES>
  [COMPILE] FORTH DEFINITIONS
  DUP @ -DUP IF LOAD 0 OVER ! ENDIF DROP
  [COMPILE] FORTH DEFINITIONS ;

( library index                                               )
7 LIBRARY example 21 LIBRARY STR 25 LIBRARY SYS
37 LIBRARY ASSEMBLER 87 LIBRARY EDITOR

FORTH DEFINITIONS
IMPORT example ;S
( examples index                                      example )
FORTH DEFINITIONS VOCABULARY example IMMEDIATE
example DEFINITIONS DECIMAL

: loader <BUILDS , DOES> DUP CFA NFA 32 TOGGLE @ LOAD ;
 8 loader hw          9 loader collatz    10 loader fib
11 loader fac        12 loader rev        13 loader roman
15 loader mandelbrot 17 loader pascal     18 loader about
20 loader primes
: help
  ." about collatz fac fib hw mandelbrot "
  ." pascal primes rev roman" CR ;
CR ." To see the list of examples," CR
." type: example help" CR
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
DECIMAL IMPORT STR             ( load STR vocabulary          )
example DEFINITIONS DECIMAL
: s1 STR " Hello World, this is a string." ;
s1 C@ STR NEW CONSTANT s2
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
DECIMAL IMPORT SYS
example DEFINITIONS HEX SYS FORM CONSTANT ROWS CONSTANT COLUMNS
: mandelbrot
    SYS PAGE
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
        400 3 * COLUMNS 2 - /     ( compute step from cols    )
        +LOOP
        CR DROP                 ( end of line                 )
    466 2+ 2 * ROWS / +LOOP ;

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




( System properties                                     about )
0 WARNING ! HEX
CR : lit@ cs +ORIGIN @ ; : .. 0 0 D.R ;
: d36. BASE @ >R 24 BASE ! D. R> BASE ! ;

: vers. 4 lit@ 100 /MOD .. 2E EMIT .. 5 lit@ EMIT ;

: endn 5 lit@ 0200 AND IF ." Little" ELSE ." Big" ENDIF ;

: addr 5 lit@ 0100 AND IF ." Word" ELSE ." Byte" ENDIF ;
: ad. ( 0 cl DUP + D.R ) 0 <# cl DUP + 0 DO # LOOP #> TYPE ;
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
( string handling: ", COPY                                STR )
FORTH DEFINITIONS VOCABULARY STR IMMEDIATE STR DEFINITIONS
: (") R> DUP COUNT + ln >R ;    ( return string and advance IP)
: "                             ( --                          )
  ?COMP                         ( compilation only            )
  COMPILE (")                   ( execution time routine      )
  34 WORD                       ( read until "                )
  HERE C@ 1+ ln ALLOT           ( compile the string          )
; IMMEDIATE

: COPY                          ( a b --                      )
  OVER C@                       ( get length                  )
  1+ CMOVE ;                    ( copy length+1 bytes         )


-->
( APPEND                                                      )
: APPEND                        ( a b --                      )
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
( TAKE, DROP*                                                 )
: TAKE                          ( a n --                      )
  OVER C@ MIN                   ( limit to the string length  )
  SWAP C!                       ( write new length )
;

: DROP*                         ( a n --                      )
  OVER C@ MIN                   ( limit to the string length  )
  >R DUP                        ( save a and modified n       )
  DUP 1+ R +                    ( from                        )
  OVER 1+                       ( to                          )
  ROT C@ R -                    ( count                       )
  CMOVE                         ( copy the rest               )
  DUP C@ R> - SWAP C!           ( update the length           )
;
-->
( ALLOC, NEW                                                  )

: ALLOC HERE SWAP ALLOT ;       ( size -- addr                )
: NEW 1+ ln ALLOC ;             ( length -- addr              )











;S
( system dependent operations: Atari                      SYS )
FORTH DEFINITIONS VOCABULARY SYS IMMEDIATE SYS DEFINITIONS
DECIMAL
: ONLY
  BL WORD BASE @ 36 BASE ! HERE NUMBER ROT BASE !
  19 cs +ORIGIN @ = SWAP 20 cs +ORIGIN @ = AND
  0= IF [COMPILE] --> ENDIF ; -->









( Amiga                                                       )
ONLY AMIGA DECIMAL
: FORM 79 23 ;
: PAGE 12 EMIT ; ;S












( Atari                                                       )
ONLY ATARI DECIMAL
: FORM 40 24 ;
: PAGE 125 EMIT ; ;S












( BBC                                                         )
ONLY BBC HEX
: mode@ 0355 C@ ;
: mode! 16 EMIT EMIT ;
: AT-XY 1F EMIT SWAP EMIT EMIT ;
: FORM 030A C@ 0308 C@ - 1+ 0309 C@ 030B C@ - 1+ ;
: PAGE 0C EMIT ;
DECIMAL ;S








( Commodore 64                                                )
ONLY C64 HEX
: AT-XY 1 - 00D6 C! 0D EMIT 00D3 C! ;
: FORM 28 19 ;
: PAGE 0400 03E8 BLANKS D800 03E8 0286 C@ FILL 13 EMIT ;
DECIMAL ;S









;S
( Dragon                                                      )
ONLY DRAGON HEX
: AT-XY 20 * + 0400 + 0088 ! ;
: FORM 20 10 ;
: PAGE 0400 0200 60 FILL 0400 0088 ! ;
DECIMAL ;S









;S
( Colour Genie                                                )
ONLY EG2000 HEX
: AT-XY 28 * + 4400 + 4020 ! ;
: FORM 28 18 ;
CREATE PAGE
  C5 C, DD C, E5 C,  ( push bc ix   )
  CD C, 01C9 ,       ( call CLS     )
  DD C, E1 C, C1 C,  ( pop ix bc    )
  DD C, E9 C,        ( NEXT         )
  SMUDGE
DECIMAL ;S




;S
( QL                                                          )
ONLY QL
: FORM 85 25 ;
IMPORT ASSEMBLER HEX
ASSEMBLER FFI PAGE
  20 IMM    ^ 0 DR .MOVEQ       ( D0 = SD.CLEAR               )
  10001 IMM ^ 0 AR .L .MOVE     ( A0 = channel ID 00010001    )
  -1 IMM    ^ 3 DR .W .MOVE     ( D3.W = timeout forever -1   )
  3 .TRAP                       ( TRAP #3                     )
  .RTS

DECIMAL ;S



;S
( Spectrum                                                    )
ONLY SPECTR HEX
: AT-XY 16 EMIT SWAP EMIT EMIT ;
: FORM 20 18 ;
: PAGE 4000 1800 ERASE
  5800 0400 5C8D C@ FILL
  16 EMIT 0 EMIT 0 EMIT ;
DECIMAL ;S







;S
( Z88                                                         )
ONLY Z88
: FORM 94 8 ;
: PAGE 12 EMIT ;
DECIMAL ;S










;S
( ZX81                                                        )
ONLY ZX81
: FORM 32 24 ;
HEX
CREATE PAGE
  C5 C, FD C, E5 C,  ( push bc iy   )
  FD C, 21 C, 4000 , ( ld iy, $4000 )
  CD C, 0A2A ,       ( call CLS     )
  FD C, E1 C, C1 C,  ( pop iy bc    )
  FD C, E9 C,        ( NEXT         )
  SMUDGE
DECIMAL ;S



;S
( default - ANSI console                                      )
HEX
: CSI 1B EMIT 5B EMIT ;                   ( write ESC [       )
: N. BASE @ DECIMAL SWAP 0 0 D.R BASE ! ; ( write num         )
: CUP CSI SWAP N. 3B EMIT N. 48 EMIT ;
: ED CSI N. 4A EMIT ;
: AT-XY 1+ SWAP 1+ CUP ;
: FORM 50 18 ;
: PAGE 2 ED 1 1 CUP ; DECIMAL ;S







( System-dependent assembler lookup                           )
FORTH DEFINITIONS DECIMAL
: FOR-CPU
  BL WORD BASE @ 36 BASE ! HERE NUMBER ROT BASE !
  17 cs +ORIGIN @ = SWAP 18 cs +ORIGIN @ = AND
  IF SWAP ENDIF DROP ;
38                                          ( default is 6502 )
39 FOR-CPU 68000
FORGET FOR-CPU LOAD ;S







( Original fig-Forth 6502 assembler                 ASSEMBLER )
FORTH DEFINITIONS HEX

( Load unlinked screens                                       )
51 LOAD 52 LOAD 53 LOAD 54 LOAD 55 LOAD 56 LOAD ;S











( Reimplementation of Kenneth Mantei's 68000 asm    ASSEMBLER )
FORTH DEFINITIONS VOCABULARY ASSEMBLER IMMEDIATE
ASSEMBLER DEFINITIONS HEX : W, 0100 /MOD C, C, ;
0 VARIABLE SZ 0 VARIABLE M1 0 VARIABLE R1
0 VARIABLE M2 0 VARIABLE R2 : ^ M1 @ M2 ! R1 @ R2 ! ;
: AR 0008 M1 ! 0007 AND R1 ! ; : DR 0000 M1 ! 0007 AND R1 ! ;
: IMM 0038 M1 ! 0004 R1 ! ; : [ AR 0010 M1 ! ; : .W 3000 SZ ! ;
: -[ AR 0020 M1 ! ; : [+ AR 0018 M1 ! ; : .L 2000 SZ ! ;
: .MOVE 0000 SZ @ OR M2 @ OR R2 @ OR
  M1 @ 8 * OR R1 @ 0200 * OR W, 
  38 M2 @ = 04 R2 @ = AND IF SZ @ 3000 = ( .W ) IF W, ENDIF
    SZ @ 2000 = ( .L ) IF , ENDIF ENDIF ;
: .TRAP 000F AND 4E40 OR W, ; : .RTS 4E75 W, ; 
: .JSR 4EB9 W, , ; : .JMP 4EF9 W, , ;
: .MOVEQ FF AND 7000 OR R1 @ 200 * OR W, ;
-->
( 68000 foreign function interface                            )
CREATE (FFI)
  3 DR ^ 7 -[ .L .MOVE 1 AR ^ 7 -[ .L .MOVE ( save regs       )
  2 AR ^ 7 -[ .L .MOVE 3 AR ^ 7 -[ .L .MOVE
  4 AR ^ 7 -[ .L .MOVE 5 AR ^ 7 -[ .L .MOVE
  0 IMM ^ 0 AR .L .MOVE 0 .JSR              ( SP->A0, JSR     )
  7 [+ ^ 5 AR .L .MOVE 7 [+ ^ 4 AR .L .MOVE ( restore regs    )
  7 [+ ^ 3 AR .L .MOVE 7 [+ ^ 2 AR .L .MOVE
  7 [+ ^ 1 AR .L .MOVE 7 [+ ^ 3 DR .L .MOVE
( Use of DROP to work around difficulty in obtaining NEXT     )
  ' DROP CFA @ .JMP SMUDGE                  ( DROP dummy      )

( Pass SP in A0, call subroutine                              )
: FFI <BUILDS [COMPILE] ASSEMBLER
      DOES>   ' (FFI) 0014 + ! SP@ ' (FFI) 000E + ! 0 (FFI) ;
FORTH DEFINITIONS ;S
































































































































































































































































































































































































































































































































































































































































(  FORTH-65 ASSEMBLER                             WFR-79JUN03 )
HEX
VOCABULARY  ASSEMBLER  IMMEDIATE     ASSEMBLER  DEFINITIONS

( REGISTER ASSIGNMENT SPECIFIC TO IMPLEMENTATION  )
E0  CONSTANT  XSAVE       DC  CONSTANT  W      DE  CONSTANT  UP
D9  CONSTANT  IP          D1  CONSTANT  N

(  NUCLEUS LOCATIONS ARE IMPLEMENTATION SPECIFIC )
'  (DO)  0E  +    CONSTANT  POP
'  (DO)  0C  +    CONSTANT  POPTWO
'  LIT  13  +  CONSTANT  PUT
'  LIT  11  +  CONSTANT  PUSH
'  LIT  18  +  CONSTANT  NEXT
'  EXECUTE  NFA  11  -  CONSTANT  SETUP

(     ASSEMBLER, CONT.                            WFR-78OCT03 )
0   VARIABLE  INDEX       -2  ALLOT
0909 , 1505 , 0115 , 8011 , 8009 , 1D0D , 8019 , 8080 ,
0080 , 1404 , 8014 , 8080 , 8080 , 1C0C , 801C , 2C80 ,

2  VARIABLE  MODE
: .A   0 MODE ! ;    : #    1 MODE ! ;    : MEM  2 MODE ! ;
: ,X   3 MODE ! ;    : ,Y   4 MODE ! ;    : X)   5 MODE ! ;
: )Y   6 MODE ! ;    : )    F MODE ! ;

: BOT       ,X    0  ;    ( ADDRESS THE BOTTOM OF THE STACK  *)
: SEC       ,X    2  ;       ( ADDRESS SECOND ITEM ON STACK  *)
: RP)       ,X  101  ;     ( ADDRESS BOTTOM OF RETURN STACK  *)



(  UPMODE,  CPU                                   WFR-78OCT23 )

: UPMODE   IF  MODE @ 8 AND 0=  IF  8 MODE +!  THEN THEN
     1 MODE @  0F AND  -DUP  IF  0  DO  DUP + LOOP  THEN
     OVER 1+ @ AND  0=  ;

: CPU   <BUILDS  C,  DOES>  C@   C,  MEM  ;
     00 CPU BRK,   18 CPU CLC,   D8 CPU CLD,  58 CPU CLI,
     B8 CPU CLV,   CA CPU DEX,   88 CPU DEY,  E8 CPU INX,
     C8 CPU INY,   EA CPU NOP,   48 CPU PHA,  08 CPU PHP,
     68 CPU PLA,   28 CPU PLP,   40 CPU RTI,  60 CPU RTS,
     38 CPU SEC,   F8 CPU SED,   78 CPU SEI,  AA CPU TAX,
     A8 CPU TAY,   BA CPU TSX,   8A CPU TXA,  9A CPU TXS,
     98 CPU TYA,


(  M/CPU,   MULTI-MODE OP-CODES                   WFR-79MAR26 )
: M/CPU   <BUILDS  C,  ,  DOES>
       DUP 1+ @ 80 AND   IF  10 MODE +! THEN   OVER
       FF00 AND UPMODE UPMODE    IF MEM CR LATEST ID.
       3  ERROR  THEN  C@  MODE  C@
       INDEX + C@ + C,    MODE C@ 7 AND   IF MODE C@
       0F AND 7 <   IF C, ELSE , THEN   THEN  MEM  ;

   1C6E 60 M/CPU ADC,  1C6E 20 M/CPU AND,  1C6E C0 M/CPU CMP,
   1C6E 40 M/CPU EOR,  1C6E A0 M/CPU LDA,  1C6E 00 M/CPU ORA,
   1C6E E0 M/CPU SBC,  1C6C 80 M/CPU STA,  0D0D 01 M/CPU ASL,
   0C0C C1 M/CPU DEC,  0C0C E1 M/CPU INC,  0D0D 41 M/CPU LSR,
   0D0D 21 M/CPU ROL,  0D0D 61 M/CPU ROR,  0414 81 M/CPU STX,
   0486 E0 M/CPU CPX,  0486 C0 M/CPU CPY,  1496 A2 M/CPU LDX,
   0C8E A0 M/CPU LDY,  048C 80 M/CPU STY,  0480 14 M/CPU JSR,
   8480 40 M/CPU JMP,  0484 20 M/CPU BIT,
(  ASSEMBLER CONDITIONALS                         WFR-79MAR26 )
: BEGIN,   HERE  1  ;                 IMMEDIATE
: UNTIL,   ?EXEC >R 1 ?PAIRS R> C, HERE 1+ - C, ; IMMEDIATE
: IF,      C,  HERE  0  C,  2  ;       IMMEDIATE
: THEN,    ?EXEC  2  ?PAIRS  HERE  OVER  C@
         IF SWAP ! ELSE  OVER 1+ - SWAP C!  THEN  ; IMMEDIATE
: ELSE,    2 ?PAIRS HERE 1+   1 JMP,
           SWAP HERE OVER 1+ - SWAP  C!  2  ;  IMMEDIATE
: NOT    20  +  ;                    ( REVERSE ASSEMBLY TEST )
90  CONSTANT  CS               ( ASSEMBLE TEST FOR CARRY SET )
D0  CONSTANT  0=             ( ASSEMBLER TEST FOR EQUAL ZERO )
10  CONSTANT  0<          ( ASSEMBLE TEST FOR LESS THAN ZERO )
90  CONSTANT  >=   ( ASSEMBLE TEST FOR GREATER OR EQUAL ZERO )
                    ( >= IS ONLY CORRECT AFTER SUB, OR CMP,  )


(  USE OF ASSEMBLER                               WFR-79APR28 )
: END-CODE                          ( END OF CODE DEFINITION *)
      CURRENT @ CONTEXT !    ?EXEC ?CSP SMUDGE ;  IMMEDIATE

FORTH  DEFINITIONS    DECIMAL
: CODE                  ( CREATE WORD AT ASSEMBLY CODE LEVEL *)
      ?EXEC  CREATE  [COMPILE]  ASSEMBLER
      ASSEMBLER  MEM  !CSP  ;      IMMEDIATE

( LOCK ASSEMBLER INTO SYSTEM )
'  ASSEMBLER  CFA    '  ;CODE  8  +  !  ( OVER-WRITE SMUDGE )
LATEST  12  +ORIGIN  !  ( TOP NFA )
HERE    28  +ORIGIN  !  ( FENCE )
HERE    30  +ORIGIN  !  ( DP )
'  ASSEMBLER  6  +    32  +ORIGIN  !  ( VOC-LINK )
HERE  FENCE  !
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