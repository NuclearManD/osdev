print	      equ 003h  ;si is pointer to string
setCursorPos  equ 006h  ;dh=row, dl=colmn
clearScreen   equ 009h
hline	      equ 00Ch  ;AX= size
newline       equ 00Fh
waitkey       equ 012h  
checkkey      equ 015h
inttostring   equ 018h
tone	      equ 01Bh
notone	      equ 001Eh
openfile      equ 021h
waitprg       equ 024h
fatalerror    equ 027h
fillScreen    equ 02Ah  ;AX and BX = top and bottom string locations, CX = colour
stringlength  equ 02Dh
upper	      equ 030h
lower	      equ 033h
input	      equ 036h
stringcopy    equ 039h
dialogbox     equ 03Ch  ;AX BX CX = string pointers, DX = dialogbox type, returns to CX
stringappend  equ 03Fh
listfiles     equ 042h
stringcomp    equ 045h
__UNDEF__     equ 048h
strip	      equ 04Bh
truncate      equ 04Eh
bcdtoint      equ 051h
gettime       equ 054h
error	      equ 057h
fileselect    equ 05Ah   ;
getdate       equ 05Dh
serout	      equ 060h
serin	      equ 063h
getcharloc    equ 066h
getCursorPos  equ 069h
spaceprint    equ 06Ch
dumpstring    equ 06Fh
printdigit    equ 072h
printnib      equ 075h
printbyte     equ 078h
printint      equ 07Bh
longtostring  equ 07Eh
longneg       equ 081h
settime       equ 084h
setdate       equ 087h
showcursor    equ 08Ah
grabcursor    equ 08Dh
dumpregisters equ 090h
stringcmpto   equ 093h
filewrite     equ 096h
exists	      equ 099h
filecreate    equ 09Ch
delete        equ 09Fh
rename        equ 0A2h
filesize      equ 0A5h
inputdialog   equ 0A8h  ;AX=string pointer, BX=message, returns to AX=string location
listdialog    equ 0ABh  ;AX = pointer to comma-separated list string BX/CX = dialog, returns to ax
stringreverse equ 0AEh
stringtoint   equ 0B1h
drawblock     equ 0B4h
random        equ 0B7h
setchar       equ 0BAh
openserial    equ 0BDh
sinttostring  equ 0C0h
parse         equ 0C3h
portout	      equ 0C6h
portin	      equ 0C9h
tokenize      equ 0CCh
cliline       equ 0CFh