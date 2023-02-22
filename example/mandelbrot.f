( mandelbrot.f - derived from fract.fs in openbios            )














-->
( mandelbrot.f - derived from fract.fs in openbios            )
HEX

( compare double numbers                                      )
: D=                            ( d1 d2 -- f )
  ROT = >R = R> AND ;           ( compare high and low words  )

( system specific screen width                                )
: columns                       ( -- u )
  tg     3948. D= IF 28 ;S ENDIF ( BBC 40 columns             )
  tg 3195C1F7. D= IF 20 ;S ENDIF ( Dragon 32 columns          )
  tg 6774E16F. D= IF 20 ;S ENDIF ( Spectrum 32 columns        )
  50                            ( default 80 columns          )
;

-->
( mandelbrot.f - derived from fract.fs in openbios            )

( system specific screen height                               )
: rows                           ( -- u )
  tg     3948. D= IF 19 ;S ENDIF ( BBC 25 rows                )
  tg 3195C1F7. D= IF 10 ;S ENDIF ( Dragon 16 rows             )
  tg 6774E16F. D= IF 18 ;S ENDIF ( Spectrum 24 rows           )
  18                            ( default 24 rows             )
;






-->
( mandelbrot.f - derived from fract.fs in openbios            )
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
                DUP DUP 400 */ ROT
                DUP DUP 400 */ ROT
-->
( mandelbrot.f - derived from fract.fs in openbios            )
                SWAP OVER OVER + 1000 > IF ( if diverging     )
                    DROP DROP DROP DROP DROP
                    BL 0 DUP OVER OVER LEAVE ( space          )
                ENDIF
            LOOP
            DROP DROP DROP DROP
            EMIT                ( * or space                  )
        [ 400 3 * columns 2 - / ] ( compute step from cols    )
        LITERAL +LOOP
        CR DROP                 ( end of line                 )
    [ 466 2+ 2 * rows / ] LITERAL +LOOP ;

mandelbrot DECIMAL ;S
