assume CS:code, DS:data

data segment
    msg db "Hello, world!$"
    var1 dd 12345678h ; Пример переменной двойного слова для макросов PUSHM и POPM
    var2 dd 87654321h ; Пример переменной двойного слова для макросов PUSHM и POPM
data ends

code segment
start:
    ; Устанавливаем сегмент данных
    mov AX, data
    mov DS, AX

    ; Пример использования PUSHM
    PUSHM var1

    ; Пример использования CALLM (вызов процедуры)
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
    ; Сохраняем значение переменной X на стеке
    mov ax, word ptr X
    push ax
    mov ax, word ptr X+2
    push ax
endm

POPM macro X
    ; Извлекаем значение с вершины стека в переменную X
    pop ax
    mov word ptr X, ax
    pop ax
    mov word ptr X+2, ax
endm

CALLM macro P
    ; Вызываем процедуру P
    call P
endm

RETM macro N
    ; Возвращаем управление из процедуры с числом N
    ret N
endm

LOOPM macro L
    ; Переходим по метке L
    jmp L
endm
