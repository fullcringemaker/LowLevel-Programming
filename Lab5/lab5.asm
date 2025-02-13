assume cs:code, ds:data

data segment
    cap db 19
    ; было просто dup('$')
    inputNumber1 db 20, 19 dup('$')
    inputNumber2 db 20, 19 dup('$')
    number1 db 20 dup(0) ; зафиксировали cap
    number2 db 20 dup(0) ; cap 
    newline db 0Dh, 0Ah, '$'
    warning db "incorrect format$"
    unsignedSumResult db 20, 19 dup('0'), '$'
    unsignedDiffResult db 20, 19 dup('0'), '$'
    unsignedMulResult db 20, 19 dup('0'), '$'
    textUnsignedSum db "Result of sum: $"
    textUnsignedDiff db "Result of diff: $"
    textUnsignedMul db "Result of mul: $"
    decimal db 10
    hexical db 16
    haveMinus db 0 ; количество минусов у обоих чисел 
    haveMinus1 db 0
    haveMinus2 db 0
data ends

code segment

convert proc 
    push bp 
    mov bp, sp

    mov si, [bp+6] ; inputNumber
    mov di, [bp+4] ; number

    inc si
    mov cl, [si] ; len(inputNumber1)

    ; для отрицательных

    mov al, [si+1]
    cmp al, '-'
    jne convertAction
    inc si 
    dec cl
    inc haveMinus

    convertAction:
        add si, cx ; сместили inputNumber1 в конец строки
        xor ax, ax
    convertNumber:
        mov al, [si]
        
        cmp al, '0'
        jl error
        cmp al, '9'
        jle decimalDigit

        cmp al, 'A'
        jl error
        cmp al, 'F'
        jg error

        sub al, 55
        jmp convertEnd

        decimalDigit:
            sub al, '0'
        
        convertEnd:
            mov [di], al
            inc di 
            dec si 
            loop convertNumber

    xor ax, ax
    pop bp
    ret	4
    error:
        mov ax, 1
        pop bp
        ret	4
convert endp

print proc 
    push bp 
    mov bp, sp

    mov di, [bp+6] ; result
    mov bx, [bp+4] ; textResult
    mov cl, [di] ; len(result)
    dec cl
    inc di 
    mov si, 1
    printLoop:
        mov al, [di]
        cmp cl, 0
        je printEnd 
        cmp al, '0'
        jne printEnd
        dec cl 
        inc di 
        inc si
        jmp printLoop
    
    printEnd:
        dec di
        cmp cl, 0
        je printCorrect
        mov al, haveMinus
        cmp al, 1
        jne withoutMinus
        mov al, '-'
        mov [di], al
        jmp printCorrect
        withoutMinus:
            inc di 
        printCorrect:
            mov ah, 09h 
            mov dx, offset newline
            int 21h
            mov ah, 09h 
            mov dx, bx
            int 21h
            mov ah, 09h 
            mov dx, di
            int 21h
    pop bp
    ret
print endp

unsignedSum proc 
    push bp 
    mov bp, sp

    mov dx, [bp+4]

    mov si, 0
    mov cl, [unsignedSumResult]
    dec cl
    mov di, offset unsignedSumResult
    add di, cx

    unsignedSumLoop:
        mov al, [number1+si]
        add al, [number2+si]
        add al, bl
        div dl
        cmp ah, 10
        jl digit
        jge symbol
    digit:
        add ah, '0'
        jmp unsignedSumEnd
    symbol:
        add ah, 55

    unsignedSumEnd:
        mov [di], ah
        mov bl, al

        xor ax, ax
        dec di
        inc si
        loop unsignedSumLoop

    push offset unsignedSumResult
    push offset textUnsignedSum
    call print
    add sp, 4
    pop bp 
    ret 
unsignedSum endp
    
