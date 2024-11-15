assume CS:code, DS:data

PUSHM macro X
    push word ptr X+2
    push word ptr X
endm

POPM macro X
    pop word ptr X
    pop word ptr X+2
endm

CALLM macro P
    push AX              ; Сохраняем AX
    push offset after_callm@
    jmp P
    after_callm@:
    pop AX               ; Восстанавливаем AX
endm

RETM macro N
    add SP, N
    pop AX
    jmp AX
endm

LOOPM macro L
    push CX              ; Сохраняем CX
    dec CX
    jnz L
    pop CX               ; Восстанавливаем CX
endm

data segment
    msg    db "Hello, world!$"
    var    dw 5678h
           dw 1234h
    count  dw 5
data ends

code segment
start:
    mov AX, data
    mov DS, AX

    mov AH, 09h
    mov DX, offset msg
    int 21h

    PUSHM var

    mov word ptr var, 0ABCDh
    mov word ptr var+2, 0EF01h

    POPM var

    CALLM my_procedure

    mov CX, count

loop_start:
    mov AH, 02h
    mov DL, 'A'
    int 21h

    LOOPM loop_start

    mov AH, 4Ch
    int 21h

my_procedure:
    mov AH, 02h
    mov DL, 'P'
    int 21h
    RETM 0
code ends

end start
