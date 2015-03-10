;filesystem, disk functions
; data
fileloc dw 8000h
disk_buffer     equ     24576
; eject disk drive, args:
; dl : drive number
eject:
        mov ah, 46h
        int 13h
        ret
; open file, args:
; ax : location of filename
open:
        mov [.filename_loc], ax         ; Store filename location
        mov [fileloc], cx        ; And where to load the file!

        mov eax, 0                      ; Needed for some older BIOSes

        call reset_disk          ; In case floppy has been changed
        jnc .floppy_ok                  ; Did the floppy reset OK?

        mov ax, .err_msg_floppy_reset   ; If not, bail out
        jmp error


.floppy_ok:                             ; Ready to read first block of data
        mov ax, 19                      ; Root dir starts at logical sector 19
        call disk_convert_l2hts

        mov si, disk_buffer             ; ES:BX should point to our buffer
        mov bx, si

        mov ah, 2                       ; Params for int 13h: read floppy sectors
        mov al, 14                      ; 14 root directory sectors

        pusha                           ; Prepare to enter loop


.read_root_dir:
        popa
        pusha

        stc                             ; A few BIOSes clear, but don't set properly
        int 13h                         ; Read sectors
        jnc .search_root_dir            ; No errors = continue

        call reset_disk          ; Problem = reset controller and try again
        jnc .read_root_dir

        popa
        jmp .root_problem               ; Double error = exit

.search_root_dir:
        popa

        mov cx, word 224                ; Search all entries in root dir
        mov bx, -32                     ; Begin searching at offset 0 in root dir

.next_root_entry:
        add bx, 32                      ; Bump searched entries by 1 (offset + 32 bytes)
        mov di, disk_buffer             ; Point root dir at next entry
        add di, bx

        mov al, [di]                    ; First character of name

        cmp al, 0                       ; Last file name already checked?
        je .root_problem

        cmp al, 229                     ; Was this file deleted?
        je .next_root_entry             ; If yes, skip it

        mov al, [di+11]                 ; Get the attribute byte

        cmp al, 0Fh                     ; Is this a special Windows entry?
        je .next_root_entry

        test al, 18h                    ; Is this a directory entry or volume label?
        jnz .next_root_entry

        mov byte [di+11], 0             ; Add a terminator to directory name entry

        mov ax, di                      ; Convert root buffer name to upper case
        call upper

        mov si, [.filename_loc]         ; DS:SI = location of filename to load

        call compstr                    ; Current entry same as requested?
        jc .found_file_to_load

        loop .next_root_entry

.root_problem:
        mov bx, 0                       ; If file not found or major disk error,
        stc                             ; return with size = 0 and carry set
        ret


.found_file_to_load:                    ; Now fetch cluster and load FAT into RAM
        mov ax, [di+28]                 ; Store file size to return to calling routine
        mov word [.file_size], ax

        cmp ax, 0                       ; If the file size is zero, don't bother trying
        je .end                         ; to read more clusters

        mov ax, [di+26]                 ; Now fetch cluster and load FAT into RAM
        mov word [.cluster], ax

        mov ax, 1                       ; Sector 1 = first sector of first FAT
        call disk_convert_l2hts

        mov di, disk_buffer             ; ES:BX points to our buffer
        mov bx, di

        mov ah, 2                       ; int 13h params: read sectors
        mov al, 9                       ; And read 9 of them

        pusha

.read_fat:
        popa                            ; In case registers altered by int 13h
        pusha

        stc
        int 13h
        jnc .read_fat_ok

        call reset_disk
        jnc .read_fat

        popa
        jmp .root_problem


.read_fat_ok:
        popa


.load_file_sector:
        mov ax, word [.cluster]         ; Convert sector to logical
        add ax, 31

        call disk_convert_l2hts         ; Make appropriate params for int 13h

        mov bx, [fileloc]


        mov ah, 02                      ; AH = read sectors, AL = just read 1
        mov al, 01

        stc
        int 13h
        jnc .calculate_next_cluster     ; If there's no error...

        call reset_disk          ; Otherwise, reset floppy and retry
        jnc .load_file_sector

        mov ax, .err_msg_floppy_reset   ; Reset failed, bail out
        jmp error


