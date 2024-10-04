assume CS:code, DS:data
data segment
    a db 15                ; a = 1
    b db 2                ; b = 2
    d db 25               ; d = 4
    c db 4             ; c = 3
    str db '000 00h','$'   ; строка для вывода результата
data ends

code segment
start:
    mov AX, data          ; загрузка адреса сегмента данных в AX
    mov DS, AX            ; установка сегмента данных DS

    mov al, a             ; загрузка значения a в AL (AL = 1)
    mov bl, b             ; загрузка значения b в BL (BL = 2)
    mov ah, 0             ; обнуление AH
    div bl                ; деление AX (0001) на BL (2): AL = 0, AH = 1
    mov bh, al            ; сохранение результата деления (0) в BH

    mov al, d             ; загрузка значения d в AL (AL = 4)
    mov bl, c             ; загрузка значения c в BL (BL = 3)
    mov ah, 0             ; обнуление AH
    div bl                ; деление AX (0004) на BL (3): AL = 1, AH = 1
    add bh, al            ; BH = BH + AL = 0 + 1 = 1

    sub bh, 1             ; вычитание 1 из BH (BH = 1 - 1 = 0)

    ; Преобразование BH в десятичный формат
    mov ax, 0             ; обнуление AX
    mov al, bh            ; загрузка BH в AL
    mov ah, 0             ; обнуление AH для корректного деления
    mov bl, 100           ; установка делителя 100 для сотен
    div bl                ; деление AX на 100: AL = сотни, AH = остаток
    add al, '0'           ; преобразование сотен в ASCII
    mov [str], al         ; сохранение сотен в str[0]

    mov al, ah            ; загрузка остатка после деления на 100
    mov ah, 0             ; обнуление AH для следующего деления
    mov bl, 10            ; установка делителя 10 для десятков
    div bl                ; деление AX на 10: AL = десятки, AH = единицы
    add al, '0'           ; преобразование десятков в ASCII
    mov [str+1], al       ; сохранение десятков в str[1]

    mov al, ah            ; загрузка остатка после деления на 10
    add al, '0'           ; преобразование единиц в ASCII
    mov [str+2], al       ; сохранение единиц в str[2]

    ; Преобразование BH в шестнадцатеричный формат
    mov al, bh            ; загрузка BH в AL
    mov ah, 0             ; обнуление AH для корректного деления
    mov bl, 16            ; установка делителя 16 для разрядов
    div bl                ; деление AX на 16: AL = старший разряд, AH = младший разряд

    ; Преобразование старшего разряда в ASCII
    cmp al, 10            ; проверка, >= ли AL 10
    jb hex_high_is_num    ; если меньше 10, перейти к числовому преобразованию
    add al, 55            ; преобразование 10-15 в 'A'-'F'
    jmp hex_high_done     ; переход к завершению преобразования
hex_high_is_num:
    add al, '0'           ; преобразование 0-9 в '0'-'9'
hex_high_done:
    mov [str+4], al       ; сохранение старшего разряда в str[4]

    ; Преобразование младшего разряда в ASCII
    mov al, ah            ; загрузка младшего разряда в AL
    cmp al, 10            ; проверка, >= ли AL 10
    jb hex_low_is_num     ; если меньше 10, перейти к числовому преобразованию
    add al, 55            ; преобразование 10-15 в 'A'-'F'
    jmp hex_low_done      ; переход к завершению преобразования
hex_low_is_num:
    add al, '0'           ; преобразование 0-9 в '0'-'9'
hex_low_done:
    mov [str+5], al       ; сохранение младшего разряда в str[5]

    ; Символ 'h' уже установлен в str[6]

    ; Вывод строки на экран
    lea dx, str           ; загрузка адреса строки в DX
    mov ah, 09h           ; функция DOS для вывода строки
    int 21h               ; вызов прерывания для вывода

    ; Завершение программы
    mov AH, 4Ch           ; функция DOS для завершения программы
    int 21h               ; вызов прерывания для завершения
code ends
end start
