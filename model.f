















































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
CODE EMIT   XSAVE STX,  BOT 1+ LDA,  7F # AND,
            72C6 JSR,  XSAVE LDX,  POP JMP,
CODE KEY   XSAVE STX,  BEGIN,  BEGIN,  8 # LDX,
      BEGIN,  6E02 LDA,  .A LSR,  CS END,  7320 JSR,
      BEGIN,  731D JSR,  0 X) CMP,  0 X) CMP,  0 X) CMP,
      0 X) CMP,  0 X) CMP,  6E02 LDA,  .A LSR,  PHP,  TYA,
      .A LSR,  PLP,  CS IF,  80 # ORA,  THEN,  TAY,  DEX,
      0= END,  731D JSR,  FF # EOR,  7F # AND,  0= NOT END,
      7F # CMP,  0= NOT END,  XSAVE LDX,  PUSH0A JMP,
CODE CR  XSAVE STX,  728A JSR,  XSAVE LDX, NEXT JMP,

CODE ?TERMINAL   1 # LDA,  6E02 BIT,  0= NOT IF,
     BEGIN,  731D JSR,  6E02 BIT,  0= END,  INY,  THEN,
     TYA,  PUSH0A  JMP,
DECIMAL       ;S
(  INPUT-OUTPUT,  APPLE                            WFR-780730 )
CODE HOME   FC58 JSR,  NEXT JMP,
CODE SCROLL   FC70 JSR,  NEXT JMP,

HERE  '  KEY  2  -  !    ( POINT KEY TO HERE )
   FD0C JSR,  7F # AND,  PUSH0A JMP,
HERE  ' EMIT  2  -  !   (  POINT EMIT TO HERE  )
   BOT 1+ LDA,  80 # ORA,  FDED JSR,  POP JMP,
HERE  '  CR  2  -  !      ( POINT CR TO HERE )
    FD8E JSR,  NEXT JMP,
HERE  '  ?TERMINAL  2  -  !   ( POINT ?TERM TO HERE )
   C000 BIT,  0<
      IF,  BEGIN,  C010 BIT,  C000 BIT,  0< NOT END,  INY,
        THEN,  TYA,  PUSH0A JMP,

DECIMAL    ;S
(  INPUT-OUTPUT,  SYM-1                            WFR-781015 )
HEX
CODE KEY    8A58 JSR,  7F # AND,  PUSH0A JMP,

CODE EMIT   BOT 1+ LDA,    8A47 JSR,  POP JMP,

CODE CR    834D JSR,  NEXT JMP,

CODE ?TERMINAL  ( BREAK TEST FOR ANY KEY )
    8B3C JSR,  CS
    IF,  BEGIN,  8B3C JSR,  CS NOT  END,  INY,  THEN,
           TYA,  PUSH0A  JMP,



DECIMAL    ;S
















































(  COLD AND WARM ENTRY,  USER PARAMETERS          WFR-79APR29 )
( ASSEMBLER OBJECT MEM ) HEX
0000 , 0000 ,      ( WORD ALIGNED VECTOR TO COLD )
0000 , 0000 ,      ( WORD ALIGNED VECTOR TO WARM )
0000 ,   ver  ,  ( CPU, AND REVISION PARAMETERS )
0000   ,        ( TOPMOST WORD IN FORTH VOCABULARY )
  bs   ,        ( BACKSPACE CHARACTER )
user   ,        ( INITIAL USER AREA )
s0     ,        ( INITIAL TOP OF STACK )
r0     ,        ( INITIAL TOP OF RETURN STACK )
tib    ,        ( TERMINAL INPUT BUFFER )
001F   ,        ( INITIAL NAME FIELD WIDTH )
0000   ,        ( INITIAL WARNING = 1 )
0000   ,        ( INITIAL FENCE )
0000   ,        ( COLD START VALUE FOR DP )
0000   ,        ( COLD START VALUE FOR VOC-LINK ) 5A LOAD -->
(  START OF NUCLEUS,  LIT, PUSH, PUT, NEXT        WFR-78DEC26 )
CODE LIT                   ( PUSH FOLLOWING LITERAL TO STACK *)
5 cd HERE cl - !












-->    
(  SETUP                                           WFR-790225 )








CODE EXECUTE              ( EXECUTE A WORD BY ITS CODE FIELD *)
                                      ( ADDRESS ON THE STACK *)
