; Лабораторная работа №4 (использование макросредств)
; Условие задания:
; Реализовать макросы PUSHM, POPM, CALLM, RETM, LOOPM
; с учётом проверки корректности данных и сохранения регистров.

; Синтаксис кода повторяет следующий пример:
; assume CS:code, DS:data
; data segment
;     msg db "Hello, world!$"
; data ends
; code segment
; start:
;     mov AX, data
;     mov DS, AX
;     mov AH, 09h
;     mov DX, offset msg
;     int 21h
;     mov AH, 4Ch
;     int 21h
; code ends
; end start

; Определение макросов
; Макрос PUSHM X - пушит двойное слово X на стек
PUSHM macro X
    ; Проверка существования переменной X производится на этапе компиляции
    ; Предполагается, что X занимает два слова (4 байта)
    push word ptr X+2    ; Пушим старшее слово
    push word ptr X      ; Пушим младшее слово
endm

; Макрос POPM X - выталкивает двойное слово из стека в X
POPM macro X
    ; Проверка существования переменной X производится на этапе компиляции
    pop word ptr X        ; Выталкиваем младшее слово
    pop word ptr X+2      ; Выталкиваем старшее слово
endm

; Макрос CALLM P - вызывает процедуру P
CALLM macro P
    ; Проверка существования метки P производится на этапе компиляции
    call P
endm

; Макрос RETM N - возвращается из процедуры, удаляя N байт из стека
RETM macro N
    add SP, N
    ret
endm

; Макрос LOOPM L - выполняет цикл к метке L, используя CX как счетчик
LOOPM macro L
    loop L
endm

; Определение сегментов
assume CS:code, DS:data

data segment
    msg    db "Hello, world!$"   ; Сообщение для вывода
    var    dw 5678h               ; Первое слово двойного слова
           dw 1234h               ; Второе слово двойного слова
    count  dw 5                   ; Счетчик для цикла
data ends

code segment
start:
    ; Инициализация сегмента данных
    mov AX, data
    mov DS, AX

    ; Вывод строки на экран
    mov AH, 09h
    mov DX, offset msg
    int 21h

    ; Демонстрация использования макроса PUSHM
    pushm var

    ; Изменение значения переменной var
    mov word ptr var, 0ABCDh       ; Изменяем младшее слово
    mov word ptr var+2, 0EF01h     ; Изменяем старшее слово

    ; Демонстрация использования макроса POPM для восстановления var
    popm var

    ; Демонстрация использования макроса CALLM
    CALLM my_procedure

    ; Демонстрация использования макроса LOOPM
    mov CX, count                  ; Устанавливаем счетчик цикла
loop_start:
    ; Пример кода внутри цикла: вывод символа 'A'
    mov AH, 02h                    ; Функция вывода символа
    mov DL, 'A'                    ; Символ для вывода
    int 21h

    ; Вызов макроса LOOPM для перехода к loop_start
    LOOPM loop_start

    ; Завершение программы
    mov AH, 4Ch
    int 21h

; Процедура для примера вызова
my_procedure:
    ; Пример кода процедуры: вывод символа 'P'
    mov AH, 02h                    ; Функция вывода символа
    mov DL, 'P'                    ; Символ для вывода
    int 21h

    ; Возврат из процедуры с очисткой стека (если необходимо)
    retm 0
code ends

end start
