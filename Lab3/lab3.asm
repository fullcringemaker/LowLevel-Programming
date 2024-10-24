assume CS:code, DS:data

data segment
    ; Буферы для ввода строк
    buf_size equ 256
    str_input1 db buf_size dup(0)
    str_input2 db buf_size dup(0)
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

    ; Подготовка буфера для первой строки
    mov byte ptr [str_input1], buf_size - 2 ; Максимальная длина ввода
    lea dx, str_input1
    mov ah, 0Ah
    int 21h

    ; Добавление символа конца строки '$' в первую строку
    lea si, [str_input1 + 2]
    mov cl, [str_input1 + 1]    ; Фактическая длина введенной строки
    mov [si + cx], '$'          ; Добавляем '$' в конец строки

    ; Подготовка буфера для второй строки
    mov byte ptr [str_input2], buf_size - 2 ; Максимальная длина ввода
    lea dx, str_input2
    mov ah, 0Ah
    int 21h

    ; Добавление символа конца строки '$' во вторую строку
    lea si, [str_input2 + 2]
    mov cl, [str_input2 + 1]
    mov [si + cx], '$'

    ; Подготовка аргументов для функции strpbrk
    lea ax, [str_input2 + 2]    ; Адрес начала второй строки
    push ax
    lea ax, [str_input1 + 2]    ; Адрес начала первой строки
    push ax

    ; Вызов функции strpbrk
    call strpbrk

    ; Очистка стека после вызова функции
    add sp, 4

    ; Проверка возвращенного значения
    cmp ax, 0
    je output_null

    ; Вычисление позиции найденного символа
    lea bx, [str_input1 + 2]
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

    ; Получение фактической длины строк
    mov cl, [si - 2]   ; Длина str
    mov ch, 0
    mov bx, cx         ; BX = длина str

    mov dl, [di - 2]   ; Длина sym
    mov dh, 0
    mov dx, dx         ; DX = длина sym

    ; Внешний цикл по str
    xor ax, ax         ; AX будет использоваться для сравнения
str_loop:
    cmp bx, 0
    je not_found

    mov al, [si]
    push si
    push bx

    ; Внутренний цикл по sym
    mov cx, dx         ; CX = длина sym
    mov di, [bp+6]     ; DI = указатель на sym
sym_loop:
    cmp cx, 0
    je sym_end
    mov ah, [di]
    cmp al, ah
    je found_char
    inc di
    dec cx
    jmp sym_loop

sym_end:
    pop bx
    pop si
    inc si
    dec bx
    jmp str_loop

found_char:
    pop bx
    pop si
    mov ax, si         ; Возвращаем адрес найденного символа
    jmp strpbrk_end

not_found:
    mov ax, 0          ; Возвращаем NULL

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