6 cd HERE cl - !



-->    
(  BRANCH, 0BRANCH     W/16-BIT OFFSET            WFR-79APR01 )
CODE BRANCH            ( ADJUST IP BY IN-LINE 16 BIT LITERAL *)
7 cd HERE cl - !



CODE 0BRANCH           ( IF BOT IS ZERO, BRANCH FROM LITERAL *)
8 cd HERE cl - !





-->    


(  LOOP CONTROL                                   WFR-79MAR20 )
CODE (LOOP)      ( INCREMENT LOOP INDEX, LOOP UNTIL => LIMIT *)
9 cd HERE cl - !





CODE (+LOOP)          ( INCREMENT INDEX BY STACK VALUE +/-   *)
0A cd HERE cl - !





-->    
(  (DO-                                           WFR-79MAR30 )

CODE (DO)             ( MOVE TWO STACK ITEMS TO RETURN STACK *)
0B cd HERE cl - !





CODE I                    ( COPY CURRENT LOOP INDEX TO STACK *)
22 cd HERE cl - !          ( THIS WILL LATER BE POINTED TO 'R' )

-->    



(  DIGIT                                           WFR-781202 )
CODE DIGIT     ( CONVERT ASCII CHAR-SECOND, WITH BASE-BOTTOM *)
                   ( IF OK RETURN DIGIT-SECOND, TRUE-BOTTOM; *)
                                   ( OTHERWISE FALSE-BOTTOM. *)
0C cd HERE cl - !










-->    
(  FIND FOR VARIABLE LENGTH NAMES                  WFR-790225 )
CODE (FIND)  ( HERE, NFA ... PFA, LEN BYTE, TRUE; ELSE FALSE *)
0D cd HERE cl - !












                                                     -->    
(  ENCLOSE                                         WFR-780926 )
CODE ENCLOSE   ( ENTER WITH ADDRESS-2, DELIM-1.  RETURN WITH *)
    ( ADDR-4, AND OFFST TO FIRST CH-3, END WORD-2, NEXT CH-1 *)
0E cd HERE cl - !











-->    
(  TERMINAL VECTORS                               WFR-79MAR30 )
(  THESE WORDS ARE CREATED WITH NO EXECUTION CODE, YET.       )
(  THEIR CODE FIELDS WILL BE FILLED WITH THE ADDRESS OF THEIR )
(  INSTALLATION SPECIFIC CODE.                                )

CODE EMIT             ( PRINT ASCII VALUE ON BOTTOM OF STACK *)

CODE KEY        ( ACCEPT ONE TERMINAL CHARACTER TO THE STACK *)

CODE ?TERMINAL      ( 'BREAK' LEAVES 1 ON STACK; OTHERWISE 0 *)

CODE CR         ( EXECUTE CAR. RETURN, LINE FEED ON TERMINAL *)

-->


(  CMOVE,                                         WFR-79MAR20 )
CODE CMOVE   ( WITHIN MEMORY; ENTER W/  FROM-3, TO-2, QUAN-1 *)
15 cd HERE cl - !








-->    




(  U*,  UNSIGNED MULTIPLY FOR 16 BITS             WFR-79APR08 )
CODE U*        ( 16 BIT MULTIPLICAND-2,  16 BIT MULTIPLIER-1 *)
             ( 32 BIT UNSIGNED PRODUCT: LO WORD-2, HI WORD-1 *)
16 cd HERE cl - !











-->
(  U/,  UNSIGNED DIVIDE FOR 31 BITS               WFR-79APR29 )
CODE U/          ( 31 BIT DIVIDEND-2, -3,  16 BIT DIVISOR-1  *)
                 ( 16 BIT REMAINDER-2,  16 BIT QUOTIENT-1    *)
17 cd HERE cl - !









-->    


(  LOGICALS                                       WFR-79APR20 )

CODE AND           ( LOGICAL BITWISE AND OF BOTTOM TWO ITEMS *)
18 cd HERE cl - !


CODE OR           ( LOGICAL BITWISE 'OR' OF BOTTOM TWO ITEMS *)
19 cd HERE cl - !


CODE XOR        ( LOGICAL 'EXCLUSIVE OR' OF BOTTOM TWO ITEMS *)
1A cd HERE cl - !


-->    

(  STACK INITIALIZATION                           WFR-79MAR30 )
CODE SP@                      ( FETCH STACK POINTER TO STACK *)
1B cd HERE cl - !


CODE SP!                                 ( LOAD SP FROM 'S0' *)
1C cd HERE cl - !

CODE RP!                                   ( LOAD RP FROM R0 *)
1D cd HERE cl - !


CODE ;S              ( RESTORE IP REGISTER FROM RETURN STACK *)
1E cd HERE cl - !

-->    
(  RETURN STACK WORDS                             WFR-79MAR29 )
CODE LEAVE          ( FORCE EXIT OF DO-LOOP BY SETTING LIMIT *)
                                                  ( TO INDEX *)
1F cd HERE cl - !

CODE >R              ( MOVE FROM COMP. STACK TO RETURN STACK *)
20 cd HERE cl - !

CODE R>              ( MOVE FROM RETURN STACK TO COMP. STACK *)
21 cd HERE cl - !

CODE R  ( COPY THE BOTTOM OF THE RETURN STACK TO COMP. STACK *)
22 cd HERE cl - !

( '   R    -2  BYTE.IN  I  ! )
-->    
(  TESTS AND LOGICALS                             WFR-79MAR19 )

CODE 0=           ( REVERSE LOGICAL STATE OF BOTTOM OF STACK *)
23 cd HERE cl - !


CODE 0<            ( LEAVE TRUE IF NEGATIVE; OTHERWISE FALSE *)
24 cd HERE cl - !


-->    





(  MATH                                           WFR-79MAR19 )
CODE +         ( LEAVE THE SUM OF THE BOTTOM TWO STACK ITEMS *)
25 cd HERE cl - !

CODE D+            ( ADD TWO DOUBLE INTEGERS, LEAVING DOUBLE *)
26 cd HERE cl - !



CODE MINUS         ( TWOS COMPLEMENT OF BOTTOM SINGLE NUMBER *)
27 cd HERE cl - !

CODE DMINUS        ( TWOS COMPLEMENT OF BOTTOM DOUBLE NUMBER *)
28 cd HERE cl - !

                                           -->    
(  STACK MANIPULATION                             WFR-79MAR29 )
CODE OVER              ( DUPLICATE SECOND ITEM AS NEW BOTTOM *)
29 cd HERE cl - !

CODE DROP                           ( DROP BOTTOM STACK ITEM *)
2A cd HERE cl - !           ( C.F. VECTORS DIRECTLY TO 'POP' )

CODE SWAP        ( EXCHANGE BOTTOM AND SECOND ITEMS ON STACK *)
2B cd HERE cl - !


CODE DUP                    ( DUPLICATE BOTTOM ITEM ON STACK *)
2C cd HERE cl - !

-->    

(  MEMORY INCREMENT,                              WFR-79MAR30 )

CODE +!   ( ADD SECOND TO MEMORY 16 BITS ADDRESSED BY BOTTOM *)
2D cd HERE cl - !



CODE TOGGLE           ( BYTE AT ADDRESS-2, BIT PATTERN-1 ... *)
2E cd HERE cl - !

-->    





(  MEMORY FETCH AND STORE                          WFR-781202 )
CODE @                   ( REPLACE STACK ADDRESS WITH 16 BIT *)
2F cd HERE cl - !                  ( CONTENTS OF THAT ADDRESS *)


CODE C@      ( REPLACE STACK ADDRESS WITH POINTED 8 BIT BYTE *)
30 cd HERE cl - !

CODE !         ( STORE SECOND AT 16 BITS ADDRESSED BY BOTTOM *)
31 cd HERE cl - SMUDGE ! SMUDGE


CODE C!           ( STORE SECOND AT BYTE ADDRESSED BY BOTTOM *)
32 cd HERE cl - !

DECIMAL     ;S    
(  :,  ;,                                         WFR-79MAR30 )

: :                  ( CREATE NEW COLON-DEFINITION UNTIL ';' *)
                    ?EXEC !CSP CURRENT   @         CONTEXT    !
                CREATE  ]
[ 51 cd ] LITERAL HERE cl MINUS + ! ; IMMEDIATE



: ;                             ( TERMINATE COLON-DEFINITION *)
                    ?CSP  COMPILE     ;S                       
                  SMUDGE  [COMPILE] [    ;   IMMEDIATE         



-->    
(  CONSTANT,  VARIABLE, USER                      WFR-79MAR30 )
: CONSTANT              ( WORD WHICH LATER CREATES CONSTANTS *)
                      CREATE  SMUDGE  ,
[ 52 cd ] LITERAL HERE cl DUP + MINUS + ! ;

: VARIABLE              ( WORD WHICH LATER CREATES VARIABLES *)
     CONSTANT
[ 53 cd ] LITERAL HERE cl DUP + MINUS + ! ;

: USER                                ( CREATE USER VARIABLE *)
     CONSTANT
[ 54 cd ] LITERAL HERE cl DUP + MINUS + ! ;



-->    
(  DEFINED CONSTANTS                              WFR-78MAR22 )
HEX
00  CONSTANT 0        01  CONSTANT  1
02  CONSTANT 2        03  CONSTANT  3
20  CONSTANT BL                                ( ASCII BLANK *)
40  CONSTANT C/L                  ( TEXT CHARACTERS PER LINE *)

FIRST   CONSTANT   FIRST   ( FIRST BYTE RESERVED FOR BUFFERS *)
LIMIT   CONSTANT   LIMIT            ( JUST BEYOND TOP OF RAM *)
  80    CONSTANT   B/BUF            ( BYTES PER DISC BUFFER  *)
   8     CONSTANT  B/SCR  ( BLOCKS PER SCREEN = 1024 B/BUF / *)

           00  +ORIGIN
: +ORIGIN  LITERAL  +  ; ( LEAVES ADDRESS RELATIVE TO ORIGIN *)
-->    

(  USER VARIABLES                                 WFR-78APR29 )
HEX              ( 0 THRU 5 RESERVED,    REFERENCED TO $00A0 *)
( 06 USER  S0 )             ( TOP OF EMPTY COMPUTATION STACK *)
( 08 USER  R0 )                  ( TOP OF EMPTY RETURN STACK *)
05 cs USER  TIB                      ( TERMINAL INPUT BUFFER *)
06 cs USER  WIDTH                 ( MAXIMUM NAME FIELD WIDTH *)
07 cs USER  WARNING                  ( CONTROL WARNING MODES *)
08 cs USER  FENCE                   ( BARRIER FOR FORGETTING *)
09 cs USER  DP                          ( DICTIONARY POINTER *)
0A cs USER  VOC-LINK                  ( TO NEWEST VOCABULARY *)
0B cs USER  BLK                       ( INTERPRETATION BLOCK *)
0C cs USER  IN                     ( OFFSET INTO SOURCE TEXT *)
0D cs USER  OUT                    ( DISPLAY CURSOR POSITION *)
0E cs USER  SCR                             ( EDITING SCREEN *)
-->    

(  USER VARIABLES, CONT.                          WFR-79APR29 )
0F cs USER  OFFSET                ( POSSIBLY TO OTHER DRIVES *)
10 cs USER  CONTEXT              ( VOCABULARY FIRST SEARCHED *)
11 cs USER  CURRENT         ( SEARCHED SECOND, COMPILED INTO *)
12 cs USER  STATE                        ( COMPILATION STATE *)
13 cs USER  BASE                  ( FOR NUMERIC INPUT-OUTPUT *)
14 cs USER  DPL                     ( DECIMAL POINT LOCATION *)
15 cs USER  FLD                         ( OUTPUT FIELD WIDTH *)
16 cs USER  CSP                       ( CHECK STACK POSITION *)
17 cs USER  R#                     ( EDITING CURSOR POSITION *)
18 cs USER  HLD       ( POINTS TO LAST CHARACTER HELD IN PAD *)
-->    




(  HI-LEVEL MISC.                                 WFR-79APR29 )
: 1+      1   +  ;           ( INCREMENT STACK NUMBER BY ONE *)
: 2+      2   +  ;           ( INCREMENT STACK NUMBER BY TWO *)
: HERE    DP  @  ;        ( FETCH NEXT FREE ADDRESS IN DICT. *)
: ALLOT   DP  +! ;                ( MOVE DICT. POINTER AHEAD *)
: ,   HERE  !  cl  ALLOT  ;    ( ENTER STACK NUMBER TO DICT. *)
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

: LFA    2 cs  -  ;             ( CONVERT A WORDS PFA TO LFA *)
: CFA    cl  -  ;               ( CONVERT A WORDS PFA TO CFA *)
: NFA 2 cs 1+ - -1 TRAVERSE ;   ( CONVERT A WORDS PFA TO NFA *)
: PFA 1 TRAVERSE 2 cs 1+ + ;    ( CONVERT A WORDS NFA TO PFA *)
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
        ?COMP  R>  DUP  cl +  >R  @  ,  ;

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
[ 37 cd ] LITERAL LATEST PFA CFA ! ;
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
        R  COUNT  DUP  1+  R>  + ln >R  TYPE  ;


: ."     22  STATE  @       ( COMPILE OR PRINT QUOTED STRING *)
    IF  COMPILE  (.")        WORD    HERE  C@  1+ ln ALLOT
        ELSE        WORD    HERE   COUNT  TYPE  ENDIF  ;
               IMMEDIATE     -->    
(  TERMINAL INPUT                                 WFR-79APR29 )

: EXPECT            ( TERMINAL INPUT MEMORY-2,  CHAR LIMIT-1 *)
    OVER  +  OVER  DO  KEY  DUP  07 cs +ORIGIN ( BS ) @ =
    IF  DROP  08  OVER  I  =  DUP  R>  2  -  + >R  -
       ELSE ( NOT BS )  DUP  0D  =
           IF ( RET ) LEAVE  DROP  BL  0  ELSE  DUP  ENDIF
          I  C!  0 I 1+ C! 0 I 2+ C!
       ENDIF EMIT  LOOP  DROP  ;
: QUERY     TIB  @  50  EXPECT  0  IN  !  ;
HERE 1+
: X  BLK @                            ( END-OF-TEXT IS NULL *)
      IF ( DISC ) 1 BLK +!  0 IN !  BLK @  7  AND  0=
         IF ( SCR END )  ?EXEC  R>  DROP  ENDIF
       ELSE  ( TERMINAL )    R>  DROP
         ENDIF  ; 58 TOGGLE IMMEDIATE  -->
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
      DP  C@  OFD  =  ALLOT HERE ln DP !
      DUP  A0  TOGGLE HERE  1  -  80  TOGGLE ( DELIMIT BITS )
      LATEST  ,  CURRENT  @  ! 
      HERE  cl +  ,  ;
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
  [ s0 ] LITERAL SP@ < 1 ?ERROR SP@ [ s1 ] LITERAL < 7 ?ERROR ;
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
       <BUILDS HERE cl BLANKS 81 C, cl 2 - ALLOT A0 C,
       CURRENT  @  cl -  ,
       HERE  VOC-LINK  @  ,  VOC-LINK  !
       DOES>  cl +  CONTEXT  !  ;
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
38 cd HERE cl - !
2 cs BYTE.IN FORTH 11 cs +ORIGIN !
0 BYTE.IN ABORT 12 cs +ORIGIN !










                                                    -->    
(  MATH UTILITY                               DJK-WFR-79APR29 )
CODE S->D                  ( EXTEND SINGLE INTEGER TO DOUBLE *)
39 cd HERE cl - !

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
      80 2 cs +          +  DUP  LIMIT  =       ( IF AT PREV *)
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
       R  cl + ( STORAGE LOC. )
       R  @  7FFF  AND  ( ITS BLOCK # )
       0         R/W     ( WRITE SECTOR TO DISC )
      ENDIF
    R  !  ( WRITE NEW BLOCK # INTO THIS BUFFER )
    R  PREV  !  ( ASSIGN THIS BUFFER AS 'PREV' )
    R>  cl +  ( MOVE TO STORAGE LOCATION )  ;

-->    

(  BLOCK                                          WFR-79APR02 )
: BLOCK         ( CONVERT BLOCK NUMBER TO ITS BUFFER ADDRESS *) 
   OFFSET  @  +  >R   ( RETAIN BLOCK # ON RETURN STACK )
   PREV  @  DUP  @  R  -  7FFF AND  ( BLOCK = PREV ? )
   IF ( NOT PREV )
      BEGIN  +BUF  0=  ( TRUE UPON REACHING 'PREV' )
         IF ( WRAPPED )  DROP  R  BUFFER
             DUP  R  1         R/W    ( READ SECTOR FROM DISC )
             cl  - ( BACKUP )
           ENDIF 
           DUP  @  R  -  7FFF AND  0= 
        UNTIL  ( WITH BUFFER ADDRESS ) 
      DUP  PREV  !
     ENDIF 
     R>  DROP    cl +  ;
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

(  LOAD,  -->                                     WFR-79APR02 )

: LOAD                         ( INTERPRET SCREENS FROM DISC *)
    BLK  @  >R  IN  @  >R  0  IN  !  B/SCR  *  BLK !
    INTERPRET  R>  IN  !  R>  BLK  !  ;

: -->               ( CONTINUE INTERPRETATION ON NEXT SCREEN *)
     ?LOADING  0  IN  !  B/SCR  BLK  @  OVER
     MOD  -  BLK  +!  ;    IMMEDIATE

-->





(  INSTALLATION DEPENDENT TERMINAL I-O,  TIM      WFR-79APR26 )
( EMIT )
  10 cd cl MINUS BYTE.IN EMIT !




( KEY )
      11 cd cl MINUS BYTE.IN KEY !






                                   -->    
(  INSTALLATION DEPENDENT TERMINAL I-O,  TIM      WFR-79APR02 )

( ?TERMINAL )
     12 cd cl MINUS BYTE.IN ?TERMINAL !




( CR )
    14 cd cl MINUS BYTE.IN CR !


-->    



(  INSTALLATION DEPENDENT DISC                    WFR-79APR02 )




: #HL            ( CONVERT DECIMAL DIGIT FOR DISC CONTROLLER *)
      0  0A  U/  SWAP  30  +  HOLD  ;

-->    







(  D/CHAR,  ?DISC,                                WFR-79MAR23 )
CODE D/CHAR      ( TEST CHAR-1. EXIT TEST BOOL-2, NEW CHAR-1 *)
3A cd HERE cl - !




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
3B cd HERE cl - !                        ( WITH EOT AT END *)









-->    



(  BLOCK-READ,                                     WFR-790103 )

CODE BLOCK-READ   ( BUF.ADDR-1. EXIT AT 128 CHAR OR CONTROL *)
3C cd HERE cl - !










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
01 cs BYTE.IN :        REPLACED.BY  !CSP
02 cs BYTE.IN :        REPLACED.BY  CURRENT
04 cs BYTE.IN :        REPLACED.BY  CONTEXT
06 cs BYTE.IN :        REPLACED.BY  CREATE
07 cs BYTE.IN :        REPLACED.BY  ]
0F cs BYTE.IN :        REPLACED.BY  ;S
00  BYTE.IN  ;         REPLACED.BY  ?CSP
01 cs BYTE.IN ;        REPLACED.BY  COMPILE
03 cs BYTE.IN ;        REPLACED.BY  SMUDGE
04 cs BYTE.IN ;        REPLACED.BY  [
05 cs BYTE.IN ;        REPLACED.BY  ;S
00  BYTE.IN  CONSTANT  REPLACED.BY  CREATE
01 cs BYTE.IN CONSTANT REPLACED.BY SMUDGE
02 cs BYTE.IN CONSTANT REPLACED.BY , -->    
(  FORWARD REFERENCES                             WFR-79APR29 )
( 02  BYTE.IN VARIABLE   REPLACED.BY  (;CODE)
( 02  BYTE.IN USER       REPLACED.BY  (;CODE)
03 cs BYTE.IN ?ERROR   REPLACED.BY  ERROR
08 cs BYTE.IN ."       REPLACED.BY  WORD
10 cs BYTE.IN ."       REPLACED.BY  WORD
00  BYTE.IN  (ABORT)   REPLACED.BY  ABORT
0A cs 5 + BYTE.IN ERROR ln REPLACED.BY MESSAGE
10 cs 5 + BYTE.IN ERROR ln REPLACED.BY QUIT
06 cs BYTE.IN WORD     REPLACED.BY  BLOCK
10 cs BYTE.IN CREATE   REPLACED.BY  MESSAGE
17 cs BYTE.IN CREATE   REPLACED.BY  MIN 
02 cs BYTE.IN ABORT    REPLACED.BY  DR0
19 cs BYTE.IN BUFFER   REPLACED.BY  R/W
19 cs BYTE.IN BLOCK    REPLACED.BY  R/W      DECIMAL ;S    

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

' . CFA ' MESSAGE 12 cs + 7 + ln !     ( PRINT MESSAGE NUMBER )
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
       SMUDGE ' xt CFA @ LATEST PFA CFA !





DECIMAL
HERE              FENCE  !
HERE 14 cs      +ORIGIN  !   ( COLD START FENCE )
HERE 15 cs      +ORIGIN  !   ( COLD START DP )
LATEST 6 cs     +ORIGIN  !   ( TOPMOST WORD )
' FORTH 3 cs + 16 cs +ORIGIN ! ( COLD VOC-LINK ) ;S
( ORTERFORTH INST - PROTO INTERPRETER                         )
( proto-interpreter source to bootstrap the outer interpreter )
:- MINUS + ;S :HERE DP @ ;S :1+ LIT 1 + ;S

:BLANKS LIT 32 SWAP >R OVER C! DUP 1+ R> LIT 1 - CMOVE ;S

:WORD BLK @ BLOCK IN @ + SWAP ENCLOSE HERE LIT 34 BLANKS IN +!
OVER - >R R HERE C! + HERE 1+ R> CMOVE ;S

:-FIND LIT 32 WORD HERE CONTEXT @ @ (FIND) ;S

:, HERE ! cl DP +! ;S

:COMPILE R> DUP cl + >R @ , ;S

:(NUMBER) LIT 0 SWAP DUP >R C@ BASE @ DIGIT 0BRANCH ^11 SWAP
BASE @ U* DROP + R> 1+ BRANCH ^-17 R> DROP ;S

:NUMBER 1+ DUP C@ LIT 45 - 0= DUP >R + (NUMBER) R> 0BRANCH 
^2 MINUS ;S

:INTERPRET -FIND 0BRANCH ^17 STATE @ - 0< 0BRANCH ^6 cl - , 
BRANCH ^4 cl - EXECUTE BRANCH ^-18 HERE NUMBER STATE @ 0BRANCH 
^-24 COMPILE LIT , BRANCH ^-29

:CREATE -FIND 0BRANCH ^3 DROP DROP HERE DUP C@ 1+ DP +! DP
C@ LIT 253 - 0= DP +! HERE ln DP ! DUP LIT 160 TOGGLE HERE LIT
1 - LIT 128 TOGGLE CURRENT @ @ , CURRENT @ ! HERE cl + , ;S

:LOAD BLK @ >R IN @ >R LIT 0 IN ! LIT 8 U* DROP BLK ! INTERPRET 
R> IN ! R> BLK ! ;S

::[ LIT 0 STATE ! ;S

:load CURRENT @ @ 1+ LIT 88 TOGGLE LIT 83 LOAD xt

::X LIT 1 BLK +! LIT 0 IN ! BLK @ LIT 7 AND 0= 0BRANCH ^3 R>
DROP ;S





( ORTERFORTH INST - FORTH                                     )
( Code to load the fig-Forth Model source follows. Some words )
( are forward defined as they are used in the fig source.     )
( Some contain forward references which are resolved once the )
( fig source has created the required definitions. Finally    )
( we modify a few settings.                                   )
CREATE : 51 cd HERE cl - ! 192 STATE !
  CREATE 192 STATE ! 51 cd HERE cl - !
  ;S [ CURRENT @ @ 96 TOGGLE
: ; COMPILE ;S CURRENT @ @ 32 TOGGLE 0 STATE !
  ;S [ CURRENT @ @ 96 TOGGLE
: IMMEDIATE CURRENT @ @ 64 TOGGLE ;
: ( 41 WORD ; IMMEDIATE ( now we have comment syntax.         )

( need --> in order to progress to next screen                )
: --> 0 IN ! 8 BLK @ 7 AND - BLK +! ; IMMEDIATE
-->




( forward reference words - these may be no-ops but may need  )
( stack effects e.g. . calls DROP. Others may never be called )
: noop ; : ?EXEC ; : !CSP SP@ CSP ! ; : ] 192 STATE ! ;
: ?CSP ; : SMUDGE CURRENT @ @ 32 TOGGLE ; : ERROR ; : ABORT ;
: MESSAGE ; : QUIT ; : MIN ; : DR0 ; : R/W ; : . DROP ;
( these words are called by the model source                  )
: HEX 16 BASE ! ; : CODE CREATE SMUDGE ;
: DECIMAL 10 BASE ! ;
: LITERAL COMPILE noop , ; IMMEDIATE
: +ORIGIN origin + ;
: [COMPILE] -FIND DROP DROP cl - , ; IMMEDIATE
: BYTE.IN -FIND DROP DROP + ;
: REPLACED.BY -FIND DROP DROP cl - SWAP ! ;
-->


( control words - some contain 'noop' forward references      )
: BACK HERE - , ;
: BEGIN HERE 1 ; IMMEDIATE
: ENDIF DROP HERE OVER - SWAP ! ; IMMEDIATE
: DO COMPILE noop HERE 3 ; IMMEDIATE
: LOOP DROP COMPILE noop BACK ; IMMEDIATE
: UNTIL DROP COMPILE noop BACK ; IMMEDIATE
: AGAIN DROP COMPILE noop BACK ; IMMEDIATE
: REPEAT >R >R [COMPILE] AGAIN R> R> 2 - [COMPILE] ENDIF ;
IMMEDIATE
: IF COMPILE noop HERE 0 , 2 ; IMMEDIATE
: ELSE DROP COMPILE noop HERE 0 , SWAP 2 [COMPILE] ENDIF 2 ;
IMMEDIATE
: WHILE [COMPILE] IF 2 + ; IMMEDIATE
-->

( move DP back to origin                                      )
0 +ORIGIN DP !
( load boot-up parameters and machine code definitions        )
12 LOAD
( now resolve forward references in control words & LITERAL   )
( NB we could wait until now to define these but that would   )
( be inauthentic - they would be pre-existing in Forth        )
01 cs BYTE.IN LITERAL   REPLACED.BY LIT
01 cs BYTE.IN DO        REPLACED.BY (DO)
02 cs BYTE.IN LOOP      REPLACED.BY (LOOP)
02 cs BYTE.IN UNTIL     REPLACED.BY 0BRANCH
02 cs BYTE.IN AGAIN     REPLACED.BY BRANCH
01 cs BYTE.IN IF        REPLACED.BY 0BRANCH
02 cs BYTE.IN ELSE      REPLACED.BY BRANCH
26 cs BYTE.IN INTERPRET REPLACED.BY LIT
-->
( load high level utility definitions                         )
33 LOAD
( some forward references to HERE needed by our novel defns   )
10 cs BYTE.IN :        REPLACED.BY HERE
05 cs BYTE.IN CONSTANT REPLACED.BY HERE
03 cs BYTE.IN VARIABLE REPLACED.BY HERE
03 cs BYTE.IN USER     REPLACED.BY HERE
( load high level definitions                                 )
72 LOAD
( set EMIT and CR CFAs after silent install                   )
15 cd ' EMIT CFA ! 19 cd ' CR CFA !
( installed flag = 1                                          )
1 installed C!


-->
( WARNING = 1                                                 )
1 13 cs +ORIGIN !
( SAVE TO DR1                                                 )
HERE 62 cs ALLOT                ( make room for link table    )
FIRST cl + CONSTANT buf         ( use first disc buffer       )
2000 VARIABLE blk               ( first block of DR1          )
: link                          ( --                          )
  link? IF 
    62 0 DO I cd , LOOP         ( table of code addresses     )
    -62 cs ALLOT                ( move DP back before table   )
  ENDIF ;
: start                         ( -- a-addr                   )
  link? IF origin ELSE org ENDIF ;
: end                           ( -- a-addr                   )
  HERE link? IF 62 cs + ENDIF ;
-->
: save                          ( --                          )
  save? IF
    link                        ( write link table            )
    end start DO                ( write blocks of hex         )
      I buf sb buf blk @ 0 R/W
      1 blk +!
    64 +LOOP
    buf 128 90 FILL             ( write a block of 'Z's       )
    buf blk @ 0 R/W
  ENDIF ;

DP !                            ( move DP back                )
0 ' cl LFA !                    ( break inst dictionary link  )
save                            ( now save                    )

;S
( COMPILED AFTER BOOT-UP LITERALS                             )
( extra boot-up literals for COLD                             )
0 , 0 ,
( extra boot-up literals for tg                               )
th , tl ,
( additional words                                            )
CODE cl 0 cd HERE SMUDGE cl SMUDGE - !
CODE cs 1 cd HERE cl - !
CODE ln 2 cd HERE cl - !
CODE tg 3 cd HERE cl - !
CODE xt 4 cd HERE cl - !




;S
