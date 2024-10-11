data segment
    a db 1                 ; a = 1
    b db 2                 ; b = 2
    d db 4                 ; d = 4
    c db 3                 ; c = 3
    str db 5 dup ('?'), ' ', 4 dup ('?'), 'h', '$'  ; Место для результата
data ends

code segment
start:
    mov ax, data           ; Загрузка адреса сегмента данных в AX
    mov ds, ax             ; Установка DS на сегмент данных

    ; Вычисление результата и сохранение в CX
    mov al, a              ; AL = a
    mov bl, b              ; BL = b
    mov ah, 0              ; Обнуление AH для деления
    div bl                 ; AX = AX / BL, AL = частное, AH = остаток
    mov cx, ax             ; CX = частное от первого деления

    mov al, d              ; AL = d
    mov bl, c              ; BL = c
    mov ah, 0              ; Обнуление AH для деления
    div bl                 ; AX = AX / BL
    add cx, ax             ; CX = CX + частное от второго деления
    sub cx, 1              ; CX = CX - 1

    ; Преобразование CX в десятичный формат и сохранение в str[0..4]
    mov si, offset str + 4 ; SI указывает на последнюю десятичную цифру в str
    mov ax, cx             ; Перенос результата в AX
    cmp ax, 0
    jne dec_convert_start
    ; Обработка случая нуля
    mov byte ptr [si], '0'
    sub si, 1
    jmp dec_fill_zero

dec_convert_start:
dec_convert_loop:
    mov dx, 0              ; Обнуление DX для деления
    mov bx, 10             ; Делитель 10
    div bx                 ; AX = AX / 10, DX = остаток
    add dl, '0'            ; Преобразование цифры в ASCII
    mov [si], dl           ; Сохранение цифры в str
    sub si, 1              ; Уменьшение SI
    cmp ax, 0
    jne dec_convert_loop

dec_fill_zero:
    cmp si, offset str
    jl dec_conversion_done
    mov byte ptr [si], '0' ; Заполнение ведущих нулей
    sub si, 1
    jmp dec_fill_zero

dec_conversion_done:

    ; Преобразование CX в шестнадцатеричный формат и сохранение в str[6..9]
    mov si, offset str + 9 ; SI указывает на последнюю шестнадцатеричную цифру в str
    mov ax, cx             ; Перенос результата в AX
    cmp ax, 0
    jne hex_convert_start
    ; Обработка случая нуля
    mov byte ptr [si], '0'
    sub si, 1
    jmp hex_fill_zero

hex_convert_start:
hex_convert_loop:
    mov dx, 0              ; Обнуление DX для деления
    mov bx, 16             ; Делитель 16
    div bx                 ; AX = AX / 16, DX = остаток
    cmp dl, 9
    jg hex_alpha
    add dl, '0'            ; Преобразование 0-9 в ASCII
    jmp hex_store_digit
hex_alpha:
    add dl, 'A' - 10       ; Преобразование 10-15 в 'A'-'F'
hex_store_digit:
    mov [si], dl           ; Сохранение цифры в str
    sub si, 1              ; Уменьшение SI
    cmp ax, 0
    jne hex_convert_loop

hex_fill_zero:
    cmp si, offset str + 6
    jl hex_conversion_done
    mov byte ptr [si], '0' ; Заполнение ведущих нулей
    sub si, 1
    jmp hex_fill_zero

hex_conversion_done:

    ; Пробел и 'h' уже находятся на своих местах в str
    ; Вывод результата
    mov dx, offset str
    mov ah, 09h            ; Функция DOS для вывода строки
    int 21h                ; Вызов DOS-прерывания

    ; Завершение программы
    mov ah, 4Ch            ; Функция DOS для завершения программы
    int 21h                ; Вызов DOS-прерывания
code ends
end start
