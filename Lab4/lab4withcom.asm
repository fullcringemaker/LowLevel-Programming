assume CS:code, DS:data

data segment
    msg db "Hello, world!$"
    var1 dd 12345678h  ; Пример переменной для PUSHM/POPM
    var2 dd 87654321h  ; Пример переменной для PUSHM/POPM
data ends

code segment
start:
    ; Устанавливаем сегмент данных
    mov AX, data
    mov DS, AX

    ; Пример использования PUSHM
    PUSHM var1

    ; Пример использования CALLM
    CALLM testProc

    ; Пример использования POPM
    POPM var2

    ; Пример использования RETM
    RETM 10
    
    ; Пример использования LOOPM
    LOOPM loopEnd

    ; Выводим строку на экран
    mov AH, 09h
    mov DX, offset msg
    int 21h

    ; Завершаем программу
    mov AH, 4Ch
    int 21h

; Пример процедуры для CALLM
testProc:
    ; Код процедуры
    ret

; Метка для LOOPM
loopEnd:

code ends
end start

; Реализация макросов

PUSHM macro X
    ; Сохраняем значение переменной X на стеке (для двойного слова)
    mov ax, word ptr X        ; Загружаем младшее слово в AX
    push ax                   ; Сохраняем в стеке
    mov ax, word ptr X+2      ; Загружаем старшее слово в AX
    push ax                   ; Сохраняем в стеке
endm

POPM macro X
    ; Извлекаем значение с вершины стека в переменную X (для двойного слова)
    pop ax                    ; Извлекаем из стека в AX
    mov word ptr X, ax        ; Сохраняем в младшее слово X
    pop ax                    ; Извлекаем следующее слово в AX
    mov word ptr X+2, ax      ; Сохраняем в старшее слово X
endm

CALLM macro P
    ; Вызов процедуры P
    call P
endm

RETM macro N
    ; Возврат из процедуры с числом N
    ret N
endm

LOOPM macro L
    ; Переход к метке L
    jmp L
endm
