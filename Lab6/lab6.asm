 
; TASM:
; TASM /m PM.asm
; TLINK /x /3 PM.obj
; PM.exe
 
        .386p                                           ; разрешить привилегированные инструкции i386
       
; СЕГМЕНТ КОДА (для Real Mode)
; ----------------------------------------------------------------------------------
RM_CODE     segment     para public 'CODE' use16
        assume      CS:RM_CODE,SS:RM_STACK
@@start:
                    mov                 AX,03h
                    int                 10h            ; текстовый режим 80x25 + очистка экрана
               
; открываем линию А20 (для 32-х битной адресации):
        in      AL,92h
        or      AL,2
        out     92h,AL
 	
; вычисляем линейный адрес метки ENTRY_POINT (точка входа в защищенный режим):
        xor     EAX,EAX             ; обнуляем регистра EAX
        mov     AX,PM_CODE          ; AX = номер сегмента PM_CODE
        shl     EAX,4               ; EAX = линейный адрес PM_CODE
        add     EAX,offset ENTRY_POINT      ; EAX = линейный адрес ENTRY_POINT
        mov     dword ptr ENTRY_OFF,EAX     ; сохраняем его в переменной    
; (кстати, подобный "трюк" называется SMC или Self Modyfing Code - самомодифицирующийся код)
 
; теперь надо вычислить линейный адрес GDT (для загрузки регистра GDTR):
        xor     EAX,EAX
        mov     AX,RM_CODE          ; AX = номер сегмента RM_CODE
        shl     EAX,4               ; EAX = линейный адрес RM_CODE
        add     AX,offset GDT           ; теперь EAX = линейный адрес GDT
 
; линейный адрес GDT кладем в заранее подготовленную переменную:
        mov     dword ptr GDTR+2,EAX
; а подобный трюк назвать SMC уже нельзя, потому как по сути мы модифицируем данные <img src="styles/smiles_s/smile3.gif" class="mceSmilie" alt=":smile3:" title="Smile3    :smile3:">
 
; собственно, загрузка регистра GDTR:
        lgdt        fword ptr GDTR
 
; запрет маскируемых прерываний:
        cli
 
; запрет немаскируемых прерываний:
        in      AL,70h
        or      AL,80h
        out     70h,AL
 
; переключение в защищенный режим:
        mov     EAX,CR0
        or      AL,1
        mov     CR0,EAX
 
; загрузить новый селектор в регистр CS
        db      66h             ; префикс изменения разрядности операнда
        db      0EAh                ; опкод команды JMP FAR
ENTRY_OFF   dd      ?               ; 32-битное смещение
        dw      00001000b           ; селектор первого дескриптора (CODE_descr)
 
; ТАБЛИЦА ГЛОБАЛЬНЫХ ДЕСКРИПТОРОВ:
GDT:  
; нулевой дескриптор (обязательно должен присутствовать в GDT!):
NULL_descr  db      8 dup(0)
CODE_descr  db      0FFh,0FFh,00h,00h,00h,10011010b,11001111b,00h
DATA_descr  db      0FFh,0FFh,00h,00h,00h,10010010b,11001111b,00h
MY_descr1   db      0FFh,0FFh,01h,00h,00h,10010000b,11001111b,00h
MY_descr2   db      0FFh,0FFh,02h,00h,00h,10010001b,11001111b,00h
MY_descr3   db      0FFh,0FFh,03h,00h,00h,10010010b,11001111b,00h
MY_descr4   db      0FFh,0FFh,04h,00h,00h,10010011b,11001111b,00h
MY_descr5   db      0FFh,0FFh,05h,00h,00h,10010100b,11001111b,00h
MY_descr6   db      0FFh,0FFh,06h,00h,00h,10010101b,11001111b,00h
MY_descr7   db      0FFh,0FFh,07h,00h,00h,10010110b,11001111b,00h
MY_descr8   db      0FFh,0FFh,08h,00h,00h,10010111b,11001111b,00h
MY_descr9   db      0FFh,0FFh,09h,00h,00h,10011000b,11001111b,00h
MY_descr10  db      0FFh,0FFh,0Ah,00h,00h,10011001b,11001111b,00h
MY_descr11  db      0FFh,0FFh,0Bh,00h,00h,10011010b,11001111b,00h
MY_descr12  db      0FFh,0FFh,0Ch,00h,00h,10011011b,11001111b,00h
MY_descr13  db      0FFh,0FFh,0Dh,00h,00h,10011100b,11001111b,00h
MY_descr14  db      0FFh,0FFh,0Eh,00h,00h,10011101b,11001111b,00h
MY_descr15  db      0FFh,0FFh,0Fh,00h,00h,10011110b,11001111b,00h
MY_descr16  db      0FFh,0FFh,10h,00h,00h,10011111b,11001111b,00h

