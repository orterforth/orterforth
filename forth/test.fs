















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







( double word handling                                   test )
: test ; : D= ROT = ROT ROT = AND ; : 2DROP DROP DROP ;
: 2OVER SP@ 3 cs + @ SP@ 3 cs + @ ;
( test framework                                              )
0 VARIABLE passes 0 VARIABLE fails 0 VARIABLE case
: c ." [" case @ IF 0 case ! 88 ELSE 32 ENDIF EMIT ." ] " ;
: a IF 1 passes +! ELSE 1 fails +! 1 case +! ENDIF ;
: t
  OVER OVER = DUP a IF
    DROP DROP ELSE
    ."     should be " . ." but is " . CR ENDIF ;
: dt
  2OVER 2OVER D= DUP a IF
    2DROP 2DROP ELSE
    ."     should be " D. ." but is " D. CR ENDIF ;
CR -->
( LIT, EXECUTE, BRANCH                                   test )

: t-lit LIT [ 123 , ] ;
t-lit 123 t c ." LIT -- 123" CR

' t-lit CFA EXECUTE 123 t c ." CFA EXECUTE --" CR
FORGET t-lit

: t-bran BRANCH [ 4 cs , ] 123 ;S 456 ;
t-bran 456 t c ." BRANCH --" CR
FORGET t-bran




