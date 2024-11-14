PUSHM macro X
    push word ptr X+2    
    push word ptr X     
endm

POPM macro X
    pop word ptr X        
    pop word ptr X+2     
endm

CALLM macro P
    call P
endm

RETM macro N
    add SP, N
    ret
endm

LOOPM macro L
    loop L
endm

assume CS:code, DS:data

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

    pushm var

    mov word ptr var, 0ABCDh       
    mov word ptr var+2, 0EF01h     

    popm var

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

    retm 0
code ends

end start
