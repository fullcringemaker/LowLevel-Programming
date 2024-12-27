; TASM:
; TASM /m PM.asm
; TLINK /x /3 PM.obj
; PM.exe

        .386p                           ; разрешить привилегированные инструкции i386
       
; СЕГМЕНТ КОДА (для Real Mode)
; ----------------------------------------------------------------------------------
RM_CODE     segment     para public 'CODE' use16
        assume      CS:RM_CODE, SS:RM_STACK
@@start:
                    mov     AX, 03h
                    int     10h            ; текстовый режим 80x25 + очистка экрана
               
; Открываем линию А20 (для 32-битной адресации):
        in      AL, 92h
        or      AL, 2
        out     92h, AL

; вычисляем линейный адрес метки MY_ENTRY (точка входа в защищённый режим):
        xor     EAX, EAX
        mov     AX, PM_CODE
        shl     EAX, 4
        add     EAX, offset MY_ENTRY
        mov     dword ptr ENTRY_OFF, EAX

; Теперь вычислить линейный адрес GDT (для загрузки регистра GDTR):
        xor     EAX, EAX
        mov     AX, RM_CODE
        shl     EAX, 4
        add     AX, offset GDT

        mov     dword ptr GDTR+2, EAX

; Собственно, загрузка регистра GDTR:
        lgdt    fword ptr GDTR

; Запрет маскируемых прерываний:
        cli

; Запрет немаскируемых прерываний:
        in      AL, 70h
        or      AL, 80h
        out     70h, AL

; Переключение в защищенный режим:
        mov     EAX, CR0
        or      AL, 1
        mov     CR0, EAX

; Загрузить новый селектор в регистр CS:
        db      66h             ; префикс изменения разрядности операнда
        db      0EAh            ; опкод команды JMP FAR
ENTRY_OFF   dd      ?           ; 32-битное смещение будет записан выше
        dw      00001000b       ; селектор первого дескриптора (CODE_descr)

; ТАБЛИЦА ГЛОБАЛЬНЫХ ДЕСКРИПТОРОВ:
GDT:
; Нулевой дескриптор:
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

GDT_size    equ     $-GDT
GDTR        dw      GDT_size-1
            dd      ?               ; 32-битный линейный адрес GDT

RM_CODE     ends
; -----------------------------------------------------------------------------


; СЕГМЕНТ СТЕКА (для Real Mode)
; -----------------------------------------------------------------------------
RM_STACK    segment para stack 'STACK' use16
            db 100h dup(?)
RM_STACK    ends
; -----------------------------------------------------------------------------


; СЕГМЕНТ КОДА (для Protected Mode)
; -----------------------------------------------------------------------------
PM_CODE     segment para public 'CODE' use32
        assume  CS:PM_CODE, DS:PM_DATA

; -----------------------------------------------------------------------------
; Переименованные процедуры:
; -----------------------------------------------------------------------------

GetBase proc
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

GetDLS proc
    mov esi, edx
    xor eax, eax
    mov al, byte ptr [esi + 5]
    shl al, 1
    rept 6
        shr al, 1
    endm
    ret
endp

GetPresent proc
    mov esi, edx
    xor eax, eax
    mov al, byte ptr [esi + 5]
    rept 7
        shr al, 1
    endm
    ret
endp

GetAVL proc
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

GetBits proc
    mov esi, edx
    xor eax, eax
    mov al, byte ptr [esi + 6]
    shl al, 1
    rept 7
        shr al, 1
    endm
    ret
endp

GetMode proc
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

GetLimit proc
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
    je  multy
    jmp skip
multy:
    imul eax, 1000h
skip:
    pop bx
    ret
endp

CalcHex proc
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

ShowBase proc
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
        call CalcHex
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

ShowDLS proc
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
        call CalcHex
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

ShowDataType proc
    cmp al, 2
    jge data01
    push ax
    mov al, 27 ;; R
    call CalcHex
    add EDI, 2
    pop ax
    call ShowAnyAttr
    ret
data01:
    sub al, 2
    push ax
    mov al, 32 ;; W
    call CalcHex
    add EDI, 2
    pop ax
    call ShowAnyAttr
    ret
endp

ShowDataAttr proc
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
    call ShowDataType
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
    call ShowDataType
    ret
endp

ShowAnyAttr proc
    cmp al, 1
    je  code001
    push ax
    mov al, 23 ;; N
    call CalcHex
    add EDI, 2
    pop ax
    ret
code001:
    sub al, 1
    push ax
    mov al, 10 ;; A
    call CalcHex
    add EDI, 2
    pop ax
    ret
endp

ShowCodeType proc
    cmp al, 2
    jge code01
    push ax
    mov al, 14 ;; E
    call CalcHex
    add EDI, 2
    pop ax
    call ShowAnyAttr
    ret
code01:
    sub al, 2
    push ax
    mov al, 27 ;; R
    call CalcHex
    add EDI, 2
    pop ax
    call ShowAnyAttr
    ret
endp

ShowCodeAttr proc
    cmp al, 4
    jge code1
    push ax
    mov al, 23 ;; N
    call CalcHex
    add EDI, 2
    pop ax
    call ShowCodeType
    ret
