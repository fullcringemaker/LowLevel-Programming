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

    ; Демонстрация работы макросов

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
    ; Здесь код процедуры
    ret

; Метка для LOOPM
loopEnd:

code ends
end start

; Реализация макросов
PUSHM macro X
    ; Проверка на существование переменной X
    IFDEF X
        ; Сохраняем значение переменной X на стеке
        mov eax, dword ptr X
        push eax
    ELSE
        ; Если переменная X не передана, выводим ошибку или делаем другое действие
        ; Для упрощения примера будем делать пустую операцию
        nop
    ENDIF
endm

POPM macro X
    ; Проверка на существование переменной X
    IFDEF X
        ; Извлекаем значение с вершины стека в переменную X
        pop eax
        mov dword ptr X, eax
    ELSE
        ; Если переменная X не передана, выводим ошибку или делаем другое действие
        nop
    ENDIF
endm

CALLM macro P
    ; Проверка на существование процедуры P
    IFDEF P
        ; Вызываем процедуру P
        call P
    ELSE
        ; Если процедура P не передана, выводим ошибку или делаем другое действие
        nop
    ENDIF
endm

RETM macro N
    ; Проверка на существование константы N
    IFDEF N
        ; Возвращаем управление с указанием числа возврата N
        ret N
    ELSE
        ; Если константа N не передана, выводим ошибку или делаем другое действие
        nop
    ENDIF
endm

LOOPM macro L
    ; Проверка на существование метки L
    IFDEF L
        ; Переходим по метке L
        jmp L
    ELSE
        ; Если метка L не передана, выводим ошибку или делаем другое действие
        nop
    ENDIF
endm
