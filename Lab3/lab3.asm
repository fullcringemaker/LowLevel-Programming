assume CS:code, DS:data

data segment
    ; Буферы для ввода строк
    str_input1 db 255, 0, 255 dup(0) ; Первый байт - максимальная длина (255)
    buffer_gap db 10 dup(0)          ; Промежуток между буферами
    str_input2 db 255, 0, 255 dup(0)

    ten dw 10

    ; Сообщения для вывода
    msg_null db 'null$', 0
    msg_pos db 'Position: $', 0
    num_buf db 6 dup(0), '$', 0  ; Буфер для хранения позиции в виде строки
data ends

code segment
start:
    mov ax, data
    mov ds, ax

    ; Ввод первой строки
    lea dx, str_input1
    mov ah, 0Ah
    int 21h

    ; Добавление символа конца строки '$' в первую строку
    mov si, offset str_input1 + 2
    mov cl, [str_input1 + 1]    ; Фактическая длина введенной строки
    add si, cx
    mov byte ptr [si], '$'

    ; Ввод второй строки
    lea dx, str_input2
    mov ah, 0Ah
    int 21h

    ; Добавление символа конца строки '$' во вторую строку
    mov si, offset str_input2 + 2
    mov cl, [str_input2 + 1]
    add si, cx
    mov byte ptr [si], '$'

    ; Подготовка аргументов для функции strpbrk
    lea ax, str_input2 + 2      ; Адрес начала второй строки
    push ax
    lea ax, str_input1 + 2      ; Адрес начала первой строки
    push ax

    ; Вызов функции strpbrk
    call strpbrk

    ; Очистка стека после вызова функции
    add sp, 4

    ; Проверка возвращенного значения
    cmp ax, 0
    je output_null

    ; Вычисление позиции найденного символа
    lea bx, str_input1 + 2
    sub ax, bx  ; AX = смещение найденного символа
    inc ax      ; Позиция начинается с 1
    mov bx, ax  ; Сохранение позиции в BX

    ; Вывод 'Position: '
    mov ah, 9
    lea dx, msg_pos
    int 21h

    ; Вывод позиции
    call print_number

    ; Переход к завершению программы
    jmp exit_program

output_null:
    ; Вывод 'null'
    mov ah, 9
    lea dx, msg_null
    int 21h

exit_program:
    ; Завершение программы
    mov ah, 4Ch
    int 21h

; Подпрограмма для вывода числа в BX
print_number proc
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, offset num_buf + 5  ; Указатель на конец буфера
    mov byte ptr [si], '$'      ; Добавление символа конца строки
    dec si

    mov cx, 0  ; Счетчик цифр

convert_loop:
    xor dx, dx
    mov ax, bx
    div word ptr [ten]  ; Деление на 10
    add dl, '0'         ; Преобразование остатка в ASCII
    mov [si], dl
    dec si
    inc cx
    mov bx, ax
    cmp bx, 0
    jne convert_loop

    inc si  ; Указатель на первый символ числа

    ; Вывод числа
    mov ah, 9
    mov dx, si
    int 21h

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number endp

; Реализация функции strpbrk
strpbrk proc
    push bp
    mov bp, sp
    push si
    push di
    push bx
    push cx
    push dx

    mov si, [bp+4]  ; SI = указатель на str
    mov di, [bp+6]  ; DI = указатель на sym

    ; Внешний цикл по str
str_loop:
    lodsb          ; AL = текущий символ из str, SI увеличивается
    cmp al, '$'
    je not_found   ; Дошли до конца строки

    push si        ; Сохраняем SI

    ; Внутренний цикл по sym
    mov di, [bp+6] ; Восстанавливаем DI
sym_loop:
    mov bl, [di]
    cmp bl, '$'
    je end_sym_loop
    cmp al, bl
    je found_char
    inc di
    jmp sym_loop

end_sym_loop:
    pop si         ; Восстанавливаем SI
    jmp str_loop

found_char:
    pop si         ; Восстанавливаем SI
    dec si         ; Корректируем SI после LODSB
    mov ax, si     ; Возвращаем адрес найденного символа
    jmp strpbrk_end

not_found:
    mov ax, 0      ; Возвращаем NULL

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