GDT_size    equ         $-GDT               ; размер GDT
 
GDTR        dw      GDT_size-1          ; 16-битный лимит GDT
   dd      ?               ; здесь будет 32-битный линейный адрес GDT

RM_CODE         ends
; -----------------------------------------------------------------------------
 
 
 
; СЕГМЕНТ СТЕКА (для Real Mode)
; -----------------------------------------------------------------------------
RM_STACK       segment          para stack 'STACK' use16
            db     100h dup(?)         ; 256 байт под стек - это даже много
RM_STACK       ends
; -----------------------------------------------------------------------------
 
 
 
; СЕГМЕНТ КОДА (для Protected Mode)
; -----------------------------------------------------------------------------
PM_CODE     segment     para public 'CODE' use32
        assume      CS:PM_CODE,DS:PM_DATA

base proc
    mov esi, edx
    xor eax, eax
    mov ah, byte ptr [esi + 7]
    mov al, byte ptr [esi + 4]
    rept 16
        shl eax, 1
    endm
    mov ah, byte ptr [esi + 3]
    mov al, byte ptr [esi + 2]
    ret
endp

dls proc
    mov esi, edx
    xor eax, eax
    mov al, byte ptr [esi + 5]
    shl al, 1
    rept 6
        shr al, 1
    endm
    ret
endp

present proc
    mov esi, edx
    xor eax, eax
    mov al, byte ptr [esi + 5]
    rept 7
        shr al, 1
    endm
    ret
endp

avl proc
    mov esi, edx
    xor eax, eax
    mov al, byte ptr [esi + 6]
    rept 3
        shl al, 1
    endm
    rept 7
        shr al, 1
    endm
    ret
endp

bits proc
    mov esi, edx
    xor eax, eax
    mov al, byte ptr [esi + 6]
    shl al, 1
    rept 7
        shr al, 1
    endm
    ret
endp


mode proc
    mov esi, edx
    xor eax, eax
    mov al, byte ptr [esi + 5]
    rept 4
        shl al, 1
    endm
    rept 4
        shr al, 1
    endm
    ret
endp

limit proc
    mov esi, edx
    xor eax, eax
    mov al, byte ptr [esi + 6]
    rept 4
        shl al, 1
    endm
    rept 8
        shl eax, 1
    endm
    mov ah, byte ptr [esi + 1]
    mov al, byte ptr [esi]
    push bx
    mov bl, byte ptr [esi + 6]
    rept 7
        shr bl, 1
    endm
    add eax, 1
    cmp bl, 1
    je multy
    jmp skip
    multy:
        imul eax, 1000h
    skip:
    pop bx
    ret
endp

maths proc
    push edx
    cmp al, 10
    mov ah, al
    jl notadd
    add al, 7
    notadd:
    add al, 30h
    mov [edi], al
    mov dl, ch
    add dl, 1
    cmp dl, 16
    jl write
    sub dl, 15
    write:
    mov [edi + 1], dl
    mov al, ah
    pop edx
    ret
endp

basepr proc
    push eax
    push ebx
    push ecx
    push edx
    mov ebx, eax
    cmp eax, 0FFFFFFFFh
    irp count, <28, 24, 20, 16, 12, 8, 4, 0>
        mov eax, ebx
        rept count
            shr eax, 1
        endm
        call maths
        add EDI, 2
        rept count
            shl eax, 1
        endm
        sub ebx, eax
    endm
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
endp

dlspr proc
    push eax
    push ebx
    push ecx
    push edx
    mov ebx, eax
    cmp eax, 0FFFFFFFFh
    irp count, <1, 0>
        mov eax, ebx
        rept count
            shr eax, 1
        endm
        call maths
        add EDI, 2
        rept count
            shl eax, 1
        endm
        sub ebx, eax
    endm
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
endp

