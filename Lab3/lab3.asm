assume CS:code, DS:data

data segment
    str_input1 db 20, 0, 20 dup(0) 
    str_input2 db 20, 0, 20 dup(0)

    ten dw 10

    msg_null db 'null$', 0
    msg_pos db 'Position: $', 0
    num_buf db 5 dup(0), '$', 0  

    newline db 13, 10, '$'
data ends

code segment
start:
    mov ax, data
    mov ds, ax

    mov ah, 09h
    lea dx, newline
    int 21h

    lea dx, str_input1
    mov ah, 0Ah
    int 21h

    mov ah, 09h
    lea dx, newline
    int 21h

    lea dx, str_input2
    mov ah, 0Ah
    int 21h

    mov ah, 09h
    lea dx, newline
    int 21h

    lea ax, str_input2 + 2  
    push ax
    lea ax, str_input1 + 2  
    push ax

    call strpbrk

    add sp, 4

    cmp ax, 0
    je output_null

    lea bx, str_input1 + 2
    sub ax, bx  
    inc ax      
    mov bx, ax  

    mov ah, 09h
    lea dx, msg_pos
    int 21h

    call print_number

    mov ah, 09h
    lea dx, newline
    int 21h

    jmp exit_program

output_null:
    mov ah, 09h
    lea dx, msg_null
    int 21h

    mov ah, 09h
    lea dx, newline
    int 21h

exit_program:
    mov ah, 4Ch
    int 21h

print_number proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, offset num_buf + 5  
    mov byte ptr [si], '$'      
    dec si

    mov cx, 0  

convert_loop:
    xor dx, dx
    mov ax, bx
    div word ptr [ten]  
    add dl, '0'         
    mov [si], dl
    dec si
    inc cx
    mov bx, ax
    cmp bx, 0
    jne convert_loop

    inc si  

    mov ah, 09h
    mov dx, si
    int 21h

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp

strpbrk proc
    push bp
    mov bp, sp
    push si
    push di
    push bx
    push cx
    push dx

    mov si, [bp+4]  
    mov di, [bp+6]  

    mov cl, [si - 1]  
    mov ch, 0
    mov bx, cx        
    mov dl, [di - 1]  
    mov dh, 0

str_loop:
    cmp bx, 0
    je not_found

    mov al, [si]  

    push si
    push bx

    mov cx, dx    
    mov di, [bp+6]

sym_loop:
    cmp cx, 0
    je next_char
    mov ah, [di]
    cmp al, ah
    je found_char
    inc di
    dec cx
    jmp sym_loop

next_char:
    pop bx
    pop si
    inc si
    dec bx
    jmp str_loop

found_char:
    pop bx
    pop si
    mov ax, si    
    jmp strpbrk_end

not_found:
    mov ax, 0     

strpbrk_end:
    pop dx
    pop cx
    pop bx
    pop di
    pop si
    pop bp
    ret 4
strpbrk endp

code ends
end start
