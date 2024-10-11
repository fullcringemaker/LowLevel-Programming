assume cs:code, ds:data
data segment
    a dw 17
    b dw 2
    c dw 4
    d dw 32
    result dw 0
    buffer db 6 dup(0)
    hex_buffer db 5 dup(0)
    space db ' ', '$'
data ends

code segment
start:
    mov ax, data
    mov ds, ax
    
    mov ax, [a]
    mov dx, 0
    mov bx, [b]
    div bx
    mov bx, ax

    mov ax, [d]
    mov dx, 0
    mov cx, [c]
    div cx

    add ax, bx
    sub ax, 1
    mov [result], ax
    
    mov si, offset buffer
    add si, 5
    mov bx, si
    mov cx, 0
    mov ax, [result]
    cmp ax, 0
    jne dec_convert_loop
    mov byte ptr [bx], '0'
    mov byte ptr [bx+1], '$'
    mov dx, bx
    mov ah, 09h
    int 21h
    jmp space_output

dec_convert_loop:
    mov dx, 0
    mov si, 10
    div si
    add dl, '0'
    mov [bx], dl
    dec bx
    inc cx
    cmp ax, 0
    jne dec_convert_loop
    inc bx
    mov si, cx
    add si, bx
    mov byte ptr [si], '$'
    mov dx, bx
    mov ah, 09h
    int 21h

space_output:
    mov dx, offset space
    mov ah, 09h
    int 21h
    jmp hex_output

hex_output:
    mov si, offset hex_buffer
    add si, 4
    mov bx, si
    mov cx, 0
    mov ax, [result]
    cmp ax, 0
    jne hex_convert_loop
    mov byte ptr [bx], '0'
    mov byte ptr [bx+1], '$'
    mov dx, bx
    mov ah, 09h
    int 21h
    jmp exit_program

hex_convert_loop:
    mov dx, 0
    mov si, 16
    div si
    cmp dl, 9
    jle hex_digit
    add dl, 7
hex_digit:
    add dl, '0'
    mov [bx], dl
    dec bx
    inc cx
    cmp ax, 0
    jne hex_convert_loop
    inc bx
    mov si, cx
    add si, bx
    mov byte ptr [si], '$'
    mov dx, bx
    mov ah, 09h
    int 21h

exit_program:
    mov ah, 4Ch
    int 21h

code ends
end start