.calculate_next_cluster:
        mov ax, [.cluster]
        mov bx, 3
        mul bx
        mov bx, 2
        div bx                          ; DX = [CLUSTER] mod 2
        mov si, disk_buffer             ; AX = word in FAT for the 12 bits
        add si, ax
        mov ax, word [ds:si]

        or dx, dx                       ; If DX = 0 [CLUSTER] = even, if DX = 1 then odd

        jz .even                        ; If [CLUSTER] = even, drop last 4 bits of word
                                        ; with next cluster; if odd, drop first 4 bits

.odd:
        shr ax, 4                       ; Shift out first 4 bits (belong to another entry)
        jmp .calculate_cluster_cont     ; Onto next sector!

.even:
        and ax, 0FFFh                   ; Mask out top (last) 4 bits

.calculate_cluster_cont:
        mov word [.cluster], ax         ; Store cluster

        cmp ax, 0FF8h
        jae .end

        add word [fileloc], 512
        jmp .load_file_sector           ; Onto next sector!


.end:
        mov bx, [.file_size]            ; Get file size to pass back in BX
        clc                             ; Carry clear = good load
        ret


        .bootd          db 0            ; Boot device number
        .cluster        dw 0            ; Cluster of the file we want to load
        .pointer        dw 0            ; Pointer into disk_buffer, for loading 'file2load'

        .filename_loc   dw 0            ; Temporary store of filename location
        .load_position  dw 0            ; Where we'll load the file
        .file_size      dw 0            ; Size of the file

        .string_buff    times 12 db 0   ; For size (integer) printing

        .err_msg_floppy_reset   db 'os_load_file: Floppy failed to reset', 0

run:
        pusha
        call open
        mov dl, 0
.repeat
        cmp [8000h+dl],0
        je .end
        mov [6000h+dl],[8000h+dl]
        add dl, 1
.end
        call 6000h
        popa
        ret
; returns pointer to char array in ax
read:
        mov ax, fileloc
        ret

reset_disk:
        push ax
        push dx
        mov ax, 0
        mov dl, [bootdev]
        stc
        int 13h
        pop dx
        pop ax
        ret

disk_convert_l2hts:
        push bx
        push ax

        mov bx, ax                      ; Save logical sector

        mov dx, 0                       ; First the sector
        div word [SecsPerTrack]         ; Sectors per track
        add dl, 01h                     ; Physical sectors start at 1
        mov cl, dl                      ; Sectors belong in CL for int 13h
        mov ax, bx

        mov dx, 0                       ; Now calculate the head
        div word [SecsPerTrack]         ; Sectors per track
        mov dx, 0
        div word [Sides]                ; Floppy sides
        mov dh, dl                      ; Head/side
        mov ch, al                      ; Track

        pop ax
        pop bx

; ******************************************************************
        mov dl, [bootdev]               ; Set correct device
; ******************************************************************

        ret
upper:
        pusha

        mov si, ax                      ; Use SI to access string

.more:
        cmp byte [si], 0                ; Zero-termination of string?
        je .done                        ; If so, quit

        cmp byte [si], 'a'              ; In the lower case A to Z range?
        jb .noatoz
        cmp byte [si], 'z'
        ja .noatoz

        sub byte [si], 20h              ; If so, convert input char to upper case

        inc si
        jmp .more

.noatoz:
        inc si
        jmp .more

.done:
        popa
        ret

compstr:
        pusha

.more:
        mov al, [si]                    ; Retrieve string contents
        mov bl, [di]

        cmp al, bl                      ; Compare characters at current location
        jne .not_same

        cmp al, 0                       ; End of first string? Must also be end of second
        je .terminated

        inc si
        inc di
        jmp .more


.not_same:                              ; If unequal lengths with same beginning, the byte
        popa                            ; comparison fails at shortest string terminator
        clc                             ; Clear carry flag
        ret


.terminated:                            ; Both strings terminated at the same position
        popa
        stc                             ; Set carry flag
        ret
Sides dw 2
SecsPerTrack dw 18
bootdev db 0