unsignedDiff proc
    push bp 
    mov bp, sp

    mov cl, [unsignedDiffResult]
    dec cl
    mov di, offset unsignedDiffResult
    add di, cx
    xor dx, dx
    mov bx, 0

    unsignedDiffLoop:
        
        mov si, [bp+6] ; num1
        add si, 19
        sub si, cx
        
        mov al, [si]
        
        mov si, [bp+4] ; num2
        add si, 19
        sub si, cx
        
        mov dl, [si]
        cmp bl, 0
        je withoutLoan
        add dl, bl
        mov bl, 0
        withoutLoan:
            cmp al, dl 
            jge simpleDiff

            add al, 10
            mov bl, 1
            
            simpleDiff:
                sub al, dl
                add al, '0'
                mov [di], al 
        xor ax, ax
        dec di
        inc si
        loop unsignedDiffLoop

    push offset unsignedDiffResult
    mov dx, offset textUnsignedDiff
    mov al, haveMinus1
    add al, haveMinus2
    cmp al, 0
    je printDiff
    mov dx, offset textUnsignedSum
    printDiff:
        push dx
        call print
        add sp, 4
    pop bp
    ret 4
unsignedDiff endp

unsignedMul proc 
    mov si, 0
    mov cl, [unsignedMulResult]
    dec cl
    mov di, offset unsignedMulResult
    add di, cx

    unsignedMulLoopOuter:
        mov bx, 0
        mov dx, 0
        unsignedMulLoopInner:
            mov al, [number1+si]
            mul [number2+bx] 
            add al, dl ; добавили остаток

            div decimal 

            mov dl, al ; сохранили остаток

            ; 2 шаг - когда уже накоплена 1 цифра
            
            mov al, ah 
            mov ah, 0

            sub di, bx

            add al, [di]
            sub al, '0'
            add al, dh

            div decimal

            mov dh, al

            add ah, '0'
            mov [di], ah
            
            add di, bx

            inc bx
            xor ax, ax

            cmp cx, bx
            jne unsignedMulLoopInner
        inc si
        dec di
        loop unsignedMulLoopOuter

    push offset unsignedMulResult
    push offset textUnsignedMul
    call print
    add sp, 4
    ret  
unsignedMul endp
    
signedMul proc 
    xor ax, ax
    mov al, haveMinus1
    add al, haveMinus2
    mov cl, 2
    div cl
    mov haveMinus, ah
    call unsignedMul
    ret
signedMul endp

signedSum proc 
    xor ax, ax
    mov al, haveMinus1
    add al, haveMinus2
    mov cl, 2
    div cl
    cmp ah, 0
    je makeSignedSum
    jmp makeUnsignedDiff
    makeSignedSum:
        mov haveMinus, al
        mov dl, decimal
        push dx
        xor bx, bx
        call unsignedSum
        add sp, 2
        jmp signedSumEnd
    makeUnsignedDiff:
        mov si, offset number1
        mov di, offset number2
        mov al, [si]
        mov bl, [di]
        mov cx, 19
        add si, cx 
        add di, cx 
        inc cx
        compare:
            mov al, [si]
            mov bl, [di]
            cmp al, bl 
            jg first
            jl second
            dec si
            dec di 
            loop compare
        first:
            push offset number1
            push offset number2
            mov al, haveMinus1
            mov haveMinus, al
            jmp compareEnd
        second:
            push offset number2
            push offset number1
            mov al, haveMinus2
            mov haveMinus, al
        compareEnd:
            call unsignedDiff
    signedSumEnd:
    ret
signedSum endp

start:
    mov ax, data
    mov ds, ax
    mov ah, 0Ah 
    mov dx, offset inputNumber1
    int 21h

    push dx
    push offset number1

    call convert
    mov cl, haveMinus
    mov haveMinus1, cl

    cmp ax, 1
    je throwError

    mov ah, 09h 
    mov dx, offset newline
    int 21h
    mov ah, 0Ah 
    mov dx, offset inputNumber2
    int 21h

    push dx 
    push offset number2

    call convert
    mov cl, haveMinus
    mov bl, haveMinus1
    mov haveMinus2, cl
    sub haveMinus2, bl

    cmp ax, 1
    je throwError

    ; Беззнаковое сложение (поддерживает 16 формат: в функцию следует передать hexical вместо decimal)
    
    mov dl, hexical
    push dx
    call unsignedSum

    ; Беззнаковое вычитание

    ;push offset number1
    ;push offset number2
    ;call unsignedDiff

    ; Беззнаковое умножение
    ;call unsignedMul

    ; Знаковое сложение
    ;call signedSum

    ; Знаковое умножение
    ;call signedMul

    jmp final
    throwError:
        mov ah, 09h
        mov dx, offset newline
        int 21h
        mov ah, 09h
        mov dx, offset warning
        int 21h

    final:
        mov ax, 4C00h
        int 21h
code ends
end start