dataxpr proc
    cmp al, 2
    jge data01
    push ax
    mov al, 27 ;; R
    call maths
    add EDI, 2
    pop ax
    call anyxxpr
    ret
    data01:
    sub al, 2
    push ax
    mov al, 32 ;; W
    call maths
    add EDI, 2
    pop ax
    call anyxxpr
    ret
endp

datapr proc
    cmp al, 4
    jge data1
    push ax
    push dx
    mov [edi], 24 ;; ↑
    mov dl, ch
    add dl, 1
    cmp dl, 16
    jl write1
    sub dl, 15
    write1:
    mov [edi + 1], dl
    add EDI, 2
    pop dx
    pop ax
    call dataxpr
    ret
    data1:
    sub al, 4
    push ax
    push dx
    mov [edi], 25 ;; ↑
    mov dl, ch
    add dl, 1
    cmp dl, 16
    jl write2
    sub dl, 15
    write2:
    mov [edi + 1], dl
    add EDI, 2
    pop dx
    pop ax
    call dataxpr
    ret
endp

anyxxpr proc
    cmp al, 1
    je code001
    push ax
    mov al, 23 ;; N
    call maths
    add EDI, 2
    pop ax
    ret
    code001:
    sub al, 1
    push ax
    mov al, 10 ;; A
    call maths
    add EDI, 2
    pop ax
    ret
endp

codexpr proc
    cmp al, 2
    jge code01
    push ax
    mov al, 14 ;; E
    call maths
    add EDI, 2
    pop ax
    call anyxxpr
    ret
    code01:
    sub al, 2
    push ax
    mov al, 27 ;; R
    call maths
    add EDI, 2
    pop ax
    call anyxxpr
    ret
endp

codepr proc
    cmp al, 4
    jge code1
    push ax
    mov al, 23 ;; N
    call maths
    add EDI, 2
    pop ax
    call codexpr
    ret
    code1:
    sub al, 4
    push ax
    mov al, 12 ;; N
    call maths
    add EDI, 2
    pop ax
    call codexpr
    ret
endp

modepr proc
    push eax
    push ebx
    push ecx
    push edx
    cmp al, 8
    jge code
    push ax
    mov al, 13  ;; D
    call maths
    add EDI, 2
    pop ax
    call datapr
    jmp return
    code:
    sub al, 8
    push ax
    mov al, 12  ;; C
    call maths
    add EDI, 2
    pop ax
    call codepr
    return:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
endp

logic proc ;;EDX - адрес регистра, BX - оффсет в видеопамяти
    push edx
    call base
    mov EDI, 012000h
    add EDI, eBX
    call basepr
    add edi, 2
    call limit
    call basepr
    add edi, 2
    call mode
    call modepr
    add edi, 2
    call dls
    call dlspr
    add edi, 2
    call present
    call maths
    add edi, 4
    call avl
    call maths
    add edi, 4
    call bits
    call maths
    pop edx
    ret
endp 


ENTRY_POINT:
; загрузим сегментные регистры селекторами на соответствующие дескрипторы:
                 mov           AX,00010000b      ; селектор на второй дескриптор (DATA_descr)
     mov           DS,AX                         ; в DS его        
     mov           ES,AX                         ; его же - в ES


 
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
; создать каталог страниц
                mov        EDI,00100000h               ; его физический адрес - 1 Мб
    mov        EAX,00101007h               ; адрес таблицы 0 = 1 Мб + 4 Кб
    stosd                              ; записать первый элемент каталога
    mov        ECX,1023                    ; остальные элементы каталога -
    xor        EAX,EAX                     ; нули
    rep                 stosd
; заполнить таблицу страниц 0
                mov        EAX,00000007h               ; 0 - адрес страницы 0
    mov        ECX,1024                    ; число страниц в таблице
fill_page_table:
    stosd                              ; записать элемент таблицы
    add        EAX,00001000h               ; добавить к адресу 4096 байтов
    loop                fill_page_table        ; и повторить для всех элементов
; поместить адрес каталога страниц в CR3
                mov        EAX,00100000h               ; базовый адрес = 1 Мб
    mov        CR3,EAX
