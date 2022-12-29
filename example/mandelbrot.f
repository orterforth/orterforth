















( mandelbrot.f - derived from fract.fs in openbios            )
HEX
: D= ROT = >R = R> AND ;        ( compare double numbers      )
: columns                       ( system specific screen width)
  tg 3948. D= IF 28 ;S ENDIF    ( BBC 40 columns              )
  tg 6774E16F. D= IF 20 ;S ENDIF ( Spectrum 32 columns        )
  50                            ( default 80 columns          )
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
    5E +LOOP ;

DECIMAL
mandelbrot
;S
