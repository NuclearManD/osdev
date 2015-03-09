print:
        pusha
        mov ah, 09h

.rep:
        lodsb
        cmp al, 0
        je .end
        int 10h
        jmp .rep

.end:
        mov bh, 0
        mov ah, 3
        int 10h
        add dh, 1
        mov dl, 0
        call cursor
        popa
        ret

cls:
        pusha

        mov dx, 0                       ; Position cursor at top-left
        call cursor

        mov ah, 6                       ; Scroll full-screen
        mov al, 0                       ; Normal white on black
        mov bh, 7                       ;
        mov cx, 0                       ; Top-left
        mov dh, 24                      ; Bottom-right
        mov dl, 79
        int 10h

        popa
        ret
cursor:
        pusha

        mov bh, 0
        mov ah, 2
        int 10h                         ; BIOS interrupt to move cursor

        popa
        ret
