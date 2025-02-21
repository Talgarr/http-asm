global _start

extern strcmp
extern memcmp
extern memset


section .rodata

method_get: db 'GET', 0
method_post: db 'POST', 0
path_index: db '/', 0
http_badrequest: db 'HTTP/1.0 400 BAD REQUEST', 0x0d, 0x0a, 0x0d, 0x0a
http_notfound: db 'HTTP/1.0 404 NOT FOUND', 0x0d, 0x0a, 0x0d, 0x0a


section .text

_start:
    ; socket(AF_INET, SOCK_STREAM, 0)
    mov     rax, 41
    mov     rdi, 2
    mov     rsi, 1
    mov     rdx, 0
    syscall

    mov     r12, rax
    ; r13 = fd

    ; sockaddr_in {
        ; sa_family_t = 2 bytes
        ; in_port_t   = 2 bytes
        ; in_addr     = 4 bytes
    ; }

    ; create socket on stack
    sub     rsp, 16
    mov     word [rsp], 2
    mov     word [rsp + 2], 0x3575
    mov     dword [rsp + 4], 0

    ; bind(sockfd, &addr, sizeof(addr))
    mov     rax, 49
    mov     rdi, r12
    mov     rsi, rsp
    mov     rdx, 16
    syscall

    ; listen(fd,  4)
    mov     rax, 50
    mov     rdi, r12
    mov     rsi, 4
    syscall

_accept_loop:
    ; accept(fd)
    mov     rax, 43
    mov     rdi, r12
    sub     rsp, 16
    mov     rsi, rsp
    sub     rsp, 8
    mov     rdx, rsp
    syscall

    add     rsp, 24

    mov     rdi, rax
    call    handleSocket

    jmp     _accept_loop

; header_data + buf
handleSocket:
    push    r12
    mov     r12, rax
    sub     rsp, 4096 + 16

    ; read(fd, &buf, 4096)
    mov     rax, 0
    mov     rdi, r12
    mov     rsi, rsp
    add     rsi, 16
    mov     rdx, 4096
    syscall

    mov     rdi, rsp
    add     rdi, 16
    mov     rsi, rax
    mov     rdx, rsp
    call    parseHeader

    int3

    ; close(fd)
    mov     rax, 3
    mov     rdi, r12
    syscall

    add     rsp, 4096 + 16
    pop     r12
    ret

; struct header_data {
;   long  method
;   char* path
; }

; rdi - Header string
; rsi - Len header
; rdx - ptr header_data
; return code (1 ok 0 error)
parseHeader:
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rdi
    mov     r13, rsi
    mov     r14, rdx

_parseMethod:
    mov     rdi, r12
    call    readToken
    mov     r15, rax

    mov     rdi, r12
    lea     rsi, method_get
    call    strcmp
    cmp     rax, 1
    jz      _parseMethod_get

    mov     rdi, r12
    lea     rsi, method_post
    call    strcmp
    cmp     rax, 1
    jz      _parseMethod_post

_parseMethod_unhandled:
    mov     rax, 0
    jmp     _parseHeader_end

_parseMethod_get:
    mov     qword [r14], 0
    jmp     _parsePath

_parseMethod_post:
    mov     qword [r14], 1

_parsePath:
    mov     rdi, r15
    call    readToken

    mov     [r14 + 8], r15
    mov     rax, 1

_parseHeader_end:
    pop r15
    pop r14
    pop r13
    pop r12

    ret



; return the address to next token
; null out suffix
readToken:
_readToken_loop:
    mov     rdx, 1
    cmp     byte [rdi], 0x20
    je      _readToken_end

    mov     rdx, 2
    cmp     word [rdi], 0x0a0d
    je      _readToken_end

    mov     rdx, 1
    cmp     byte [rdi], 0x0a
    je      _readToken_end

    inc     rdi
    jmp     _readToken_loop

; rdi pointe vers " " ou "\x0d\x0a"
; set next N bytes to null
; increment rdi by N
_readToken_end:
    mov      rsi, 0
    call     memset     ; rdi is set to rdi + N after memset; Aka opti

    mov      rax, rdi
    ret