code1:
    sub al, 4
    push ax
    mov al, 12 ;; N
    call CalcHex
    add EDI, 2
    pop ax
    call ShowCodeType
    ret
endp

ShowMode proc
    push eax
    push ebx
    push ecx
    push edx
    cmp al, 8
    jge isCode
    push ax
    mov al, 13  ;; D
    call CalcHex
    add EDI, 2
    pop ax
    call ShowDataAttr
    jmp retHere
isCode:
    sub al, 8
    push ax
    mov al, 12  ;; C
    call CalcHex
    add EDI, 2
    pop ax
    call ShowCodeAttr
retHere:
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
endp

ProcessDescriptor proc  ;; EDX - адрес дескриптора, BX - оффсет в видеопамяти
    push edx
    call GetBase
    mov EDI, 012000h
    add EDI, EBX
    call ShowBase
    add EDI, 2
    call GetLimit
    call ShowBase
    add EDI, 2
    call GetMode
    call ShowMode
    add EDI, 2
    call GetDLS
    call ShowDLS
    add EDI, 2
    call GetPresent
    call CalcHex
    add EDI, 4
    call GetAVL
    call CalcHex
    add EDI, 4
    call GetBits
    call CalcHex
    pop edx
    ret
endp

; -----------------------------------------------------------------------------
MY_ENTRY:
; Загрузим сегментные регистры селекторами на соответствующие дескрипторы
    mov     AX, 00010000b      ; селектор на второй дескриптор (DATA_descr)
    mov     DS, AX
    mov     ES, AX

; Создать каталог страниц:
    mov     EDI, 00100000h     ; физический адрес каталога - 1 Мб
    mov     EAX, 00101007h     ; адрес таблицы 0 = 1 Мб + 4 Кб
    stosd
    mov     ECX, 1023
    xor     EAX, EAX
    rep     stosd

; Заполнить таблицу страниц 0:
    mov     EAX, 00000007h
    mov     ECX, 1024
fill_page_table:
    stosd
    add     EAX, 00001000h
    loop    fill_page_table

; Поместить адрес каталога страниц в CR3
    mov     EAX, 00100000h
    mov     CR3, EAX

; Включить страничную адресацию
    mov     EAX, CR0
    or      EAX, 80000000h
    mov     CR0, EAX

; Изменить физический адрес страницы 12000h на 0B8000h
    mov     EAX, 000B8007h
    mov     ES:00101000h+012h*4, EAX

    xor     EAX, EAX
    sgdt    fword ptr GDTAddr
    mov     DI, offset GDTAddr
    mov     AX, word ptr [DI]
    add     DI, 2
    mov     EDX, dword ptr [DI]
    inc     AX
    mov     CH, 8
    div     CH
    mov     CL, AL
    mov     CH, 0
    xor     EBX, EBX
    mov     BX, 640

loop_descriptors: ;; CL CH - контроль цикла, EDX - адрес таблицы, BX - оффсет в видеопамяти
    call    ProcessDescriptor
    add     EDX, 8
    add     BX, 160
    inc     CH
    cmp     CL, CH
    jne     loop_descriptors

; -----------------------------------------------------------------------------
; Вывод в видеопамять "под стандартным" и "нестандартным" адресом
; -----------------------------------------------------------------------------

showMsg1:
    mov     EDI, 012000h
    mov     ESI, PM_DATA
    shl     ESI, 4
    add     ESI, offset infoMsg1
    mov     ECX, info_len
    rep     movsw

showMsg2:
    mov     EDI, 0120A0h
    mov     ESI, PM_DATA
    shl     ESI, 4
    add     ESI, offset infoMsg2
    mov     ECX, info_len
    rep     movsw

showMsg3:
    mov     EDI, 012140h
    mov     ESI, PM_DATA
    shl     ESI, 4
    add     ESI, offset infoMsg3
    mov     ECX, info_len
    rep     movsw

showMsg4:
    mov     EDI, 0121E0h
    mov     ESI, PM_DATA
    shl     ESI, 4
    add     ESI, offset infoMsg4
    mov     ECX, info_len
    rep     movsw

    jmp     $  ; Вечный цикл

PM_CODE     ends
; -----------------------------------------------------------------------------


; СЕГМЕНТ ДАННЫХ (для Protected Mode)
; -----------------------------------------------------------------------------
PM_DATA     segment para public 'DATA' use32
        assume  CS:PM_DATA

GDTAddr dw ?
        dd ?

; Ниже – изменённые сообщения (цвет 07h вместо 0Bh, текст переписан):
infoMsg1:
irpc newMsg1, <Segment BASE Info, Next is LIMIT, Then We Check MODE.                              >
    db '&newMsg1&',0Ah
endm

infoMsg2:
irpc newMsg2, <Descriptor Type: D or C, Growth: Up/Down, Conformance Bits.                              >
    db '&newMsg2&',0Ah
endm

infoMsg3:
irpc newMsg3, <R/W/E Allowed or Not, Also Checking User-Bit: A/N.                              >
    db '&newMsg3&',0Ah
endm

infoMsg4:
irpc newMsg4, <Privilege (0..3), Presence Flag, AVL Bit, 16/32 mode.                              >
    db '&newMsg4&',0Ah
endm

info_len equ 80

PM_DATA     ends
; -----------------------------------------------------------------------------

                end @@start
