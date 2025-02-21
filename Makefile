build:
	nasm -felf64 -g -F dwarf main.asm
	nasm -felf64 -g -F dwarf utils.asm
	ld utils.o main.o