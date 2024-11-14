
assume CS:code, DS:data

data segment
    msg db "Hello, world!$"
    var1 dd 12345678h   ; Double-word variable
    var2 dd 0           ; Double-word variable to receive data
data ends

PUSHM MACRO X
    IFDEF X
        IF TYPE X EQ 4
            MOV EAX, X      ; Move double-word variable into EAX
            PUSH EAX        ; Push EAX onto the stack
        ELSE
            .ERR <Variable X is not a double-word (32-bit) variable>
        ENDIF
    ELSE
        .ERR <Variable X is not defined>
    ENDIF
ENDM

POPM MACRO X
    IFDEF X
        IF TYPE X EQ 4
            POP EAX         ; Pop value from stack into EAX
            MOV X, EAX      ; Move value from EAX into variable X
        ELSE
            .ERR <Variable X is not a double-word (32-bit) variable>
        ENDIF
    ELSE
        .ERR <Variable X is not defined>
    ENDIF
ENDM

CALLM MACRO P
    IFDEF P
        CALL P              ; Call procedure P
    ELSE
        .ERR <Procedure P is not defined>
    ENDIF
ENDM

RETM MACRO N
    IFCONST N
        RET N               ; Return and clean up N bytes from the stack
    ELSE
        .ERR <N must be a constant>
    ENDIF
ENDM

LOOPM MACRO L
    IFDEF L
        DEC EBX             ; Decrement EBX (loop counter)
        JNZ L               ; Jump to label L if EBX is not zero
    ELSE
        .ERR <Label L is not defined>
    ENDIF
ENDM

code segment
start:
    mov AX, data
    mov DS, AX

    ; Demonstrate PUSHM and POPM
    MOV EAX, 12345678h
    MOV var1, EAX

    PUSHM var1      ; Push var1 onto the stack

    ; Modify var1
    MOV var1, 0

    POPM var2       ; Pop value from stack into var2

    ; Demonstrate LOOPM
    MOV EBX, 5      ; Initialize loop counter to 5
    MOV ECX, 0      ; Initialize ECX to zero

loop_start:
    INC ECX         ; Increment ECX
    LOOPM loop_start

    ; Use DOS interrupt to print message
    mov AH, 09h
    mov DX, offset msg
    int 21h

    mov AH, 4Ch     ; Exit to DOS
    int 21h
code ends
end start
