main:
        mov ax, 2000h                   ;set up the stack
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov si, hello
        call print
waitkey:
        pusha

        mov ax, 0
        mov ah, 10h                     ; BIOS call to wait for key
        int 16h

        mov [.tmp_buf], ax              ; Store resulting keypress

        popa                            ; But restore all other regs
        mov ax, [.tmp_buf]
        ret


        .tmp_buf        dw 0
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
.rep:
        call waitkey
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
        mov [bx+5750h],byte 0    ; Just in case...
        mov [2],bx
        popa
        mov bx, [2]
        mov si, 5750h
        ret      
; returns kernel end point into ax
end:
        mov ax, end_kernel
        ret

error:
        mov si, errors
        call print
        ret
%include "source/fs.asm"
%include "source/scrn.asm"
%include "source/ser.asm"
;data
hello db "hello, world!",0
errors db "ERROR",0
end_kernel:
