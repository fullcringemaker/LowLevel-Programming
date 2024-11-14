assume CS:code, DS:data

data segment
    msg db "Hello, world!$"
    ; Определяем переменную X размером двойное слово
    X dd 12345678h
data ends

code segment
    ; Определение макросов

PUSHM MACRO X
    IFDEF X
        IF (TYPE X) EQ 4
            PUSH WORD PTR [X+2] ; Сохранение старшего слова
            PUSH WORD PTR [X]   ; Сохранение младшего слова
        ELSE
            .ERR <Переменная X не является двойным словом>
        ENDIF
    ELSE
        .ERR <Переменная X не определена>
    ENDIF
ENDM

POPM MACRO X
    IFDEF X
        IF (TYPE X) EQ 4
            POP WORD PTR [X]     ; Восстановление младшего слова
            POP WORD PTR [X+2]   ; Восстановление старшего слова
        ELSE
            .ERR <Переменная X не является двойным словом>
        ENDIF
    ELSE
        .ERR <Переменная X не определена>
    ENDIF
ENDM

CALLM MACRO P
    IFDEF P
        ; Используем EAX как вспомогательный регистр
        PUSH EAX
        MOV EAX, OFFSET $$NEXT
        PUSH EAX
        JMP P
$$NEXT:
        POP EAX
    ELSE
        .ERR <Процедура P не определена>
    ENDIF
ENDM

RETM MACRO N
    IF CONST N
        ADD SP, N
    ENDIF
    RET
ENDM

LOOPM MACRO L
    IFDEF L
        DEC CX
        JNZ L
    ELSE
        .ERR <Метка L не определена>
    ENDIF
ENDM

start:
    mov AX, data
    mov DS, AX

    mov AH, 09h
    mov DX, OFFSET msg
    int 21h

    ; Использование макросов PUSHM и POPM
    PUSHM X
    ; ... выполнение каких-либо операций ...
    POPM X

    ; Использование макросов CALLM и RETM
    CALLM myProc

    mov AH, 4Ch
    int 21h

; Определение процедуры myProc
myProc PROC
    ; Пример использования макроса LOOPM
    mov CX, 5
printLoop:
    mov AH, 09h
    mov DX, OFFSET msg
    int 21h
    LOOPM printLoop

    ; Возврат из процедуры без корректировки SP
    RETM 0
myProc ENDP

code ends
end start
