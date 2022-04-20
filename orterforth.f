















































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







(  INPUT-OUTPUT,  TIM                              WFR-780519 )














DECIMAL     ;S    
(  INPUT-OUTPUT,  APPLE                            WFR-780730 )














DECIMAL  ;S    
(  INPUT-OUTPUT,  SYM-1                            WFR-781015 )
HEX













DECIMAL  ;S    
















































(  COLD AND WARM ENTRY,  USER PARAMETERS          WFR-79APR29 )
( ASSEMBLER   OBJECT  MEM ) HEX
0000 , 0000 ,      ( WORD ALIGNED VECTOR TO COLD )
0000 , 0000 ,      ( WORD ALIGNED VECTOR TO WARM )
relrev , ver  ,  ( CPU, AND REVISION PARAMETERS )
0000   ,        ( TOPMOST WORD IN FORTH VOCABULARY )
  bs   ,        ( BACKSPACE CHARACTER )
user   ,        ( INITIAL USER AREA )
inits0 ,        ( INITIAL TOP OF STACK )
initr0 ,        ( INITIAL TOP OF RETURN STACK )
tib    ,        ( TERMINAL INPUT BUFFER )
001F   ,        ( INITIAL NAME FIELD WIDTH )
0000   ,        ( INITIAL WARNING = 1 )
0000   ,        ( INITIAL FENCE )
0000   ,        ( COLD START VALUE FOR DP )
0000   ,        ( COLD START VALUE FOR VOC-LINK ) ext -->
(  START OF NUCLEUS,  LIT, PUSH, PUT, NEXT        WFR-78DEC26 )
CODE LIT                   ( PUSH FOLLOWING LITERAL TO STACK *)
lit rcod












-->    
(  SETUP                                           WFR-790225 )








CODE EXECUTE              ( EXECUTE A WORD BY ITS CODE FIELD *)
                                      ( ADDRESS ON THE STACK *)
exec rcod



-->    
(  BRANCH, 0BRANCH     W/16-BIT OFFSET            WFR-79APR01 )
CODE BRANCH            ( ADJUST IP BY IN-LINE 16 BIT LITERAL *)
bran rcod



CODE 0BRANCH           ( IF BOT IS ZERO, BRANCH FROM LITERAL *)
zbran rcod





-->    


(  LOOP CONTROL                                   WFR-79MAR20 )
CODE (LOOP)      ( INCREMENT LOOP INDEX, LOOP UNTIL => LIMIT *)
xloop rcod





CODE (+LOOP)          ( INCREMENT INDEX BY STACK VALUE +/-   *)
xploo rcod





