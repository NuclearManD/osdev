k_main  equ     0000h   ; Where the OS code starts
cls     equ     0009h   ; (Nothing used)
print   equ     0003h   ; SI = zero-terminated string location
cursor  equ     0006h   ; DH, DL = row, column
waitkey equ     000Ch   
tone    equ     000Fh   
run     equ     0012h   
open    equ     0015h   
read    equ     0018h   
sstart  equ     001Bh
sin     equ     001Eh
sout    equ     0021h
eject   equ     0024h
end     equ     0027h             
