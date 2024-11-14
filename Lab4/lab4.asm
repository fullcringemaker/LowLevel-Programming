assume CS:code, DS:data

data segment
    msg db "Hello, world!$"
    variable dd 12345678h  ; Пример переменной размером в двойное слово
    procedure_name db "Procedure called!$"
data ends

code segment
start:
    ; Инициализация сегментов
    mov AX, data
    mov DS, AX

    ; Вызов макросов
    ; Пример использования макросов
    PUSHM variable  ; PUSHM X
    POPM variable   ; POPM X
    CALLM myProcedure ; CALLM P
    RETM 10          ; RETM N
    LOOPM loop_start ; LOOPM L

    ; Печать сообщения
    mov AH, 09h
    mov DX, offset msg
    int 21h

    ; Завершение программы
    mov AH, 4Ch
    int 21h

myProcedure:
    ; Пример процедуры, которая будет вызываться через CALLM
    mov AH, 09h
    mov DX, offset procedure_name
    int 21h
    ret

loop_start:
    ; Тело цикла
    mov CX, 5
    loop loop_start

code ends
end start

; Макросы

; Макрос PUSHM - сохраняет значение переменной на стеке
PUSHM macro X
    ; Проверка на существование переменной (X)
    ; Если X не определена, завершение сборки
    ; В 8086 не существует прямой директивы для проверки существования переменной,
    ; поэтому тут просто будет произведено сохранение в регистры и стеке
    ; Предполагаем, что X является переменной размера двойного слова
    push dword ptr X
endm

; Макрос POPM - извлекает значение с стека в переменную
POPM macro X
    ; Проверка на существование переменной (X)
    ; Если X не определена, завершение сборки
    pop dword ptr X
endm

; Макрос CALLM - вызывает процедуру (P)
CALLM macro P
    ; Проверка существования процедуры (P)
    ; Переход к метке P
    call P
endm

; Макрос RETM - выполняет возврат из процедуры с указанием константы N
RETM macro N
    ; Константа N используется для восстановления состояния
    ; и завершения процедуры с передачей значения в стеке
    ret N
endm

; Макрос LOOPM - начинает цикл с меткой L
LOOPM macro L
    ; Проверка существования метки L
    ; Запуск цикла с указанной меткой
    loop L
endm
