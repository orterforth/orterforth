















(                                                        test )
6 LOAD ;S














(                                                        test )















(                                                        test )

( Test suite for native code words                            )













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







( Test framework                                         test )
0 VARIABLE passes 0 VARIABLE fails
: t IF
  ." [ ] " 1 passes +! ELSE
  ." [X] " 1 fails +! ENDIF ;
: ==
  OVER OVER = IF
    DROP DROP 1 ELSE
    ."     should be " . ." but is " . CR 0 ENDIF ;

: t= == t ;




CR -->
( LIT, EXECUTE, BRANCH                                   test )

: t-lit LIT [ 123 , ] ;
t-lit 123 t= ." LIT -- 123" CR

' t-lit CFA EXECUTE 123 t= ." CFA EXECUTE --" CR
FORGET t-lit

: t-bran BRANCH [ 4 cs , ] 123 ;S 456 ;
t-bran 456 t= ." BRANCH --" CR
FORGET t-bran




-->
( 0BRANCH, (LOOP                                         test )
: t-zbran 0BRANCH [ 4 cs , ] 234 ;S 567 ;
0 t-zbran 567 t= ." 0 0BRANCH --" CR
1 t-zbran 234 t= ." 1 0BRANCH --" CR
FORGET t-zbran

: t-xloop SWAP >R >R (LOOP) [ 4 cs , ] 345 ;S R> R> 
  DROP ;
6 0 t-xloop   1 t= ." [6 0] (LOOP) -- [6 1]" CR
6 4 t-xloop   5 t= ." [6 4] (LOOP) -- [6 5]" CR
6 5 t-xloop 345 t= ." [6 5] (LOOP) -- []" CR
FORGET t-xloop



-->
( (+LOOP, (DO, I, R                                      test )
: t-xploo ROT >R SWAP >R (+LOOP) [ 4 cs , ] 99 ;S R> R>
  DROP ;
 6  0  2 t-xploo  2 t= ." [ 6  0]  2 (+LOOP) -- [ 6  2]" CR
 6  2 -2 t-xploo 99 t= ." [ 6  2] -2 (+LOOP) -- []" CR
-6  0 -2 t-xploo -2 t= ." [-6  0] -2 (+LOOP) -- [ 6 -2]" CR
( -6 -4 -2 t-xploo -6 t= ." [-6 -4] -2 (+LOOP  -- [-6 -6]" CR )
-6 -6 -2 t-xploo 99 t= ." [-6 -6] -2 (+LOOP) -- []" CR
FORGET t-xploo

6 0 (DO) R> 0 == R> 6 == AND t ." [6 0] (DO)" CR

123 >R I 123 t= R> DROP ." I -- I" CR
456 >R R 456 t= R> DROP ." R -- R" CR

-->
( DIGIT                                                  test )
DECIMAL
: t-digit-0 OVER OVER DIGIT 0 t=
  SWAP . . ." DIGIT -- 0" CR ;
: t-digit-1 DUP >R ROT DUP >R ROT DUP >R ROT
  DIGIT 1 == SWAP ROT == AND t
  R> . R> R> . ." DIGIT -- " . 1 . CR ;
   47 10 t-digit-0    47 16 t-digit-0
 0 48 10 t-digit-1  0 48 16 t-digit-1
 9 57 10 t-digit-1  9 57 16 t-digit-1
   58 10 t-digit-0    58 16 t-digit-0
   64 10 t-digit-0    64 16 t-digit-0
   65 10 t-digit-0 10 65 16 t-digit-1
   70 10 t-digit-0 15 70 16 t-digit-1
   71 10 t-digit-0    71 16 t-digit-0
-->
( (FIND, ENCLOSE                                         test )
( (FIND matches a full aligned name field with extra bytes=BL )
DECIMAL HERE 3 C, 65 C, 66 C, 83 C, 32 C, 32 C, 32 C, 32 C,
CURRENT @ @ (FIND)
( true flag is not always 1 e.g., 6502 asm returns 0101h      )
0= 0= 1 == SWAP 131 == AND SWAP ' ABS == AND t
." ABS LATEST (FIND) -- ABS 131 1" CR
HERE 2 C, 68 C, 82 C, 32 C, 32 C, 32 C, 32 C, 32 C,
CURRENT @ @ (FIND)
0 t= ." DR  LATEST (FIND) -- 0" CR FORGET t-digit-0
HERE 32 C, 67 C, 82 C, 32 C, CONSTANT name
name 32 ENCLOSE
4 == SWAP 3 == AND SWAP 1 == AND SWAP name ==
AND t ." CR 32 ENCLOSE -- addr 1 3 4" CR
FORGET name
-->
( CMOVE, U*                                              test )
DECIMAL
HERE 1 C, 2 C, 3 C, 4 C, CONSTANT from
from DUP 2+ 2 CMOVE
from 2+ DUP C@ 1 t= ." CMOVE" CR 1+ C@ 2 t= CR

HEX
: D= ROT = ROT ROT = AND ;
: 3pick SP@ 3 cs + @ ;
: t-ustar 3pick 3pick 3pick 3pick
  U* D= t SWAP 0 D. 0 D. ." U* -- " 4 cs D.R 2E EMIT CR ;
40000000. 8000 8000 t-ustar
E1000000. F000 F000 t-ustar
FFFE0001. FFFF FFFF t-ustar
FORGET D=
-->
( U/                                                     test )
HEX : 4pick SP@ 4 cs + @ ;
: t-uslas 4pick 4pick 4pick 4pick 4pick
  U/ SWAP ROT == ROT ROT == AND t ROT ROT 4 cs D.R ." . "
  0 4 D.R ."  U/ -- " S->D 4 D.R SPACE S->D 4 D.R SPACE ;
  -1   -1 00000001. 0000 t-uslas ." division by 0" CR
  -1   -1 0000 0004 0004 t-uslas ." overflow" CR
7000 7000 70000000. FFFF t-uslas CR
6000 6000 60000000. FFFF t-uslas CR
2000 2000 20000000. FFFF t-uslas CR
2222 4222 20000000. EFFF t-uslas CR
8889 1888 7FFFFFFF. EFFF t-uslas CR
8000 7FFF 7FFFFFFF. FFFF t-uslas CR
E38F 738E 7FFFFFFF. 8FFF t-uslas CR
FFE2 01C1 7FFFFFFF. 800F t-uslas CR
FORGET 4pick -->
( AND, OR, XOR SP@, SP!                                  test )
HEX
FEAE EF51 AND EE00 t= ." FEFE EF51 AND -- EE00" CR
12AE 4851 OR  5AFF t= ." 12AE 4851  OR -- 5AFF" CR
12AE 37FF XOR 2551 t= ." 12AE 37FF XOR -- 2551" CR
123 SP@ @ 123 t= DROP ." 123 SP@ @ -- 123" CR
SP! SP@ 9 cs +ORIGIN @ t= ." SP! SP@ -- S0" CR








-->
( Summary                                                test )
DECIMAL
passes @ fails @ + . ." tests "
passes ? ." passes "
fails ? ." fails" CR
FORGET passes
;S
