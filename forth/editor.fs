















( SCREEN EDITOR                                               )
6 LOAD ;S














( SCREEN EDITOR                                               )















( SCREEN EDITOR                                               )

( An interactive screen editor in an ANSI terminal.           )
( Arrow keys, newline, backspace supported.                   )
( Ctrl+X to save and exit.                                    )











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







( SCREEN EDITOR                                               )
FORTH VOCABULARY editor IMMEDIATE editor DEFINITIONS DECIMAL
( ansi terminal handling                                      )
: esc 27 EMIT 91 EMIT ;
: dec BASE @ SWAP DECIMAL 0 0 D.R BASE ! ;
: cls esc ." 2J" esc 72 EMIT ;
: at esc 1+ dec 59 EMIT 1+ dec 72 EMIT ;
( cursor position                                             )
0 VARIABLE row 0 VARIABLE column
: move column @ 4 + row @ 2+ at ;
: down 1 row +! row @ 15 > IF 0 row ! ENDIF move ;
: right 1 column +! column @ 63 > IF 
  0 column ! down ENDIF move ;
: newline 0 column ! down move ;
: up row @ IF -1 row +! ELSE 15 row ! ENDIF move ;
-->
( SCREEN EDITOR                                               )
: left column @ IF -1 column +! ELSE 
  63 column ! up ENDIF move ;
( operations                                                  )
0 VARIABLE screen
: block screen @ B/SCR * row @ 2 / + ;
: addr block BLOCK row @ 1 AND IF 64 + ENDIF column @ + ;
: write DUP EMIT addr C! UPDATE right ;
: flush 8 0 DO 32767 BUFFER DROP LOOP ;






-->
( SCREEN EDITOR                                               )
: arrow
  KEY 91 - IF ;S ENDIF
  KEY DUP 65 = IF DROP up ;S ENDIF
  DUP 66 = IF DROP down ;S ENDIF
  DUP 67 = IF DROP right ;S ENDIF
  DUP 68 = IF DROP left ;S ENDIF
  DROP ;
: del left BL write left ;
: exit flush 0 18 at R> DROP R> DROP ;S ;





-->
( SCREEN EDITOR                                               )
: type
  KEY
  DUP 13 = IF DROP newline ;S ENDIF ( CR                      )
  DUP 24 = IF DROP exit ENDIF       ( CAN Ctrl+X              )
  DUP 27 = IF DROP arrow ;S ENDIF   ( ESC arrow key sequences )
  DUP BL < IF DROP ;S ENDIF         ( other C0 not valid      )
  DUP [ 7 cs +ORIGIN @ ] LITERAL = IF DROP del ;S ENDIF ( DEL )
  write ;
: edit screen ! cls screen @ LIST move BEGIN type AGAIN ;
FORTH DEFINITIONS
;S
