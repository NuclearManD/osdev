use16

	MIKEOS_VER: dd '4.4'	    ; OS version number
	MIKEOS_API_VER: dw 16	    ; API version for programs to check


	; This is the location in RAM for kernel disk operations, 24K
	; after the point where the kernel has loaded; it's 8K in size,
	; because external programs load after it at the 32K point:

	disk_bufferl	 equ	 24576
	jmp main
	;jmp write    ; 0033h  fs    x
	;jmp append   ; 0036h  fs    x
main:
	cli				; Clear interrupts
	mov ax, 0
	mov ss, ax			; Set stack segment and pointer
	mov sp, 0FFFFh
	sti				; Restore interrupts

	cld				; The default direction for string operations
					; will be 'up' - incrementing address in RAM

	mov ax, 2000h			; Set all segments to match where kernel is loaded
	mov ds, ax			; After this, we don't need to bother with
	mov es, ax			; segments ever again, as MikeOS and its programs
	mov fs, ax			; live entirely in 64K
	mov gs, ax
	mov si, startup
	call print

loop:
	call getcmd
	call run
	jmp loop
waitkey:
	pusha

	mov ax, 0
	mov ah, 10h			; BIOS call to wait for key
	int 16h

	mov [.tmp_buf], ax		; Store resulting keypress

	popa				; But restore all other regs
	mov ax, [.tmp_buf]
	ret


	.tmp_buf	dw 0
; make a tone, 0 to turn off. args:
; ax : tone
tone:
	pusha
	cmp ax, 0
	je .off
	mov cx, ax
	mov al, 182
	out 43h, al
	mov ax, cx
	out 42h, al
	mov al,ah
	out 42h, al
	in al, 61h
	or al, 03h
	out 61h, al
	popa
	ret
.off:
	in al, 61h
	and al, 0FCh
	out 61h, al
	popa
	ret
; returns a pointer to si
getcmd:
	pusha
	mov bx,0
	mov ah, 0Eh
	mov al, '>'
	int 10h
.rep:
	call waitkey
	mov ah, 0Eh
	int 10h
	cmp al, 13
	je .ret
	cmp al, 8
	je .back
	mov [bx+5750h], ax  ; I highly doubt anyone will use 640 bytes of the stack through user input.
	inc bx
	jmp .rep

.back:
	mov al, ' '
	int 10h
	dec dh
	dec bx
	call cursor
	jmp .rep
.ret:
	;inc bx
	mov [bx+5750h],byte 0	 ; Just in case...
	mov [2],bx
	popa
	mov bx, [2]
	mov si, 5750h
	inc dh
	mov dl, 0
	call cursor
	ret	 
; returns kernel end point into ax
end:
	mov ax, end_kernel
	ret

error:
	mov si, errors
	call print
	ret

;data
startup db "welcome to your CNOS computer.",0
errors db "ERROR",0
logo db "CNOS",0
line db "________________________________________",0
%include "fs.asm"
%include "scrn.asm"
%include "ser.asm"
;data
end_kernel:
