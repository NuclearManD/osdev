@echo off
nasm kernel.asm -o kernel.bin
cd programs
 for %%i in (*.asm) do nasm -O0 -fbin %%i
 for %%i in (*.prg) do del %%i
 for %%i in (*.) do ren %%i %%i.prg
cd ..
pause