-->    
(  (DO-                                           WFR-79MAR30 )

CODE (DO)             ( MOVE TWO STACK ITEMS TO RETURN STACK *)
xdo rcod





CODE I                    ( COPY CURRENT LOOP INDEX TO STACK *)
rr rcod                   ( THIS WILL LATER BE POINTED TO 'R' )

-->    



(  DIGIT                                           WFR-781202 )
CODE DIGIT     ( CONVERT ASCII CHAR-SECOND, WITH BASE-BOTTOM *)
                   ( IF OK RETURN DIGIT-SECOND, TRUE-BOTTOM; *)
                                   ( OTHERWISE FALSE-BOTTOM. *)
digit rcod










-->    
(  FIND FOR VARIABLE LENGTH NAMES                  WFR-790225 )
CODE (FIND)  ( HERE, NFA ... PFA, LEN BYTE, TRUE; ELSE FALSE *)
pfind rcod












                                                     -->    
(  ENCLOSE                                         WFR-780926 )
CODE ENCLOSE   ( ENTER WITH ADDRESS-2, DELIM-1.  RETURN WITH *)
    ( ADDR-4, AND OFFST TO FIRST CH-3, END WORD-2, NEXT CH-1 *)
encl rcod











-->    
(  TERMINAL VECTORS                               WFR-79MAR30 )
(  THESE WORDS ARE CREATED WITH NO EXECUTION CODE, YET.       )
(  THEIR CODE FIELDS WILL BE FILLED WITH THE ADDRESS OF THEIR )
(  INSTALLATION SPECIFIC CODE.                                )

CODE EMIT             ( PRINT ASCII VALUE ON BOTTOM OF STACK *)
emit rcod
CODE KEY        ( ACCEPT ONE TERMINAL CHARACTER TO THE STACK *)
key rcod
CODE ?TERMINAL      ( 'BREAK' LEAVES 1 ON STACK; OTHERWISE 0 *)
qterm rcod
CODE CR         ( EXECUTE CAR. RETURN, LINE FEED ON TERMINAL *)
cr rcod
-->    


(  CMOVE,                                         WFR-79MAR20 )
CODE CMOVE   ( WITHIN MEMORY; ENTER W/  FROM-3, TO-2, QUAN-1 *)
cmove rcod








-->    




(  U*,  UNSIGNED MULTIPLY FOR 16 BITS             WFR-79APR08 )
CODE U*        ( 16 BIT MULTIPLICAND-2,  16 BIT MULTIPLIER-1 *)
             ( 32 BIT UNSIGNED PRODUCT: LO WORD-2, HI WORD-1 *)
ustar rcod











-->    
(  U/,  UNSIGNED DIVIDE FOR 31 BITS               WFR-79APR29 )
CODE U/          ( 31 BIT DIVIDEND-2, -3,  16 BIT DIVISOR-1  *)
                 ( 16 BIT REMAINDER-2,  16 BIT QUOTIENT-1    *)
uslas rcod









-->    


(  LOGICALS                                       WFR-79APR20 )

CODE AND           ( LOGICAL BITWISE AND OF BOTTOM TWO ITEMS *)
andd rcod


CODE OR           ( LOGICAL BITWISE 'OR' OF BOTTOM TWO ITEMS *)
orr rcod


CODE XOR        ( LOGICAL 'EXCLUSIVE OR' OF BOTTOM TWO ITEMS *)
xorr rcod


-->    

(  STACK INITIALIZATION                           WFR-79MAR30 )
CODE SP@                      ( FETCH STACK POINTER TO STACK *)
spat rcod


CODE SP!                                 ( LOAD SP FROM 'S0' *)
spsto rcod

CODE RP!                                   ( LOAD RP FROM R0 *)
rpsto rcod


CODE ;S              ( RESTORE IP REGISTER FROM RETURN STACK *)
semis rcod

-->    
(  RETURN STACK WORDS                             WFR-79MAR29 )
CODE LEAVE          ( FORCE EXIT OF DO-LOOP BY SETTING LIMIT *)
                                                  ( TO INDEX *)
leave rcod

CODE >R              ( MOVE FROM COMP. STACK TO RETURN STACK *)
tor rcod

CODE R>              ( MOVE FROM RETURN STACK TO COMP. STACK *)
fromr rcod

CODE R  ( COPY THE BOTTOM OF THE RETURN STACK TO COMP. STACK *)
rr rcod

( '   R    -2  BYTE.IN  I  ! )
-->    
(  TESTS AND LOGICALS                             WFR-79MAR19 )

CODE 0=           ( REVERSE LOGICAL STATE OF BOTTOM OF STACK *)
zequ rcod


CODE 0<            ( LEAVE TRUE IF NEGATIVE; OTHERWISE FALSE *)
zless rcod


-->    





(  MATH                                           WFR-79MAR19 )
CODE +         ( LEAVE THE SUM OF THE BOTTOM TWO STACK ITEMS *)
plus rcod

CODE D+            ( ADD TWO DOUBLE INTEGERS, LEAVING DOUBLE *)
dplus rcod



CODE MINUS         ( TWOS COMPLEMENT OF BOTTOM SINGLE NUMBER *)
minus rcod

CODE DMINUS        ( TWOS COMPLEMENT OF BOTTOM DOUBLE NUMBER *)
dminu rcod

                                           -->    
(  STACK MANIPULATION                             WFR-79MAR29 )
CODE OVER              ( DUPLICATE SECOND ITEM AS NEW BOTTOM *)
over rcod

CODE DROP                           ( DROP BOTTOM STACK ITEM *)
drop rcod                    ( C.F. VECTORS DIRECTLY TO 'POP' )

CODE SWAP        ( EXCHANGE BOTTOM AND SECOND ITEMS ON STACK *)
swap rcod


CODE DUP                    ( DUPLICATE BOTTOM ITEM ON STACK *)
dup rcod

-->    

(  MEMORY INCREMENT,                              WFR-79MAR30 )

CODE +!   ( ADD SECOND TO MEMORY 16 BITS ADDRESSED BY BOTTOM *)
pstor rcod



CODE TOGGLE           ( BYTE AT ADDRESS-2, BIT PATTERN-1 ... *)
toggl rcod

-->    





(  MEMORY FETCH AND STORE                          WFR-781202 )
CODE @                   ( REPLACE STACK ADDRESS WITH 16 BIT *)
at rcod                           ( CONTENTS OF THAT ADDRESS *)


CODE C@      ( REPLACE STACK ADDRESS WITH POINTED 8 BIT BYTE *)
cat rcod

CODE !         ( STORE SECOND AT 16 BITS ADDRESSED BY BOTTOM *)
store rcod


CODE C!           ( STORE SECOND AT BYTE ADDRESSED BY BOTTOM *)
cstor rcod

DECIMAL     ;S    
(  :,  ;,                                         WFR-79MAR30 )

: :                  ( CREATE NEW COLON-DEFINITION UNTIL ';' *)
                    ?EXEC !CSP CURRENT   @         CONTEXT    !
                CREATE  ]
docol rcod ; IMMEDIATE



: ;                             ( TERMINATE COLON-DEFINITION *)
                    ?CSP  COMPILE     ;S                       
                  SMUDGE  [COMPILE] [    ;   IMMEDIATE         



-->    
(  CONSTANT,  VARIABLE, USER                      WFR-79MAR30 )
: CONSTANT              ( WORD WHICH LATER CREATES CONSTANTS *)
                      CREATE  SMUDGE  ,
docon rcod ;

: VARIABLE              ( WORD WHICH LATER CREATES VARIABLES *)
     CONSTANT
dovar rcod ;

: USER                                ( CREATE USER VARIABLE *)
     CONSTANT
douse rcod ;



-->    
(  DEFINED CONSTANTS                              WFR-78MAR22 )
HEX
00  CONSTANT 0        01  CONSTANT  1
02  CONSTANT 2        03  CONSTANT  3
20  CONSTANT BL                                ( ASCII BLANK *)
40  CONSTANT C/L                  ( TEXT CHARACTERS PER LINE *)

first   CONSTANT   FIRST   ( FIRST BYTE RESERVED FOR BUFFERS *)
limit   CONSTANT   LIMIT            ( JUST BEYOND TOP OF RAM *)
  80    CONSTANT   B/BUF            ( BYTES PER DISC BUFFER  *)
   8     CONSTANT  B/SCR  ( BLOCKS PER SCREEN = 1024 B/BUF / *)

           00  +ORIGIN
: +ORIGIN  LITERAL  +  ; ( LEAVES ADDRESS RELATIVE TO ORIGIN *)
-->    

(  USER VARIABLES                                 WFR-78APR29 )
HEX              ( O THRU 5 RESERVED,    REFERENCED TO $00A0 *)
( 06 USER  S0 )             ( TOP OF EMPTY COMPUTATION STACK *)
( 08 USER  R0 )                  ( TOP OF EMPTY RETURN STACK *)
05 rcls USER  TIB                    ( TERMINAL INPUT BUFFER *)
06 rcls USER  WIDTH               ( MAXIMUM NAME FIELD WIDTH *)
07 rcls USER  WARNING                ( CONTROL WARNING MODES *)
08 rcls USER  FENCE                 ( BARRIER FOR FORGETTING *)
09 rcls USER  DP                        ( DICTIONARY POINTER *)
0A rcls USER  VOC-LINK                ( TO NEWEST VOCABULARY *)
0B rcls USER  BLK                     ( INTERPRETATION BLOCK *)
0C rcls USER  IN                   ( OFFSET INTO SOURCE TEXT *)
0D rcls USER  OUT                  ( DISPLAY CURSOR POSITION *)
0E rcls USER  SCR                           ( EDITING SCREEN *)
-->    

(  USER VARIABLES, CONT.                          WFR-79APR29 )
0F rcls USER  OFFSET              ( POSSIBLY TO OTHER DRIVES *)
10 rcls USER  CONTEXT            ( VOCABULARY FIRST SEARCHED *)
11 rcls USER  CURRENT       ( SEARCHED SECOND, COMPILED INTO *)
12 rcls USER  STATE                      ( COMPILATION STATE *)
13 rcls USER  BASE                ( FOR NUMERIC INPUT-OUTPUT *)
14 rcls USER  DPL                   ( DECIMAL POINT LOCATION *)
15 rcls USER  FLD                       ( OUTPUT FIELD WIDTH *)
16 rcls USER  CSP                     ( CHECK STACK POSITION *)
17 rcls USER  R#                   ( EDITING CURSOR POSITION *)
18 rcls USER  HLD     ( POINTS TO LAST CHARACTER HELD IN PAD *)
-->    




(  HI-LEVEL MISC.                                 WFR-79APR29 )
: 1+      1   +  ;           ( INCREMENT STACK NUMBER BY ONE *)
: 2+      2   +  ;           ( INCREMENT STACK NUMBER BY TWO *)
: HERE    DP  @  ;        ( FETCH NEXT FREE ADDRESS IN DICT. *)
: ALLOT   DP  +! ;                ( MOVE DICT. POINTER AHEAD *)
: ,   HERE  !  rcll  ALLOT  ;  ( ENTER STACK NUMBER TO DICT. *)
: C,   HERE  C!  1   ALLOT  ;    ( ENTER STACK BYTE TO DICT. *)
: -   MINUS   +  ;               ( LEAVE DIFF.  SEC - BOTTOM *)
: =   -  0=  ;                   ( LEAVE BOOLEAN OF EQUALITY *)
: <   -  0<  ;                  ( LEAVE BOOLEAN OF SEC < BOT *) 
: >   SWAP  <  ;                ( LEAVE BOOLEAN OF SEC > BOT *)
: ROT   >R  SWAP  R>  SWAP  ;       ( ROTATE THIRD TO BOTTOM *)
: SPACE     BL  EMIT  ;            ( PRINT BLANK ON TERMINAL *)
: -DUP     DUP  IF  DUP  ENDIF  ;       ( DUPLICATE NON-ZERO *)
-->    

(  VARIABLE LENGTH NAME SUPPORT                   WFR-79MAR30 )
: TRAVERSE                          ( MOVE ACROSS NAME FIELD *)
         ( ADDRESS-2, DIRECTION-1, I.E. -1=R TO L, +1=L TO R *)
       SWAP
       BEGIN  OVER  +  7F  OVER  C@  <  UNTIL  SWAP  DROP  ;

: LATEST       CURRENT  @  @  ;         ( NFA OF LATEST WORD *)


( FOLLOWING HAVE LITERALS DEPENDENT ON COMPUTER WORD SIZE )

: LFA    2 rcls  -  ;           ( CONVERT A WORDS PFA TO LFA *)
: CFA    rcll  -  ;             ( CONVERT A WORDS PFA TO CFA *)
: NFA 2 rcls 1+ - -1 TRAVERSE ; ( CONVERT A WORDS PFA TO NFA *)
: PFA 1 TRAVERSE 2 rcls 1+ + ;  ( CONVERT A WORDS NFA TO PFA *)
    -->    
(  ERROR PROCEEDURES, PER SHIRA                   WFR-79MAR23 )
: !CSP     SP@  CSP  !  ;     ( SAVE STACK POSITION IN 'CSP' *)

: ?ERROR          ( BOOLEAN-2,  ERROR TYPE-1,  WARN FOR TRUE *)
         SWAP  IF         ERROR    ELSE  DROP  ENDIF  ;

: ?COMP   STATE @  0= 11 ?ERROR ;   ( ERROR IF NOT COMPILING *)

: ?EXEC   STATE  @  12  ?ERROR  ;   ( ERROR IF NOT EXECUTING *)

: ?PAIRS  -  13  ?ERROR  ;  ( VERIFY STACK VALUES ARE PAIRED *)

: ?CSP   SP@  CSP @ -  14  ?ERROR  ; ( VERIFY STACK POSITION *)

: ?LOADING                        ( VERIFY LOADING FROM DISC *)
         BLK  @  0=  16  ?ERROR  ;   -->    
(  COMPILE,  SMUDGE,  HEX, DECIMAL                WFR-79APR20 )

: COMPILE          ( COMPILE THE EXECUTION ADDRESS FOLLOWING *)
        ?COMP  R>  DUP  rcll +  >R  @  ,  ;

: [    0  STATE  !  ;  IMMEDIATE          ( STOP COMPILATION *)

: ]    C0  STATE  !  ;             ( ENTER COMPILATION STATE *)

: SMUDGE    LATEST  20  TOGGLE  ;   ( ALTER LATEST WORD NAME *)

: HEX      10  BASE  !  ;         ( MAKE HEX THE IN-OUT BASE *)

: DECIMAL  0A  BASE  !  ;     ( MAKE DECIMAL THE IN-OUT BASE *)
-->    

(  ;CODE                                          WFR-79APR20 )

: (;CODE)     ( WRITE CODE FIELD POINTING TO CALLING ADDRESS *)
        R>  LATEST  PFA  CFA  !  ;


: ;CODE                      ( TERMINATE A NEW DEFINING WORD *)
      ?CSP  COMPILE  (;CODE)
      [COMPILE]  [  SMUDGE  ;   IMMEDIATE
-->    






(  <BUILD,  DOES>                                 WFR-79MAR20 )

: <BUILDS   0  CONSTANT  ;  ( CREATE HEADER FOR 'DOES>' WORD *)

: DOES>          ( REWRITE PFA WITH CALLING HI-LEVEL ADDRESS *)
                             ( REWRITE CFA WITH 'DOES>' CODE *)
             R>  LATEST  PFA  !
      ( IP 1+ LDA,  PHA,  IP LDA,  PHA,) ( BEGIN FORTH NESTING )
      ( 2 # LDY,  W (Y LDA,  IP STA, )     ( FETCH FIRST PARAM )
      ( INY,  W (Y LDA,  IP 1+ STA, )    ( AS NEXT INTERP. PTR )
      ( CLC,  W LDA,  4 # ADC,  PHA,) ( PUSH ADDRESS OF PARAMS )
      ( W 1+ LDA,  00 # ADC,  PUSH JMP, )
dodoe rcod ;
-->


(  TEXT OUTPUTS                                   WFR-79APR02 )
: COUNT    DUP 1+ SWAP C@  ;  ( LEAVE TEXT ADDR. CHAR. COUNT *)
: TYPE            ( TYPE STRING FROM ADDRESS-2, CHAR.COUNT-1 *)
        -DUP  IF OVER + SWAP
                 DO I C@ EMIT LOOP  ELSE DROP ENDIF ;
: -TRAILING   ( ADJUST CHAR. COUNT TO DROP TRAILING BLANKS *) 
        DUP  0  DO  OVER  OVER  +  1  -  C@
        BL  -  IF  LEAVE  ELSE  1  -  ENDIF  LOOP  ;
: (.")             ( TYPE IN-LINE STRING, ADJUSTING RETURN *)
        R  COUNT  DUP  1+  R>  +  >R  TYPE  ;


: ."     22  STATE  @       ( COMPILE OR PRINT QUOTED STRING *)
    IF  COMPILE  (.")        WORD    HERE  C@  1+  ALLOT
        ELSE        WORD    HERE   COUNT  TYPE  ENDIF  ;
               IMMEDIATE     -->    
(  TERMINAL INPUT                                 WFR-79APR29 )

: EXPECT            ( TERMINAL INPUT MEMORY-2,  CHAR LIMIT-1 *)
    OVER  +  OVER  DO  KEY  DUP  07 rcls +ORIGIN ( BS ) @ =
    IF  DROP  08  OVER  I  =  DUP  R>  2  -  + >R  -
       ELSE ( NOT BS )  DUP  0D  =
           IF ( RET ) LEAVE  DROP  BL  0  ELSE  DUP  ENDIF
          I  C!  0  I  1+  !
       ENDIF EMIT  LOOP  DROP  ;
: QUERY     TIB  @  50  EXPECT  0  IN  !  ;
81 HERE 80 HERE 1+
: X  BLK @                            ( END-OF-TEXT IS NULL *)
      IF ( DISC ) 1 BLK +!  0 IN !  BLK @  7  AND  0=
         IF ( SCR END )  ?EXEC  R>  DROP  ENDIF
       ELSE  ( TERMINAL )    R>  DROP
         ENDIF  ; C! C! IMMEDIATE  -->    
(  FILL, ERASE, BLANKS, HOLD, PAD                 WFR-79APR02 )
: FILL               ( FILL MEMORY BEGIN-3,  QUAN-2,  BYTE-1 *)
        SWAP  >R  OVER  C!  DUP  1+  R>  1  -  CMOVE  ;

: ERASE           ( FILL MEMORY WITH ZEROS  BEGIN-2,  QUAN-1 *) 
        0  FILL  ;

: BLANKS                  ( FILL WITH BLANKS BEGIN-2, QUAN-1 *) 
        BL  FILL  ;

: HOLD                               ( HOLD CHARACTER IN PAD *)
        -1  HLD  +!   HLD  @  C!  ;

: PAD        HERE  44  +  ;     ( PAD IS 68 BYTES ABOVE HERE *)
        ( DOWNWARD HAS NUMERIC OUTPUTS; UPWARD MAY HOLD TEXT *)
-->    
(  WORD,                                          WFR-79APR02 )
: WORD         ( ENTER WITH DELIMITER, MOVE STRING TO 'HERE' *)
   BLK  @  IF  BLK  @        BLOCK    ELSE  TIB  @  ENDIF
   IN  @  +  SWAP    ( ADDRESS-2, DELIMITER-1 )
   ENCLOSE         ( ADDRESS-4, START-3, END-2, TOTAL COUNT-1 )
   HERE 22 BLANKS        ( PREPARE FIELD OF 34 BLANKS ) 
   IN  +!          ( STEP OVER THIS STRING )
   OVER  -  >R     ( SAVE CHAR COUNT )
   R  HERE  C!     ( LENGTH STORED FIRST )
   +  HERE  1+ 
   R>  CMOVE  ;    ( MOVE STRING FROM BUFFER TO HERE+1 )




-->    
(  (NUMBER-, NUMBER, -FIND,                       WFR-79APR29 )
: (NUMBER)    ( CONVERT DOUBLE NUMBER, LEAVING UNCONV. ADDR. *)
   BEGIN  1+  DUP  >R  C@  BASE  @  DIGIT 
      WHILE  SWAP  BASE  @  U*  DROP  ROT  BASE  @  U*  D+
      DPL  @  1+  IF  1  DPL  +!  ENDIF  R>  REPEAT  R>  ;

: NUMBER   ( ENTER W/ STRING ADDR.  LEAVE DOUBLE NUMBER *)
      0  0  ROT  DUP  1+  C@  2D  =  DUP  >R  +  -1
   BEGIN  DPL  !  (NUMBER)  DUP  C@  BL  -
      WHILE  DUP  C@  2E  -  0  ?ERROR    0  REPEAT 
      DROP  R>  IF  DMINUS  ENDIF  ;

: -FIND       ( RETURN PFA-3, LEN BYTE-2, TRUE-1; ELSE FALSE *)
      BL  WORD      HERE  CONTEXT  @  @  (FIND)  
      DUP  0=  IF  DROP  HERE  LATEST  (FIND)  ENDIF  ;
-->    
(  ERROR HANDLER                                  WFR-79APR20 )

: (ABORT)          ABORT    ;  ( USER ALTERABLE ERROR ABORT * )

: ERROR              ( WARNING:  -1=ABORT, 0=NO DISC, 1=DISC *)
    WARNING  @  0<           ( PRINT TEXT LINE REL TO SCR #4 *)
    IF  (ABORT)  ENDIF  HERE  COUNT  TYPE ."   ? "
          MESSAGE    SP!  IN  @  BLK  @       QUIT     ;

: ID.   ( PRINT NAME FIELD FROM ITS HEADER ADDRESS *) 
     PAD  020  5F  FILL  DUP  PFA  LFA  OVER  -
     PAD  SWAP  CMOVE  PAD  COUNT  01F  AND  TYPE  SPACE  ;
-->    



(  CREATE                                         WFR-79APR28 )

: CREATE              ( A SMUDGED CODE HEADER TO PARAM FIELD *)
                     ( WARNING IF DUPLICATING A CURRENT NAME *)
      TIB  HERE  0A0  +  =  2  ?ERROR  ( FREE SPACE ? )
      -FIND    ( CHECK IF UNIQUE IN CURRENT AND CONTEXT )
      IF ( WARN USER )  DROP  NFA  ID.
                        4         MESSAGE    SPACE  ENDIF
      HERE  DUP  C@  WIDTH  @        MIN    1+  ALLOT
      DP  C@  OFD  =  ALLOT
      DUP  A0  TOGGLE HERE  1  -  80  TOGGLE ( DELIMIT BITS )
      LATEST  ,  CURRENT  @  ! 
      HERE  rcll +  ,  ;
-->    


(  LITERAL,  DLITERAL,  [COMPILE],  ?STACK        WFR-79APR29 )

: [COMPILE] ( FORCE COMPILATION OF AN IMMEDIATE WORD *)
      -FIND  0=  0  ?ERROR  DROP  CFA  ,  ;  IMMEDIATE

: LITERAL ( IF COMPILING, CREATE LITERAL *)
      STATE  @  IF  COMPILE  LIT  ,  ENDIF  ;  IMMEDIATE

: DLITERAL             ( IF COMPILING, CREATE DOUBLE LITERAL *)
      STATE  @  IF  SWAP  [COMPILE]  LITERAL 
                          [COMPILE]  LITERAL  ENDIF ; IMMEDIATE

(  FOLLOWING DEFINITION IS INSTALLATION DEPENDENT )
: ?STACK    ( QUESTION UPON OVER OR UNDERFLOW OF STACK *)
      s0   SP@  <  1  ?ERROR   SP@  s1   <  7  ?ERROR  ;
-->    
(  INTERPRET,                                     WFR-79APR18 )

: INTERPRET   ( INTERPRET OR COMPILE SOURCE TEXT INPUT WORDS *)
      BEGIN  -FIND 
         IF  ( FOUND )  STATE  @  <
                IF  CFA  ,  ELSE  CFA  EXECUTE  ENDIF  ?STACK
            ELSE  HERE  NUMBER  DPL  @  1+
                IF  [COMPILE]  DLITERAL
                  ELSE   DROP  [COMPILE]  LITERAL  ENDIF  ?STACK
          ENDIF  AGAIN  ;
-->    





(  IMMEDIATE,  VOCAB,  DEFIN,  FORTH,  (      DJK-WFR-79APR29 )
: IMMEDIATE        ( TOGGLE PREC. BIT OF LATEST CURRENT WORD *)
         LATEST  40  TOGGLE  ;

: VOCABULARY  ( CREATE VOCAB WITH 'V-HEAD' AT VOC INTERSECT. *) 
       <BUILDS  81 C, A0 C,  CURRENT  @  2 -  ,
       HERE  VOC-LINK  @  ,  VOC-LINK  !
       DOES>  2+  CONTEXT  !  ;

VOCABULARY  FORTH     IMMEDIATE       ( THE TRUNK VOCABULARY *) 

: DEFINITIONS        ( SET THE CONTEXT ALSO AS CURRENT VOCAB *)
       CONTEXT  @  CURRENT  !  ;
                 
                 ( SKIP INPUT TEXT UNTIL RIGHT PARENTHESIS *)
: (    29  WORD  ;   IMMEDIATE   -->    
(  QUIT, ABORT                                    WFR-79MAR30 )

: QUIT                   ( RESTART,  INTERPRET FROM TERMINAL *)
      0  BLK  !  [COMPILE]  [
      BEGIN  RP!  CR  QUERY  INTERPRET
             STATE  @  0=  IF  ."  OK"  ENDIF  AGAIN  ;

: ABORT                  ( WARM RESTART, INCLUDING REGISTERS *)
      SP!  DECIMAL            DR0
      CR  ." orterforth" 
      [COMPILE]  FORTH  DEFINITIONS  QUIT  ;


-->    


(  COLD START                                     WFR-79APR29 )
CODE COLD               ( COLD START, INITIALIZING USER AREA *)
cold rcod












                                                    -->    
(  MATH UTILITY                               DJK-WFR-79APR29 )
CODE S->D                  ( EXTEND SINGLE INTEGER TO DOUBLE *)
stod rcod

: +-    0< IF MINUS ENDIF ;   ( APPLY SIGN TO NUMBER BENEATH *)

: D+-                  ( APPLY SIGN TO DOUBLE NUMBER BENEATH *)
        0<  IF  DMINUS  ENDIF  ;

: ABS     DUP  +-   ;                 ( LEAVE ABSOLUTE VALUE *)
: DABS    DUP  D+-  ;        ( DOUBLE INTEGER ABSOLUTE VALUE *)

: MIN                         ( LEAVE SMALLER OF TWO NUMBERS *)
        OVER  OVER  >  IF  SWAP  ENDIF  DROP  ;
: MAX                          ( LEAVE LARGER OF TWO NUMBERS *)
        OVER  OVER  <  IF  SWAP  ENDIF  DROP  ; -->    
(  MATH PACKAGE                               DJK-WFR-79APR29 )
: M*     ( LEAVE SIGNED DOUBLE PRODUCT OF TWO SINGLE NUMBERS *)
        OVER  OVER  XOR  >R  ABS  SWAP  ABS  U*  R>  D+-  ;
: M/              ( FROM SIGNED DOUBLE-3-2, SIGNED DIVISOR-1 *)
               ( LEAVE SIGNED REMAINDER-2, SIGNED QUOTIENT-1 *)
        OVER  >R  >R  DABS  R  ABS  U/ 
        R>  R  XOR  +-  SWAP  R>  +-  SWAP  ;
: *      U*  DROP  ;                        ( SIGNED PRODUCT *)
: /MOD   >R  S->D  R>  M/  ;           ( LEAVE REM-2, QUOT-1 *)
: /      /MOD  SWAP  DROP  ;                ( LEAVE QUOTIENT *)
: MOD    /MOD  DROP  ;                     ( LEAVE REMAINDER *)
: */MOD              ( TAKE RATION OF THREE NUMBERS, LEAVING *)
         >R  M*  R>  M/ ;                ( REM-2, QUOTIENT-1 *)
: */     */MOD  SWAP  DROP  ;   ( LEAVE RATIO OF THREE NUMBS *)
: M/MOD   ( DOUBLE, SINGLE DIVISOR ...  REMAINDER, DOUBLE *)
          >R  0  R  U/  R>  SWAP  >R  U/  R>   ;   -->    
(  DISC UTILITY,  GENERAL USE                     WFR-79APR02 )
FIRST  VARIABLE  USE           ( NEXT BUFFER TO USE, STALEST *)
FIRST  VARIABLE  PREV      ( MOST RECENTLY REFERENCED BUFFER *)

: +BUF     ( ADVANCE ADDRESS-1 TO NEXT BUFFER. RETURNS FALSE *)
      82 rcll +            +  DUP  LIMIT  =     ( IF AT PREV *)
      IF  DROP  FIRST  ENDIF  DUP  PREV  @  -  ;

: UPDATE     ( MARK THE BUFFER POINTED TO BY PREV AS ALTERED *)
      PREV  @  @  8000  OR  PREV  @  !  ;

: EMPTY-BUFFERS   ( CLEAR BLOCK BUFFERS; DON'T WRITE TO DISC *)
      FIRST  LIMIT  OVER  -  ERASE  ;

: DR0      0  OFFSET  !  ;                 ( SELECT DRIVE #0 *)
: DR1   07D0  OFFSET  !  ;   -->           ( SELECT DRIVE #1 *)
(  BUFFER                                         WFR-79APR02 )
: BUFFER                 ( CONVERT BLOCK# TO STORAGE ADDRESS *)
    USE  @  DUP  >R          ( BUFFER ADDRESS TO BE ASSIGNED *)
    BEGIN  +BUF  UNTIL ( AVOID PREV )  USE  !  ( FOR NEXT TIME )
    R  @  8000 AND  ( TEST FOR UPDATE IN THIS BUFFER )
    IF ( UPDATED, FLUSH TO DISC )
       R  rcll + ( STORAGE LOC. )
       R  @  7FFF  AND  ( ITS BLOCK # )
       0         R/W     ( WRITE SECTOR TO DISC )
      ENDIF
    R  !  ( WRITE NEW BLOCK # INTO THIS BUFFER )
    R  PREV  !  ( ASSIGN THIS BUFFER AS 'PREV' )
    R>  rcll +  ( MOVE TO STORAGE LOCATION )  ;

-->    

(  BLOCK                                          WFR-79APR02 )
: BLOCK         ( CONVERT BLOCK NUMBER TO ITS BUFFER ADDRESS *) 
   OFFSET  @  +  >R   ( RETAIN BLOCK # ON RETURN STACK )
   PREV  @  DUP  @  R  -  7FFF AND  ( BLOCK = PREV ? )
   IF ( NOT PREV )
      BEGIN  +BUF  0=  ( TRUE UPON REACHING 'PREV' )
         IF ( WRAPPED )  DROP  R  BUFFER
             DUP  R  1         R/W    ( READ SECTOR FROM DISC )
             rcll  - ( BACKUP )
           ENDIF 
           DUP  @  R  -  7FFF AND  0= 
        UNTIL  ( WITH BUFFER ADDRESS ) 
      DUP  PREV  !
     ENDIF 
     R>  DROP    rcll +  ;
-->    
(  TEXT OUTPUT FORMATTING                         WFR-79MAY03 )

: (LINE)        ( LINE#, SCR#, ...  BUFFER ADDRESS, 64 COUNT *)
         >R  C/L  B/BUF  */MOD  R>  B/SCR  *  +
         BLOCK  +  C/L  ;

: .LINE   ( LINE#,  SCR#,  ...  PRINTED *)
         (LINE)  -TRAILING  TYPE  ;

: MESSAGE      ( PRINT LINE RELATIVE TO SCREEN #4 OF DRIVE 0 *)
    WARNING  @
    IF  ( DISC IS AVAILABLE )
        -DUP  IF  4  OFFSET  @  B/SCR  /  -  .LINE  ENDIF
        ELSE  ." MSG # "          .    ENDIF  ;
-->    

(  LOAD, -->                                      WFR-79APR02 )

: LOAD                         ( INTERPRET SCREENS FROM DISC *)
    BLK  @  >R  IN  @  >R  0  IN  !  B/SCR  *  BLK !
    INTERPRET  R>  IN  !  R>  BLK  !  ;

: -->               ( CONTINUE INTERPRETATION ON NEXT SCREEN *)
     ?LOADING  0  IN  !  B/SCR  BLK  @  OVER
     MOD  -  BLK  +!  ;    IMMEDIATE

-->    





(  INSTALLATION DEPENDENT TERMINAL I-O,  TIM      WFR-79APR26 )
( EMIT )













                                   -->    
(  INSTALLATION DEPENDENT TERMINAL I-O,  TIM      WFR-79APR02 )











-->    



(  INSTALLATION DEPENDENT DISC                    WFR-79APR02 )




: #HL            ( CONVERT DECIMAL DIGIT FOR DISC CONTROLLER *)
      0  0A  U/  SWAP  30  +  HOLD  ;

-->    







(  D/CHAR,  ?DISC,                                WFR-79MAR23 )
CODE D/CHAR      ( TEST CHAR-1. EXIT TEST BOOL-2, NEW CHAR-1 *)
dchar rcod




: ?DISC         ( UPON NAK SHOW ERR MSG, QUIT.  ABSORBS TILL *)
      1  D/CHAR  >R  0=                ( EOT, EXCEPT FOR SOH *)
    IF  ( NOT SOH )  R  15 =
         IF ( NAK )  CR
             BEGIN  4  D/CHAR  EMIT
                UNTIL ( PRINT ERR MSG TIL EOT )  QUIT
           ENDIF  ( FOR ENQ, ACK )
          BEGIN  4  D/CHAR  DROP  UNTIL  ( AT EOT )
     ENDIF  R>  DROP  ;   -->    
(  BLOCK-WRITE                                     WFR-790103 )
CODE BLOCK-WRITE     ( SEND TO DISC FROM ADDRESS-2,  COUNT-1 *)
bwrit rcod                                 ( WITH EOT AT END *)









-->    



(  BLOCK-READ,                                     WFR-790103 )

CODE BLOCK-READ   ( BUF.ADDR-1. EXIT AT 128 CHAR OR CONTROL *)
bread rcod










-->    

(  R/W   FOR PERSCI 1070 CONTROLLER               WFR-79MAY03 )
0A  ALLOT  HERE      ( WORKSPACE TO PREPARE DISC CONTROL TEXT )
        ( IN FORM:  C TT SS /D,  TT=TRACK, SS=SECTOR, D=DRIVE )
                                 ( C = I TO READ, O TO WRITE *)
: R/W                                ( READ/WRITE DISC BLOCK *)
               ( BUFFER ADDRESS-3, BLOCK #-2, 1=READ 0=WRITE *)
   LITERAL  HLD  ! ( JUST AFTER WORKSPACE )   SWAP
   0  OVER  >  OVER  0F9F  >  OR  6  ?ERROR
   07D0  ( 2000 SECT/DR )  /MOD  #HL  DROP  2F  HOLD  BL  HOLD
   1A  /MOD  SWAP 1+ #HL  #HL  DROP  BL  HOLD  ( SECTOR 01-26 )
                     #HL  #HL  DROP  BL  HOLD  ( TRACK  00-76 )
   DUP
   IF  49 ( I=READ)  ELSE 4F ( O=WRITE )  ENDIF
   HOLD  HLD  @  0A  BLOCK-WRITE  ( SEND TEXT ) ?DISC
   IF  BLOCK-READ  ELSE  B/BUF  BLOCK-WRITE  ENDIF
   ?DISC  ;     -->    
(  FORWARD REFERENCES                             WFR-79MAR30 )
00  BYTE.IN :          REPLACED.BY  ?EXEC
01 rcls BYTE.IN :      REPLACED.BY  !CSP
02 rcls BYTE.IN :      REPLACED.BY  CURRENT
04 rcls BYTE.IN :      REPLACED.BY  CONTEXT
06 rcls BYTE.IN :      REPLACED.BY  CREATE
07 rcls BYTE.IN :      REPLACED.BY  ]
0B rcls BYTE.IN :      REPLACED.BY  ;S
00  BYTE.IN  ;         REPLACED.BY  ?CSP
01 rcls BYTE.IN ;      REPLACED.BY  COMPILE
03 rcls BYTE.IN ;      REPLACED.BY  SMUDGE
04 rcls BYTE.IN ;      REPLACED.BY  [
05 rcls BYTE.IN ;      REPLACED.BY  ;S
00  BYTE.IN  CONSTANT  REPLACED.BY  CREATE
01 rcls BYTE.IN CONSTANT REPLACED.BY SMUDGE
02 rcls BYTE.IN CONSTANT REPLACED.BY , -->    
(  FORWARD REFERENCES                             WFR-79APR29 )
( 02  BYTE.IN  VARIABLE    REPLACED.BY  (;CODE)
( 02  BYTE.IN  USER        REPLACED.BY  (;CODE) 
03 rcls BYTE.IN ?ERROR   REPLACED.BY  ERROR
08 rcls BYTE.IN ."       REPLACED.BY  WORD
0F rcls BYTE.IN ."       REPLACED.BY  WORD
00  BYTE.IN  (ABORT)     REPLACED.BY  ABORT
0A rcls 5 + BYTE.IN ERROR REPLACED.BY MESSAGE
10 rcls 5 + BYTE.IN ERROR REPLACED.BY QUIT
06 rcls BYTE.IN WORD     REPLACED.BY  BLOCK
10 rcls BYTE.IN CREATE   REPLACED.BY  MESSAGE
17 rcls BYTE.IN CREATE   REPLACED.BY  MIN 
02 rcls BYTE.IN ABORT    REPLACED.BY  DR0
19 rcls BYTE.IN BUFFER   REPLACED.BY  R/W
19 rcls BYTE.IN BLOCK    REPLACED.BY  R/W      DECIMAL ;S    

(  ',  FORGET,  \                                 WFR-79APR28 )
HEX  ( 3   WIDTH  ! )
: '          ( FIND NEXT WORDS PFA; COMPILE IT, IF COMPILING *)
    -FIND  0=  0  ?ERROR  DROP  [COMPILE]  LITERAL  ;
                                    IMMEDIATE

: FORGET            ( FOLLOWING WORD FROM CURRENT VOCABULARY *)
    CURRENT  @  CONTEXT  @  -  18  ?ERROR
    [COMPILE]  '  DUP  FENCE  @  <  15  ?ERROR
    DUP  NFA  DP  !  LFA  @  CURRENT  @  !  ;



-->    


(  CONDITIONAL COMPILER, PER SHIRA                WFR-79APR01 )
: BACK     HERE  -  ,  ;           ( RESOLVE BACKWARD BRANCH *)

: BEGIN    ?COMP  HERE  1  ;                  IMMEDIATE

: ENDIF    ?COMP 2 ?PAIRS  HERE  OVER  -  SWAP  !  ;  IMMEDIATE

: THEN     [COMPILE]  ENDIF  ;    IMMEDIATE

: DO       COMPILE  (DO)  HERE  3  ;            IMMEDIATE

: LOOP     3  ?PAIRS  COMPILE  (LOOP)  BACK  ;  IMMEDIATE

: +LOOP    3  ?PAIRS  COMPILE  (+LOOP)  BACK  ;     IMMEDIATE

: UNTIL    1  ?PAIRS  COMPILE  0BRANCH BACK ; IMMEDIATE -->    
(  CONDITIONAL COMPILER                           WFR-79APR01 )
: END      [COMPILE]  UNTIL  ;  IMMEDIATE

: AGAIN    1  ?PAIRS  COMPILE  BRANCH   BACK  ;   IMMEDIATE

: REPEAT   >R  >R  [COMPILE]  AGAIN
              R>  R>  2  -  [COMPILE]  ENDIF  ;  IMMEDIATE

: IF       COMPILE  0BRANCH   HERE  0  ,  2  ;  IMMEDIATE

: ELSE     2  ?PAIRS  COMPILE  BRANCH  HERE  0  ,
           SWAP  2  [COMPILE]  ENDIF  2  ;      IMMEDIATE

: WHILE    [COMPILE]  IF  2+  ;  IMMEDIATE

-->    
(  NUMERIC PRIMITIVES                             WFR-79APR01 )
: SPACES     0  MAX  -DUP  IF  0  DO  SPACE  LOOP  ENDIF  ;

: <#     PAD  HLD  !  ;

: #>     DROP  DROP  HLD  @  PAD  OVER  -  ;

: SIGN   ROT  0<  IF  2D  HOLD  ENDIF  ;

: #                      ( CONVERT ONE DIGIT, HOLDING IN PAD *)
         BASE @ M/MOD ROT 9 OVER < IF  7 + ENDIF 30  +  HOLD  ;

: #S     BEGIN  #  OVER  OVER  OR  0=  UNTIL  ;
-->    


(  OUTPUT OPERATORS                               WFR-79APR20 )
: D.R        ( DOUBLE INTEGER OUTPUT, RIGHT ALIGNED IN FIELD *)
       >R  SWAP  OVER  DABS  <#  #S  SIGN  #>
       R>  OVER  -  SPACES  TYPE  ;

: D.     0  D.R  SPACE  ;            ( DOUBLE INTEGER OUTPUT *)

: .R     >R  S->D  R>  D.R  ;       ( ALIGNED SINGLE INTEGER *)

: .      S->D  D.  ;                 ( SINGLE INTEGER OUTPUT *)

: ?      @  .  ;                  ( PRINT CONTENTS OF MEMORY *)

'  . CFA ' MESSAGE 12 rcls + 7 + ! ( PRINT MESSAGE NUMBER )
-->    

(  PROGRAM DOCUMENTATION                          WFR-79APR20 )
HEX
: LIST                      ( LIST SCREEN BY NUMBER ON STACK *)
          DECIMAL   CR  DUP  SCR  ! 
         ." SCR # "   .  10  0  DO  CR  I  3  .R  SPACE
         I  SCR  @  .LINE  LOOP  CR  ;

: INDEX      ( PRINT FIRST LINE OF EACH SCREEN FROM-2,  TO-1 *)
         0C  EMIT ( FORM FEED )  CR  1+  SWAP
         DO  CR  I  3  .R  SPACE
             0  I  .LINE
             ?TERMINAL  IF  LEAVE  ENDIF  LOOP  ;
: TRIAD     ( PRINT 3 SCREENS ON PAGE, CONTAINING # ON STACK *)
         0C  EMIT ( FF )  3  /  3  *  3  OVER  +  SWAP
         DO  CR  I  LIST  LOOP  CR
         0F  MESSAGE  CR  ;     DECIMAL   -->    
(  TOOLS                                          WFR-79APR20 )
HEX
: VLIST                            ( LIST CONTEXT VOCABULARY *)
               80  OUT  !    CONTEXT  @  @
     BEGIN  OUT  @  C/L  >  IF  CR  0  OUT  !  ENDIF
            DUP  ID.  SPACE  SPACE    PFA  LFA  @
            DUP  0=  ?TERMINAL  OR  UNTIL  DROP  ;
-->    








(  TOOLS                                          WFR-79MAY03 )
HEX

CREATE MON          ( CALL MONITOR, SAVING RE-ENTRY TO FORTH *)
       ( 0  C,     4C C,   ' LIT 18 + ,    SMUDGE )
       SMUDGE ' rxit CFA @ LATEST PFA CFA !




DECIMAL
HERE              FENCE  !
HERE 14 rcls    +ORIGIN  !   ( COLD START FENCE )
HERE 15 rcls    +ORIGIN  !   ( COLD START DP )
LATEST 6 rcls   +ORIGIN  !   ( TOPMOST WORD )
' FORTH 2+ 2 rcls + 16 rcls +ORIGIN ! ( COLD VOC-LINK ) ;S