; включить страничную адресацию,
                mov        EAX,CR0
 or        EAX,80000000h
     mov           CR0,EAX
; а теперь изменить физический адрес страницы 12000h на 0B8000h
                mov        EAX,000B8007h
    mov        ES:00101000h+012h*4,EAX

        xor     EAX,EAX
        sgdt    fword ptr GDTAddr
        mov     di, offset GDTAddr
        mov     ax, word ptr [di]
        add     di, 2
        mov     edx, dword ptr [di]
        inc     ax
        mov ch, 8
        div     ch
        mov cl, al
        mov ch, 0
        xor ebx, ebx
        mov BX, 640
        cycle: ;; CL CH - контроль цикла, EDX - адресс таблицы, BX - оффсет в видеопамяти
            call logic
            add edx, 8
            add bx, 160
            inc ch
            cmp cl, ch
            jne cycle 
; * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
mess1:
; вывод mes1 по стандартному адресу (начало видеопамяти 0B8000h)
    mov            EDI,012000h                ; для команды movsw, EDI = начало видепамяти
    mov            ESI,PM_DATA                 ;
    shl            ESI,4
    add            ESI,offset mes1             ; ESI = адрес начала mes1
    mov            ECX,mes_len                 ; длина текста в ECX
    rep            movsw                       ; DS:ESI (наше сообщение) -> ES:EDI
                                               ; (видеопамять)
; вывод mes2 по НЕСТАНДАРТНОМУ АДРЕСУ 12000h:
mess2:
    mov            EDI,0120A0h     ; 12000h (уже можешь считать, что это
                                    ; 0B8000h) + A0h
    mov            ESI,PM_DATA
    shl            ESI,4
    add            ESI,offset mes2 ; ESI = адрес начала mes2
    mov            ECX,mes_len     ; длина текста в ECX
    rep            movsw           ; DS:ESI (наше сообщение) -> ES:12000h
                                               ;(типа видеопамять)
    
    mov            EDI,012140h     ; 12000h (уже можешь считать, что это
                                    ; 0B8000h) + A0h
    mov            ESI,PM_DATA
    shl            ESI,4
    add            ESI,offset mes3 ; ESI = адрес начала mes2
    mov            ECX,mes_len     ; длина текста в ECX
    rep            movsw           ; DS:ESI (наше сообщение) -> ES:12000h
                                               ;(типа видеопамять)
    mov            EDI,0121E0h     ; 12000h (уже можешь считать, что это
                                    ; 0B8000h) + A0h
    mov            ESI,PM_DATA
    shl            ESI,4
    add            ESI,offset mes4 ; ESI = адрес начала mes2
    mov            ECX,mes_len     ; длина текста в ECX
    rep            movsw           ; DS:ESI (наше сообщение) -> ES:12000h
                                               ;(типа видеопамять)
 
 
    jmp            $                           ; погружаемся в вечный цикл
PM_CODE         ends
; -------------------------------------------------------------------------------------
 
 
; СЕГМЕНТ ДАННЫХ (для Protected Mode)
; -------------------------------------------------------------------------------------
PM_DATA         segment        para public 'DATA' use32
        assume         CS:PM_DATA
 
GDTAddr dw ?
        dd ?
; сообщение, которое мы будем выводить на экран (оформим его в виде блока повторений irpc):
mes1:
irpc            mes1,          <1st block - BASE address, 2nd - LIMIT, 3rd - MODE,                              >
                db             '&mes1&',0Bh
endm
mes2:
irpc            mes2,          <Mode - D(ata)/C(ode), (Up)/(Down)/C(onformed)/N(ot conformed),                  >
                db             '&mes2&',0Bh
endm
mes3:
irpc            mes3,          <R(ead)/W(rite + read)/E(xecute only) A(vailable)/N(ot available)               >
                db             '&mes3&',0Bh
endm
mes4:
irpc            mes4,          <DPL (00 - 11), Present (0/1), Available bit (0/1), 0/1 32-bit mode              >
                db             '&mes4&',0Bh
endm
mes_len         equ            80                  ; длина в байтах
PM_DATA         ends
; ----------------------------------------------------------------------------------------------  
                end         @@start
