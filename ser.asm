;start serial
; in: al : bps dx : port id
sstart:
        pusha
        mov ah,0
        int 14h
        popa
        ret
;print a string si to port dx
sout:
        pusha
.rep:
        lodsb
        cmp al, 0
        je .end
        out dx, al
        jmp .rep

.end:
        popa
        ret
;sin: get serial data
;out: AL : byte from a port
sin:
        pusha

        in al, dx
        mov word [.tmp], ax

        popa
        mov ax, [.tmp]
        ret


        .tmp dw 0
