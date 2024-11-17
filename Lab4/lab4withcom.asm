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
    LOCAL after_callm
    push offset after_callm
    jmp P
    after_callm:
endm

RETM macro N
    pop AX
    add SP, N
    jmp AX
endm

LOOPM macro L
    dec CX
    jnz L
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

Для каждой строчки данного кода напиши пояснение с объяснением работы и объяснением происходящего в данной строчке в контексте самого задания

Вот задание:
Лабораторная работа №4 (использование макросредств)

Во всех задачах, где это применимо, макросы, блоки повторений и
директивы условного ассемблирования должны самостоятельно определять
корректность введённых данных, в том числе проверяя существование
переданных в качестве фактических параметров переменных, а также не
портить значения ни в каких регистрах, если не указано обратное.


Описать в виде макросов указанные команды, предполагая, что таких
команд в ассемблере нет (PUSH и POP использовать можно, т.к. их
разновидности в 8086 работают только с операндами размером в
слово; также в качестве вспомогательных можно использовать
регистры EAX и EBX):
а) PUSHM X (X — переменная размером в двойное слово);
б) POPM X (X — переменная размером в двойное слово);
в) CALLM P (P — имя процедуры);
г) RETM N (N — константа);
д) LOOPM L (L — метка).
