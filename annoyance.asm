bits 16
org 6000h
jmp main

        main:
call eject   ;void args func access

mov si,start   ;si args func access
call print

call tone   ;void args func access
ret



%include "kernel.inc"
start db "your computer has fired a fatal error. it may not last long.",0
