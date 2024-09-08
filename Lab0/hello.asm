assume CS:code,DS:data 

data segment 
msg db "Hello, world!$" 
data ends 

code segment 
start: 
mov AX, data 
mov DS, AX 

mov AH, 09h 
mov DX, offset msg 
int 21h

mov AH, 4Chint 21h 
code ends
end start 
