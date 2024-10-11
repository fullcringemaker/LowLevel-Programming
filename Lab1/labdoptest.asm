data segment
    a dw 1
    b dw 2
    d dw 4
    c dw 3
    str db '000 00h','$'  ; Буфер для вывода
data ends

code segment
start:
    mov ax, data
    mov ds, ax

    ; Вычисление (a / b) + (d / c) - 1
    mov ax, [a]
    mov dx, 0              ; Зануление DX вместо использования CWD
    div word ptr [b]       ; AX = AX / [b], DX = AX mod [b]
    mov bx, ax             ; BX = результат первого деления

    mov ax, [d]
    mov dx, 0
    div word ptr [c]
    add bx, ax             ; BX += результат второго деления

    sub bx, 1              ; BX -= 1

    ; Конвертация BX в десятичный формат и запись в str[0..2]
    mov ax, bx
    mov cx, 3              ; Количество цифр для вывода
    lea si, [str + 2]      ; Указатель на позицию для записи цифр

dec_conv_loop:
    mov dx, 0              ; Зануление DX вместо XOR
    mov bx, 10
    div bx                 ; AX = AX / 10, DX = остаток
    add dl, '0'            ; Преобразование в ASCII
    mov [si], dl
    dec si
    dec cx
    jnz dec_conv_loop

    ; Конвертация BX в шестнадцатеричный формат и запись в str[4..5]
    mov ax, bx
    mov cx, 2
    lea si, [str + 5]

hex_conv_loop:
    mov dx, 0
    mov bx, 16
    div bx                 ; AX = AX / 16, DX = остаток
    mov al, dl             ; AL = остаток для обработки
    cmp al, 10
    jl hex_digit_is_num
    add al, 'A' - 10
    jmp hex_store_digit
hex_digit_is_num:
    add al, '0'
hex_store_digit:
    mov [si], al
    dec si
    dec cx
    jnz hex_conv_loop

    ; Вывод строки
    lea dx, str
    mov ah, 09h
    int 21h

    mov ah, 4Ch
    int 21h
code ends
end start
