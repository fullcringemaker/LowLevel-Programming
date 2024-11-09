assume CS:code, DS:data

data segment
    a db 1      ; a=1
    b db 2      ; b=2
    d db 4      ; c=3
    c db 3      ; d=4
data ends

code segment
start:
    mov AX, data
    mov DS, AX

    mov al, a     ;al = 1
    mov bl, b     ;bl = 2
    mov ah, 0     ;обнуление ah
    div bl        ;al = 1/2 = 0, ah = 1 mod 2 = 1
    mov bh, al    ;bh = 0

    mov al, d     ;al = 1
    mov bl, c     ;bl=3
    mov ah, 0     ;обнуление ah
    div bl        ;al= 4/3 = 1, ah = 4 mod 3 = 1
    add bh, al    ;bh = bh+al=0+1=1
    
    sub bh, 1     ;bh=bh-1=0

    mov AH, 4Ch
    int 21h
code ends
end start
