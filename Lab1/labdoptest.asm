data segment
    a db 1
    b db 2
    d db 4
    c db 3
    str db 20 dup (?), '$'  ; буфер для результата
data ends

code segment
start:
    mov ax, data          ; загрузка адреса сегмента данных в AX
    mov ds, ax            ; установка DS на сегмент данных

    ; Вычисление BH как в исходном коде
    mov al, a             ; AL = a
    mov bl, b             ; BL = b
    mov ah, 0             ; обнуление AH для деления
    div bl                ; AL = AL / BL
    mov bh, al            ; BH = результат первого деления

    mov al, d             ; AL = d
    mov bl, c             ; BL = c
    mov ah, 0             ; обнуление AH для деления
    div bl                ; AL = AL / BL
    add bh, al            ; BH += результат второго деления

    sub bh, 1             ; BH -= 1

    ; Перенос BH в AX для преобразования
    mov ax, 0
    mov al, bh

    ; Инициализация SI для указания на конец буфера
    lea si, [str + 19]    ; SI = адрес последнего символа в str

    ; Преобразование AX в десятичную строку
    mov bx, 10            ; делитель для десятичного преобразования

dec_conv_loop:
    mov dx, 0
    div bx                ; AX = AX / 10, DX = остаток
    add dl, '0'           ; преобразование остатка в ASCII
    mov [si], dl          ; сохранение цифры в буфере
    sub si, 1             ; переход к предыдущей позиции
    cmp ax, 0
    jne dec_conv_loop     ; повторить, если AX > 0

    ; Обработка случая, когда AX был нулевым
    cmp dl, '0'
    jne dec_conv_done
    cmp [si + 1], '0'
    jne dec_conv_done
    mov [si], '0'
    sub si, 1

dec_conv_done:
    ; Вставка пробела между десятичным и шестнадцатеричным числами
    mov [si], ' '
    sub si, 1

    ; Перезагрузка BH в AX для шестнадцатеричного преобразования
    mov ax, 0
    mov al, bh

    ; Преобразование AX в шестнадцатеричную строку
    mov bx, 16            ; делитель для шестнадцатеричного преобразования

hex_conv_loop:
    mov dx, 0
    div bx                ; AX = AX / 16, DX = остаток
    cmp dx, 10
    jl hex_digit_num
    add dl, 55            ; преобразование 10-15 в 'A'-'F'
    jmp hex_digit_done
hex_digit_num:
    add dl, '0'           ; преобразование 0-9 в '0'-'9'
hex_digit_done:
    mov [si], dl          ; сохранение цифры в буфере
    sub si, 1             ; переход к предыдущей позиции
    cmp ax, 0
    jne hex_conv_loop     ; повторить, если AX > 0

    ; Обработка случая, когда AX был нулевым
    cmp dl, '0'
    jne hex_conv_done
    cmp [si + 1], '0'
    jne hex_conv_done
    mov [si], '0'
    sub si, 1

hex_conv_done:
    ; Вставка 'h' в конце шестнадцатеричного числа
    mov [si], 'h'
    sub si, 1

    ; Настройка SI на первый символ результата
    add si, 1

    ; Убедиться, что буфер заканчивается на '$'
    mov byte ptr [str + 20], '$'

    ; Вывод строки с результатом
    mov dx, si            ; DX = адрес строки с результатом
    mov ah, 09h           ; функция DOS для отображения строки
    int 21h               ; вызов прерывания DOS

    ; Завершение программы
    mov ah, 4Ch           ; функция DOS для выхода из программы
    int 21h               ; вызов прерывания DOS

code ends
end start
