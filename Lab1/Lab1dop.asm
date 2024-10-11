assume CS:code, DS:data
data segment
    a db 1                ; a = 1
    b db 2                ; b = 2
    d db 4                ; d = 4
    c db 3                ; c = 3
    str db '000 00h','$'   
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
    mov bl, c     ;bl= 3
    mov ah, 0 
    div bl        ;al= 4/3 = 1, ah = 4 mod 3 = 1
    add bh, al    ;bh = bh+al=0+1=1
    
    sub bh, 1     ;bh=bh-1=0


    mov ax, 0             
    mov al, bh            
    mov ah, 0             
    mov bl, 100           
    div bl                
    add al, '0'           
    mov [str], al         

    mov al, ah            
    mov ah, 0             
    mov bl, 10            
    div bl                
    add al, '0'           
    mov [str+1], al       

    mov al, ah            
    add al, '0'           
    mov [str+2], al       

    mov al, bh     
    mov ah, 0             
    mov bl, 16            
    div bl                

    cmp al, 10           
    jb hex_high_is_num    
    add al, 55            
    jmp hex_high_done    
hex_high_is_num:
    add al, '0'          
hex_high_done:
    mov [str+4], al       

    mov al, ah           
    cmp al, 10            
    jb hex_low_is_num     
    add al, 55            
    jmp hex_low_done     
hex_low_is_num:
    add al, '0'           
hex_low_done:
    mov [str+5], al

    lea dx, str           
    mov ah, 09h           
    int 21h               

    mov AH, 4Ch           
    int 21h               
code ends
end start

Данный код выполняет свою задачу а именно осуществляет вывод ответа в десятиричном формате и, через пробел, в шестнадцатиричном формате, при этом на конце шестнадцатиричного числа была h.Также вывод осуществлялся без никаких дополнительных ненужных надписей или слов, выводится только 2 числа с теми условиями, что я указал в предыдущем предложении. 
Однако есть один минус. Повтор кусков кода не является оптимальным универсальным методом (к тому же может не работать, если считать, что и переменные, и результат будет большей разрядности, чем байт). 

Мне необходимо переделать данный код с использованием циклов. При этом переделанный вариант должен выполнять свою задачу, которую я указал ранее
