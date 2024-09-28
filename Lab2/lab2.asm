assume CS:code, DS:data

data segment
    arr dw 1, 3, 5, 2, 4, 6     
    arr_size dw 6               
data ends

code segment
start:
    mov AX, data
    mov DS, AX

    mov SI, 0

    mov AX, word ptr arr[SI]    

    add SI, 2                   

    mov CX, word ptr arr_size    

    dec CX        
                  
process_array:
    cmp CX, 0                   
    je end_process              

    mov AX, word ptr arr[SI]    

    cmp AX, word ptr arr[SI-2]  
    jge skip_update             

    mov AX, word ptr arr[SI-2]  
    mov word ptr arr[SI], AX    

skip_update:
    add SI, 2                   
    dec CX                      
    jmp process_array           

end_process:
    mov AH, 4Ch
    int 21h

code ends
end start
