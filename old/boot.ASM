;This is the CNOS system bootloader. Based on the MikeOS Bootloader.
use16
jmp short start
nop
OEMLabel	  db "BOOTDRIVE"
BytesPerSector	  dw 512
SectorsPerCluster db 1
ReservedForBoot   dw 1
NumberOfFats	  db 2
RootDirEntries	  dw 224

LogicalSectors	  dw 2880
MediumByte	  db 0F0h
SectorsPerFat	  dw 9
SectorsPerTrack   dw 18
Sides		  dw 2
HiddenSectors	  dd 0
LargeSectors	  dd 0
DriveNo 	  dw 0
Signature	  db 41
VolumeID	  dd 00000000h
VolumeLabel	  db "Nuc's CNOS "
FileSystem	  db "FAT12   "

start:
	mov ax, 07C0h
	add ax, 544
	cli
	mov ss, ax
	mov sp, 4096
	sti
	mov ax, 07C0h
	mov ds, ax


	cmp dl, 0  ;is dl invalid?
	je _nc	   ;yup, let's go fix it...

	mov [bootdev],dl
	mov ah, 8
	int 13h
	jc fatal_disk_error
	and cx,3Fh
	mov [SectorsPerTrack], cx
	movzx dx,dh
	add dx, 1
	mov [Sides], dx
_nc:
	mov eax,0
floppy_ok:
	mov ax, 19
	call l2hts
	mov si, buffer
	mov bx, ds
	mov es, bx
	mov bx, si

	mov ah, 2
	mov al, 14

	pusha
read_root:
	popa
	pusha

	stc
	int 13h

	jnc search_dir
	call reset_flp
	jnc read_root
	jmp reboot

search_dir:
	popa

	mov ax, ds
	mov es, ax
	mov di, buffer

	mov cx, word [RootDirEntries]
	mov ax, 0

next_entry:
	xchg cx, dx

	mov si, kernf
	mov cx, 11
	rep cmpsb
	je found_f

	add ax, 32

	mov di, buffer
	add di, ax

	xchg dx, cx
	loop next_entry

	mov si, f_n_f
	call print
	jmp reboot

found_f:
	mov ax, word [es:di+0Fh]
	mov word [cluster], ax

	mov ax, 1
	call l2hts

	mov di, buffer
	mov bx, di

	mov ah, 2
	mov al, 9

	pusha
fatal_disk_error:
	mov si, disk_error
	call print
	jmp reboot

read_fat_ok:
	popa

	mov ax, 2000h
	mov es, ax
	mov bx, 0

	mov ah, 2
	mov al, 1

	push ax

load_file_sector:
	mov ax, word [cluster]
	add ax, 31

	call l2hts

	mov ax, 2000h
	mov es, ax
	mov bx, word [pointer]

	pop ax
	push ax

	stc
	int 13h

	jnc calc_cluster

	call reset_flp
	jmp load_file_sector

calc_cluster:
	mov ax, [cluster]
	mov dx, 0
	mov bx, 3
	mul bx
	mov bx, 2
	div bx
	mov si, buffer
	add si, ax
	mov ax, word [ds:si]

	or dx, dx

	jz even

odd:
	shr ax, 4
	jmp short next_c_cont

even:
	and ax, 0FFFh
next_c_cont:
	mov word [cluster], ax

	cmp ax, 0FF8h
	jae exit

	add word [pointer], 512
	jmp load_file_sector
exit:
	pop ax
	mov dl, byte [bootdev]
	jmp 2000h:2000h

reboot:
	mov ax, 0
	int 16h
	mov ax, 0
	int 19h

print:
	pusha
	mov ah, 0Eh
_repeat:
	lodsb
	cmp al, 0
	je _ret
	int 10h
	jmp short _repeat
_ret
	popa
	ret
reset_flp:
	push ax
	push dx
	mov ax, 0
	mov dl, byte [bootdev]
	stc
	int 13h
	pop dx
	pop ax
	ret
l2hts:
	push bx
	push ax

	mov bx, ax

	mov dx, 0
	div word [SectorsPerTrack]
	add dl, 01h
	mov cl, dl
	mov ax, bx

	mov dx, 0
	div word [SectorsPerTrack]
	mov dx, 0
	div word [Sides]
	mov dh, dl
	mov ch, al

	pop ax
	pop bx
	mov dl, byte [bootdev]
	ret

kernf db "KERNEL  BIN"
disk_error db "Error, press any key to reboot.",0
f_n_f db "no kernel found.",0
bootdev db 0
cluster dw 0
pointer dw 0

times 510-($-$$) db 0
dw 0AA55h
buffer: