/* receive.rexx
** Written by Wolfgang Stoeggl (1998, 2004) */
/*say 'Filename?'; pull file*/
/*say 'Bytes?'; pull size*/
say 'Now send the file!'
open('1','ser:')
open('2',file,'W')
n = 1024
lof = 0
do while lof < size
 lof = seek('2', 0, E)
 diff = size-lof
 if diff < 1024 then n = diff
 t = readch('1', n)
 writech('2', t)
 say lof || '0b'x
end
say 'Received file: 'file''
say 'Filelength = 'lof' bytes'
close('1'); close('2')
exit
