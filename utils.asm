section .text

global strcmp
global memcmp
global memset


; rdi - null terminated string
; rsi - null terminated string
; rax - 1 if eq, 0 if not equals
strcmp:
    mov     cl, byte [rdi]
    mov     dl, byte [rsi]

    cmp     cl, dl
    jne     _strcmp_ne

    cmp     cl, 0
    je      _strcmp_eq

    inc     rdi
    inc     rsi

    jmp     strcmp

_strcmp_ne:
    mov     rax, 0
    ret

_strcmp_eq:
    mov     rax, 1
    ret


; rdi - byte sequence
; rsi - byte sequence
; rdx - amount of bytes
; rax - 1 if eq, 0 if not equals
memcmp:
    mov     rcx, rdx

_memcmp_loop:
    mov     al, byte [rdi]
    mov     bl, byte [rsi]

    cmp     al, bl
    jne     _memcmp_ne

    inc     rdi
    inc     rsi

    loop    _memcmp_loop

_memcmp_eq:
    mov     rax, 1
    ret

_memcmp_ne:
    mov     rax, 0
    ret


; rdi - pointer
; rsi - the byte
; rdx - count
; rax - no return
memset:
    mov     rcx, rdx
    mov     rax, rsi

_memset_loop:
    mov     byte [rdi], al
    inc     rdi

    loop _memset_loop
    ret