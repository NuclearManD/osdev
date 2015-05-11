org 7000h
	cmp si, 0
	je help

	mov di, trmcmd
	call stringcomp
	jc terminal

	jmp readfile
help:
	mov ax, help1
	mov bx, help2
	mov cx, help3
	mov dx, 0
	call dialogbox
	ret
readfile:
	mov cx, 8000h
	mov [.tmp], cx
	mov ax, si
	call openfile
	jc .error
	mov word [retloc], .loop

.loop:
	mov si, word [.tmp] ; get position in file
	mov al, 13
	call tokenize

	mov word [.tmp], di
	cmp di, 0	; no more?
	je end

	mov di, exitcom ; are we exiting?
	call stringcomp
	jc end


	mov al, ' '	; nope, tokenize
	call tokenize

	mov [tdi],di
	mov di, printcom      ; print [bla bla bla]
	call stringcomp
	jc mprint

	mov di, clscom
	call stringcomp
	jc mcls

	mov si, .comnotfound  ; NOT FOUND D:
	call print
	call newline
	jmp end

	jmp .loop
.error:
	call error
	jmp end

   .tmp dw 0
   .comnotfound db "ERROR_UNDEF",0
terminal:
	call clearScreen
	mov si, .terminalbootstr
	call print
	mov word [retloc], .loop
.loop:
	mov si, .inp	; show a " >> "
	call print

	mov ax, .buffer
	call input	; get our input in lowercase
	call lower

	call newline

	mov si, ax
	mov di, exitcom ; are we exiting?
	call stringcomp
	jc end

	mov al, ' '	; nope, tokenize
	call tokenize

	mov [tdi],di
	mov di, printcom      ; print [bla bla bla]
	call stringcomp
	jc mprint

	mov si, .comnotfound  ; NOT FOUND D:
	call print
	call newline

	jmp .loop

   .terminalbootstr db "NUC terminal        ~enjoy~ ",13,0
   .comnotfound     db "ERROR: not a command!",0
   .buffer times 256 db 0
   .inp 	    db " >> ",0

;   NUC COMMAND FUNCTIONS
mprint:
	mov si, [tdi]
	call print
	call newline
	jmp [retloc]

mcls:
	call clearScreen
	jmp [retloc]
end:
	ret
help1  db "nuc code interpreter, open in cmd.prg as",0
help2  db "'nuc.prg [filename w/o extention]'. to",0
help3  db "use the terminal do 'nuc.prg trm' in cmd",0
trmcmd db "trm",0
tdi    dw 0
retloc dw 0

;   COMMANDS

exitcom      db "exit",0
printcom     db "print",0
clscom	     db "cls",0

%include "cnos.inc"