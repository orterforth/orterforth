















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
: test=
  OVER OVER = IF
    DROP DROP 1 ELSE
    ."     should be " . ." but is " . CR 0 ENDIF ;

: t= test= t ;




CR -->
( LIT, EXECUTE, BRANCH                                   test )

: test-lit LIT [ 123 , ] ;
test-lit 123 t= ." LIT" CR

' test-lit CFA EXECUTE 123 t= ." EXECUTE" CR
FORGET test-lit

: test-bran BRANCH [ 4 cs , ] 123 ;S 456 ;
test-bran 456 t= ." BRANCH" CR
FORGET test-bran




-->
( 0BRANCH, (LOOP                                         test )


: test-zbran 0BRANCH [ 4 cs , ] 234 ;S 567 ;
0 test-zbran 567 t= ." 0 0BRANCH" CR
1 test-zbran 234 t= ." 1 0BRANCH" CR
FORGET test-zbran

: test-xloop SWAP >R >R (LOOP) [ 4 cs , ] 345 ;S R> R> 
  DROP ;
6 0 test-xloop   1 t= ." [6 0] (LOOP) -- [6 1]" CR
6 4 test-xloop   5 t= ." [6 4] (LOOP) -- [6 5]" CR
6 5 test-xloop 345 t= ." [6 5] (LOOP) -- []" CR
FORGET test-xloop

-->
( (+LOOP, (DO, I                                         test )
: test-xploo ROT >R SWAP >R (+LOOP) [ 4 cs , ] 99 ;S R> R>
  DROP ;
 6  0  2 test-xploo  2 t= ." [ 6  0]  2 (+LOOP) -- [ 6  2]" CR
 6  2 -2 test-xploo 99 t= ." [ 6  2] -2 (+LOOP) -- []" CR
-6  0 -2 test-xploo -2 t= ." [-6  0] -2 (+LOOP) -- [ 6 -2]" CR
-6 -4 -2 test-xploo -6 t= ." [-6 -4] -2 (+LOOP) -- [-6 -6]" CR
-6 -6 -2 test-xploo 99 t= ." [-6 -6] -2 (+LOOP) -- []" CR
FORGET test-xploo

6 0 (DO) R> 0 test= R> 6 test= AND t ." [6 0] (DO)" CR



123 >R I 123 t= R> DROP ." I" CR
-->
( R, DIGIT                                               test )

456 >R R 456 t= R> DROP ." R" CR

: test-digit-0 OVER OVER DIGIT 0 t=
  SWAP . . ." DIGIT -- 0" CR ;
: test-digit-1 DUP >R ROT DUP >R ROT DUP >R ROT DIGIT 1 test=
  SWAP ROT test= AND t
  R> . R> R> . ." DIGIT -- " . 1 . CR ; DECIMAL
   47 10 test-digit-0    47 16 test-digit-0
 0 48 10 test-digit-1  0 48 16 test-digit-1
 9 57 10 test-digit-1  9 57 16 test-digit-1
   58 10 test-digit-0    58 16 test-digit-0
   65 10 test-digit-0 10 65 16 test-digit-1
   70 10 test-digit-0 15 70 16 test-digit-1
   71 10 test-digit-0    71 16 test-digit-0 -->
( (FIND, ENCLOSE                                         test )
( (FIND matches a full aligned name field with extra bytes=BL )
HERE 3 C, 65 C, 66 C, 83 C, 32 C, 32 C, 32 C, 32 C,
CURRENT @ @ (FIND)
1 test= SWAP 131 test= AND SWAP ' ABS test= AND t
." ABS LATEST (FIND) -- ABS 131 1" CR
HERE 2 C, 68 C, 82 C, 32 C, 32 C, 32 C, 32 C, 32 C,
CURRENT @ @ (FIND)
0 t= ." DR  LATEST (FIND) -- 0" CR FORGET test-digit-0

HERE 32 C, 67 C, 82 C, 32 C, CONSTANT name
name 32 ENCLOSE
4 test= SWAP 3 test= AND SWAP 1 test= AND SWAP name test=
AND t ." CR 32 ENCLOSE -- addr 1 3 4" CR
FORGET name
-->
( CMOVE, U*                                              test )

HERE 1 C, 2 C, 3 C, 4 C, CONSTANT from
from DUP 2+ 2 CMOVE
from 2+ DUP C@ 1 t= ." CMOVE" CR 1+ C@ 2 t= CR

HEX
: D= ROT = ROT ROT = AND ;
: 3pick SP@ 3 cs + @ ;
: test-ustar 3pick 3pick 3pick 3pick
  U* D= t SWAP 0 D. 0 D. ." U* -- " D. CR ;
40000000. 8000 8000 test-ustar
E1000000. F000 F000 test-ustar
FFFE0001. FFFF FFFF test-ustar
FORGET D=
-->
( U/                                                     test )
: 4pick SP@ 4 cs + @ ;
: test-uslas 4pick 4pick 4pick 4pick 4pick
  U/ SWAP ROT = ROT ROT = AND t
  ROT ROT 8 D.R SPACE 0 4 D.R ."  U/ -- " . . ;
  -1   -1 00000001. 0000 test-uslas ." division by 0" CR
  -1   -1 0000 0004 0004 test-uslas ." overflow" CR
7000 7000 70000000. FFFF test-uslas CR
6000 6000 60000000. FFFF test-uslas CR
2000 2000 20000000. FFFF test-uslas CR
2222 4222 20000000. EFFF test-uslas CR
8889 1888 7FFFFFFF. EFFF test-uslas CR
8000 7FFF 7FFFFFFF. FFFF test-uslas CR
E38F 738E 7FFFFFFF. 8FFF test-uslas CR
FFE2 01C1 7FFFFFFF. 800F test-uslas CR
FORGET 4pick -->
( Summary                                                test )
DECIMAL
passes @ fails @ + . ." tests "
passes ? ." passes "
fails ? ." fails" CR
FORGET passes
;S
