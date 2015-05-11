org 7000h
init:
	mov ax, top
	mov bx, e
	mov cx, 00111111b
	call fillScreen

	mov ax, fileoptions
	mov bx, createornot
	mov cx, e
	call listdialog

	cmp ax,1
	je newfile

	cmp ax, 2
	je fileopen

	jmp end
   createornot db   "create a new file, open one, or leave?",0
   top	       db   "Nuclear Inc Word Processor",0
   fileoptions db   "new,open,exit",0

newfile:
	mov ax, fname
	mov bx, newdialog
	call inputdialog

	call exists
	jnc delete
	jmp editor
   newdialog db "type name for new file:",0

fileopen:
	call fileselect
	jc end
	mov si, ax
	mov di, fname
	call stringcopy
	mov cx, fdata
	call openfile
	jc err

editor:
	call readuser

	mov ax, saveornot
	call lower
	mov bx, e
	mov cx, e
	mov dx, 1
	call dialogbox

	cmp cx, 1
	je end

	mov ax, fname			     ; Delete the file if it already exists
	call delete

	mov ax, fname
	mov bx, fdata
	mov cx, di
	sub cx, fdata
	call filewrite
	jc near err
	ret
err:
	pusha
	mov ax, errmsg
	mov bx, e
	mov cx, e
	mov dx, 0
	call dialogbox
	popa
	ret
   errmsg db "error writing or reading file",0
readuser:
	pusha

	mov ax, fname
	call lower
	mov bx, top
	mov cx, 00111111b
	call fillScreen

	mov di, fdata
	mov dl,0
	mov dh,1
	call setCursorPos

	mov si, di
	call print

	call getCursorPos
	mov [tmp],dl
	add di, [tmp]
.more:					; Now onto string getting
	call waitkey

	cmp al, 27			; If Escape key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .backspace			; If not, skip following checks

	cmp al, 13
	je .nl

	cmp al, ' '			; In ASCII range (32 - 126)?
	jb .more			; Ignore most non-printing characters

	cmp al, '~'
	ja .more

	jmp .nobackspace


.backspace:
	cmp di, fdata		      ; Backspace at start of string?
	je .more			; Ignore it if so

	call getCursorPos		; Backspace at start of screen line?
	cmp dl, 0
	je .backspace_linestart

	pusha
	mov ah, 0Eh			; If not, write space and move cursor back
	mov al, 8
	int 10h 			; Backspace twice, to clear space
	mov al, 32
	int 10h
	mov al, 8
	int 10h
	popa

	dec di				; Character position will be overwritten by new
					; character or terminator at end

	jmp .more


.backspace_linestart:
	dec dh				; Jump back to end of previous line
	mov dl, 79
	call setCursorPos
	dec di				; Step back position in string
.nxinnlsource:
	mov ah, 08h
	int 10h
	call .print
	cmp al, ' '
	jne .nextnldelstep
	dec dl
	call setCursorPos
	cmp dl,0
	je .more
	jmp .nxinnlsource
.nextnldelstep:
	inc dl
	call setCursorPos
	jmp .more
.print:
	mov byte [tmp], dl
	push dx
	mov byte dl, [tmp]
	mov dh, 20
	mov ah, 0Eh
	call setCursorPos
	int 10h
	pop dx
	call setCursorPos
	ret
.nobackspace:
	pusha
	mov ah, 0Eh			; Output entered, printable character
	int 10h
	popa

	stosb				; Store character in designated buffer
	jmp near .more			; Still room for more
.nl:
	call newline
	stosb
	jmp near .more

.done:
	mov al, 0
	stosb
	mov [tmp],di
	popa
	mov di,[tmp]
	ret
end:
	ret
%include "cnos.inc"
e	    db	 ' ',0
saveornot db "do you want to save "
fname  times 16   db 0
fdata  times 1024 db 0
tmp dw 0