-->
( 0BRANCH, (LOOP                                         test )
: t-zbran 0BRANCH [ 4 cs , ] 234 ;S 567 ;
0 t-zbran 567 t c ." 0 0BRANCH --" CR
1 t-zbran 234 t c ." 1 0BRANCH --" CR
FORGET t-zbran

: t-xloop SWAP >R >R (LOOP) [ 4 cs , ] 345 ;S R> R> 
  DROP ;
6 0 t-xloop   1 t c ." [6 0] (LOOP) -- [6 1]" CR
6 4 t-xloop   5 t c ." [6 4] (LOOP) -- [6 5]" CR
6 5 t-xloop 345 t c ." [6 5] (LOOP) -- []" CR
FORGET t-xloop



-->
( (+LOOP, (DO, I, R                                      test )
: t-xploo ROT >R SWAP >R (+LOOP) [ 4 cs , ] 99 ;S R> R>
  DROP ;
 6  0  2 t-xploo  2 t c ." [ 6  0]  2 (+LOOP) -- [ 6  2]" CR
 6  4  2 t-xploo 99 t c ." [ 6  4]  2 (+LOOP) -- []" CR
 6  4  4 t-xploo 99 t c ." [ 6  4]  4 (+LOOP) -- []" CR
 6  2 -2 t-xploo 99 t c ." [ 6  2] -2 (+LOOP) -- []" CR
-6  0 -2 t-xploo -2 t c ." [-6  0] -2 (+LOOP) -- [ 6 -2]" CR
-6 -4 -2 t-xploo 99 t c ." [-6 -4] -2 (+LOOP  -- []" CR
-6 -6 -2 t-xploo 99 t c ." [-6 -6] -2 (+LOOP) -- []" CR
 6 -6  2 t-xploo -4 t c ." [ 6 -6]  2 (+LOOP) -- [ 6 -4]" CR
FORGET t-xploo
6 0 (DO) R> 0 t R> 6 t c ." 6 0 (DO) -- [6 0]" CR
123 >R I 123 t c R> DROP ." I -- I" CR
456 >R R 456 t c R> DROP ." R -- R" CR
-->
( DIGIT                                                  test )
DECIMAL
: t-digit-0 OVER OVER DIGIT 0 t c
  SWAP . . ." DIGIT -- 0" CR ;
: t-digit-1 DUP >R ROT DUP >R ROT DUP >R ROT
  DIGIT 1 t t c
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
0= 0= 1 t 131 t ' ABS t c
." ABS LATEST (FIND) -- ABS 131 1" CR
HERE 2 C, 68 C, 82 C, 32 C, 32 C, 32 C, 32 C, 32 C,
CURRENT @ @ (FIND)
0 t c ." DR  LATEST (FIND) -- 0" CR FORGET t-digit-0
HERE 32 C, 67 C, 82 C, 32 C, CONSTANT name
name 32 ENCLOSE
4 t 3 t 1 t name t c
." CR 32 ENCLOSE -- addr 1 3 4" CR
FORGET name
-->
( CMOVE, U*                                              test )
DECIMAL
HERE 1 C, 2 C, 3 C, 4 C, CONSTANT from
from DUP 2+ 2 CMOVE
from 2+ DUP C@ 1 t c ." CMOVE" CR 1+ C@ 2 t c CR

HEX


: t-ustar 2OVER 2OVER
  U* dt c SWAP 0 D. 0 D. ." U* -- " 4 cs D.R 2E EMIT CR ;
40000000. 8000 8000 t-ustar
E1000000. F000 F000 t-ustar
FFFE0001. FFFF FFFF t-ustar

-->
( U/                                                     test )
HEX : 4pick SP@ 4 cs + @ ;
: t-uslas 4pick 4pick 4pick 4pick 4pick
  U/ SWAP ROT t t c ROT ROT 4 cs D.R ." . "
  0 4 D.R ."  U/ -- " S->D 4 D.R SPACE S->D 4 D.R SPACE ;
  -1   -1 00000001. 0000 t-uslas CR
  -1   -1 0000 0004 0004 t-uslas CR
7000 7000 70000000. FFFF t-uslas CR
6000 6000 60000000. FFFF t-uslas CR
2000 2000 20000000. FFFF t-uslas CR
2222 4222 20000000. EFFF t-uslas CR
8889 1888 7FFFFFFF. EFFF t-uslas CR
8000 7FFF 7FFFFFFF. FFFF t-uslas CR
E38F 738E 7FFFFFFF. 8FFF t-uslas CR
FFE2 01C1 7FFFFFFF. 800F t-uslas CR
FORGET 4pick -->
( AND, OR, XOR SP@, SP!, ;S, LEAVE, >R, R>, 0=           test )
HEX
FEAE EF51 AND EE00 t c ." FEFE EF51 AND -- EE00" CR
12AE 4851 OR  5AFF t c ." 12AE 4851  OR -- 5AFF" CR
12AE 37FF XOR 2551 t c ." 12AE 37FF XOR -- 2551" CR
123 SP@ @ 123 t c DROP ." 123 SP@ @ -- 123" CR
SP! SP@ 9 cs +ORIGIN @ t c ." SP! SP@ -- S0" CR
: t-semis 123 ;S DROP 456 ; t-semis 123 t c ." ;S -- " CR
: t-leave 1 >R 2 >R LEAVE R> R> ; t-leave 2 t 2 t c
  ." [1 2] LEAVE -- [2 2]" CR
: t-tor >R 456 R> ;
123 t-tor 123 t 456 t c ." 123 >R -- [123]" CR
234 t-tor 234 t 456 t c ." [234] R> -- 234" CR
4 0= 0 t c ." 4 0= -- 0" CR
0 0= 1 t c ." 0 0= -- 1" CR
-->
( 0<, +, D+                                              test )
HEX
: t-zless OVER OVER 0< t c . ." 0< -- " . CR ;
0 5 t-zless
0 0 t-zless
0 7FFF t-zless
1 -6 t-zless

00FF 0002 + 0101 t c ." 00FF 0002 + -- 0101" CR

0001FFFF. 00000002. D+ 00020001. dt c
." 0001FFFF. 00000002. D+ -- 00020001." CR
00000001.       -2. D+       -1. dt c
." 00000001.       -2. D+ --       -1." CR

-->
( Summary                                                test )
DECIMAL
0 S->D 0. dt c ."  0 S->D --  0." CR
1 S->D 1. dt c ."  1 S->D --  1." CR
-1 S->D -1. dt c ." -1 S->D -- -1." CR
DECIMAL
passes @ fails @ + . ." tests "
passes ? ." passes " fails ? ." fails" CR
FORGET test
;S
