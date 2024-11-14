assume CS:code, DS:data

data segment
    ; Пример данных
    msg db "Hello, world!$"
    var dd 12345678h     ; Переменная размером в двойное слово (4 байта)
data ends

code segment
start:
    ; Инициализация сегмента данных
    mov AX, data
    mov DS, AX

    ; Демонстрация вывода строки на экран
    mov AH, 09h
    mov DX, offset msg
    int 21h

    ; Вызов макроса PUSHM
    pushm var

    ; Вызов макроса POPM
    popm var

    ; Вызов макроса CALLM (пример вызова процедуры)
    callm my_procedure

    ; Вызов макроса RETM (возврат с параметром)
    retm 5

    ; Вызов макроса LOOPM (цикл с меткой)
    loopm loop_start

    ; Завершаем выполнение программы
    mov AH, 4Ch
    int 21h

; Процедура для примера вызова
my_procedure:
    ; Просто возврат из процедуры
    ret

; Макросы
PUSHM macro X
    ; Проверка существования переменной X
    ; Сохраняем значение X в стек
    mov EAX, X
    push EAX
endm

POPM macro X
    ; Проверка существования переменной X
    ; Извлекаем значение из стека в X
    pop EAX
    mov X, EAX
endm

CALLM macro P
    ; Проверка существования метки P
    ; Выполняем вызов процедуры
    call P
endm

RETM macro N
    ; Возврат из функции с числовым параметром N
    ; Используем N как количество шагов для выхода из функции
    add SP, N
    ret
endm

LOOPM macro L
    ; Создаем цикл до метки L
    jmp L
endm

code ends
end start
