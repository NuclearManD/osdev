bits 16
syscall:
        jmp main     ; 0000h, kernel 1
        jmp print    ; 0003h  scrn   1
        jmp cursor   ; 0006h  scrn   1
        jmp cls      ; 0009h  scrn   1
        jmp waitkey  ; 000Ch  kernel 1
        jmp tone     ; 000Fh  kernel 1
        jmp run      ; 0012h  fs     1
        jmp open     ; 0015h  fs     1
        jmp read     ; 0018h  fs     1
        ;jmp create   ; 001Bh  fs    x
        jmp sstart   ; 001Bh  ser    0
        jmp sin      ; 001Eh  ser    0
        jmp sout     ; 0021h  ser    0
        jmp eject    ; 0024h  fs     1
        jmp end      ; 0027h  kernel 1
        ;jmp delete   ; 002Dh  fs    x
        ;jmp rename   ; 00h  fs      x
        ;jmp write    ; 001Eh  fs    x
        ;jmp append   ; 0021h  fs    x
main:
        mov si, hello
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
