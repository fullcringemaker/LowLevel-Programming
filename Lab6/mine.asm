;------------------------------------------------------------------------------
;  Сборка (TASM):
;    TASM /m lab6.asm
;    TLINK /x /3 lab6.obj
;    lab6.exe
;------------------------------------------------------------------------------

        .386p                ; Разрешить команды 386 и привилегированные инструкции

InitSegment segment para public 'CODE' use16
        assume CS:InitSegment, SS:InitStackSegment

RealInitEntry:
                mov     AX, 03h
                int     10h            ; текстовый режим 80x25 + очистка экрана
               
; Открывание линии А20 (для 32-битной адресации):
                in      AL,92h
                or      AL,2
                out     92h,AL
                xor     EAX, EAX
                mov     AX, MainPMSegment
                shl     EAX, 4
                add     EAX, offset BeginProtectedMode
                mov     dword ptr NewEntryOffset, EAX
                xor     EAX, EAX
                mov     AX, InitSegment
                shl     EAX, 4
                add     AX, offset GlobalDescTable
                mov     dword ptr GDTRRecord+2, EAX
                lgdt    fword ptr GDTRRecord
                cli
                in      AL, 70h
                or      AL, 80h
                out     70h, AL
                mov     EAX, CR0
                or      AL, 1
                mov     CR0, EAX
                db      66h            
                db      0EAh           
NewEntryOffset  dd      ?             
                dw      00001000b      

GlobalDescTable:

; Нулевой дескриптор (обязан быть в GDT):
NullDescriptor  db 8 dup(0)

; Дескриптор кода:
CodeDescriptor  db 0FFh,0FFh,00h,00h,00h,10011010b,11001111b,00h
; Дескриптор данных:
DataDescriptor  db 0FFh,0FFh,00h,00h,00h,10010010b,11001111b,00h

; Несколько «произвольных» дескрипторов:
Desc_01         db 0FFh,0FFh,01h,00h,00h,10010000b,11001111b,00h
Desc_02         db 0FFh,0FFh,02h,00h,00h,10010001b,11001111b,00h
Desc_03         db 0FFh,0FFh,03h,00h,00h,10010010b,11001111b,00h
Desc_04         db 0FFh,0FFh,04h,00h,00h,10010011b,11001111b,00h
Desc_05         db 0FFh,0FFh,05h,00h,00h,10010100b,11001111b,00h
Desc_06         db 0FFh,0FFh,06h,00h,00h,10010101b,11001111b,00h
Desc_07         db 0FFh,0FFh,07h,00h,00h,10010110b,11001111b,00h
Desc_08         db 0FFh,0FFh,08h,00h,00h,10010111b,11001111b,00h
Desc_09         db 0FFh,0FFh,09h,00h,00h,10011000b,11001111b,00h
Desc_0A         db 0FFh,0FFh,0Ah,00h,00h,10011001b,11001111b,00h
Desc_0B         db 0FFh,0FFh,0Bh,00h,00h,10011010b,11001111b,00h
Desc_0C         db 0FFh,0FFh,0Ch,00h,00h,10011011b,11001111b,00h
Desc_0D         db 0FFh,0FFh,0Dh,00h,00h,10011100b,11001111b,00h
Desc_0E         db 0FFh,0FFh,0Eh,00h,00h,10011101b,11001111b,00h
Desc_0F         db 0FFh,0FFh,0Fh,00h,00h,10011110b,11001111b,00h
Desc_10         db 0FFh,0FFh,10h,00h,00h,10011111b,11001111b,00h

GDTTableSize    equ  ($ - GlobalDescTable)

GDTRRecord      dw   GDTTableSize - 1
                dd   ?

InitSegment ends

InitStackSegment segment para stack 'STACK' use16
                db  100h dup(?)
InitStackSegment ends

MainPMSegment segment para public 'CODE' use32
        assume  CS:MainPMSegment, DS:MainPMData

AcquireSegmentBase proc
    mov  esi, edx
    xor  eax, eax
    mov  ah, byte ptr [esi + 7]
    mov  al, byte ptr [esi + 4]
    rept 16
        shl eax, 1
    endm
    mov  ah, byte ptr [esi + 3]
    mov  al, byte ptr [esi + 2]
    ret
endp

UnpackDLSField proc
    mov  esi, edx
    xor  eax, eax
    mov  al, byte ptr [esi + 5]
    shl  al, 1
    rept 6
        shr al, 1
    endm
    ret
endp

CheckPresenceFlag proc
    mov  esi, edx
    xor  eax, eax
    mov  al, byte ptr [esi + 5]
    rept 7
        shr al, 1
    endm
    ret
endp

EvaluateAVLBit proc
    mov  esi, edx
    xor  eax, eax
    mov  al, byte ptr [esi + 6]
    rept 3
        shl al, 1
    endm
    rept 7
        shr al, 1
    endm
    ret
endp

RetrieveGranularity proc
    mov  esi, edx
    xor  eax, eax
    mov  al, byte ptr [esi + 6]
    shl  al, 1
    rept 7
        shr al, 1
    endm
    ret
endp

IdentifySegMode proc
    mov  esi, edx
    xor  eax, eax
    mov  al, byte ptr [esi + 5]
    rept 4
        shl al, 1
    endm
    rept 4
        shr al, 1
    endm
    ret
endp

ComputeSegLimit proc
    mov  esi, edx
    xor  eax, eax
    mov  al, byte ptr [esi + 6]
    rept 4
        shl eax, 1
    endm
    rept 8
        shl eax, 1
    endm
    mov  ah, byte ptr [esi + 1]
    mov  al, byte ptr [esi]
    push bx
    mov  bl, byte ptr [esi + 6]
    rept 7
        shr bl, 1
    endm
    add  eax, 1
    cmp  bl, 1
    je   multy
    jmp  skip
multy:
    imul eax, 1000h
skip:
    pop  bx
    ret
endp

FormatInHex proc
    push edx
    cmp  al, 10
    mov  ah, al
    jl   noAdd
    add  al, 7
noAdd:
    add  al, 30h
    mov  [edi], al
    mov  dl, ch
    add  dl, 1
    cmp  dl, 16
    jl   writePos
    sub  dl, 15
writePos:
    mov  [edi + 1], dl
    mov  al, ah
    pop  edx
    ret
endp

PresentBaseValue proc
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
        call FormatInHex
        add  EDI, 2
        rept count
            shl eax, 1
        endm
        sub  ebx, eax
    endm
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
endp

DisplayDLSValue proc
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
        call FormatInHex
        add  EDI, 2
        rept count
            shl eax, 1
        endm
        sub  ebx, eax
    endm
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
endp

PrintDataClassification proc
    cmp  al, 2
    jge  data01
    push ax
    mov  al, 27  
    call FormatInHex
    add  EDI, 2
    pop  ax
    call ShowGeneralAttr
    ret
data01:
    sub  al, 2
    push ax
    mov  al, 32  
    call FormatInHex
    add  EDI, 2
    pop  ax
    call ShowGeneralAttr
    ret
endp

ShowDataProperties proc
    cmp  al, 4
    jge  data1
    push ax
    push dx
    mov  [edi], 24    ;; '↑'
    mov  dl, ch
    add  dl, 1
    cmp  dl, 16
    jl   up1
    sub  dl, 15
up1:
    mov  [edi + 1], dl
    add  EDI, 2
    pop  dx
    pop  ax
    call PrintDataClassification
    ret
data1:
    sub  al, 4
    push ax
    push dx
    mov  [edi], 25    ;; '↓'
    mov  dl, ch
    add  dl, 1
    cmp  dl, 16
    jl   up2
    sub  dl, 15
up2:
    mov  [edi + 1], dl
    add  EDI, 2
    pop  dx
    pop  ax
    call PrintDataClassification
    ret
endp

ShowGeneralAttr proc
    cmp  al, 1
    je   code001
    push ax
    mov  al, 23 
    call FormatInHex
    add  EDI, 2
    pop  ax
    ret
code001:
    sub  al, 1
    push ax
    mov  al, 10  
    call FormatInHex
    add  EDI, 2
    pop  ax
    ret
endp

PrintCodeClassification proc
    cmp  al, 2
    jge  code01
    push ax
    mov  al, 14  
    call FormatInHex
    add  EDI, 2
    pop  ax
    call ShowGeneralAttr
    ret
code01:
    sub  al, 2
    push ax
    mov  al, 27  
    call FormatInHex
    add  EDI, 2
    pop  ax
    call ShowGeneralAttr
    ret
endp

ShowCodeProperties proc
    cmp  al, 4
    jge  code1
    push ax
    mov  al, 23 
    call FormatInHex
    add  EDI, 2
    pop  ax
    call PrintCodeClassification
    ret
code1:
    sub  al, 4
    push ax
    mov  al, 12 
    call FormatInHex
    add  EDI, 2
    pop  ax
    call PrintCodeClassification
    ret
endp

DisplayModeInfo proc
    push eax
    push ebx
    push ecx
    push edx
    cmp  al, 8
    jge  isCode
    push ax
    mov  al, 13  
    call FormatInHex
    add  EDI, 2
    pop  ax
    call ShowDataProperties
    jmp  retHere
isCode:
    sub  al, 8
    push ax
    mov  al, 12  
    call FormatInHex
    add  EDI, 2
    pop  ax
    call ShowCodeProperties
retHere:
    pop  edx
    pop  ecx
    pop  ebx
    pop  eax
    ret
endp

ParseDescriptorEntry proc  
    push edx
    ; BASE
    call AcquireSegmentBase
    mov  EDI, 012000h
    add  EDI, EBX
    call PresentBaseValue
    add  EDI, 2
    ; LIMIT
    call ComputeSegLimit
    call PresentBaseValue
    add  EDI, 2
    ; MODE
    call IdentifySegMode
    call DisplayModeInfo
    add  EDI, 2
    ; DLS
    call UnpackDLSField
    call DisplayDLSValue
    add  EDI, 2
    ; PRESENCE
    call CheckPresenceFlag
    call FormatInHex
    add  EDI, 4
    ; AVL
    call EvaluateAVLBit
    call FormatInHex
    add  EDI, 4
    ; GRANULARITY
    call RetrieveGranularity
    call FormatInHex
    pop  edx
    ret
endp

BeginProtectedMode:

                mov     AX, 00010000b 
                mov     DS, AX
                mov     ES, AX
                mov     EDI, 00100000h 
                mov     EAX, 00101007h 
                stosd
                mov     ECX, 1023
                xor     EAX, EAX
                rep     stosd
                mov     EAX, 00000007h
                mov     ECX, 1024
FillPageLoop:
                stosd
                add     EAX, 00001000h
                loop    FillPageLoop
                mov     EAX, 00100000h
                mov     CR3, EAX
                mov     EAX, CR0
                or      EAX, 80000000h
                mov     CR0, EAX
                mov     EAX, 000B8007h
                mov     ES:00101000h+(012h*4), EAX
                xor     EAX, EAX
                sgdt    fword ptr GlobalTablePtr
                mov     DI, offset GlobalTablePtr
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

IterateDescEntries:
                call    ParseDescriptorEntry
                add     EDX, 8
                add     BX, 160
                inc     CH
                cmp     CL, CH
                jne     IterateDescEntries

; Вывод четырёх сообщений по разным смещениям 
PrintBlock1:
                mov     EDI, 012000h
                mov     ESI, MainPMData
                shl     ESI, 4
                add     ESI, offset descInfoA
                mov     ECX, descInfoSize
                rep     movsw

PrintBlock2:
                mov     EDI, 0120A0h
                mov     ESI, MainPMData
                shl     ESI, 4
                add     ESI, offset descInfoB
                mov     ECX, descInfoSize
                rep     movsw

PrintBlock3:
                mov     EDI, 012140h
                mov     ESI, MainPMData
                shl     ESI, 4
                add     ESI, offset descInfoC
                mov     ECX, descInfoSize
                rep     movsw

PrintBlock4:
                mov     EDI, 0121E0h
                mov     ESI, MainPMData
                shl     ESI, 4
                add     ESI, offset descInfoD
                mov     ECX, descInfoSize
                rep     movsw
                jmp     $   ; Вечный цикл

MainPMSegment ends

MainPMData segment para public 'DATA' use32
        assume CS:MainPMData

GlobalTablePtr    dw ?
                  dd ?

descInfoA:
irpc textA, <Segment BASE Info, Next is LIMIT, Then We Check MODE.                                    >
    db '&textA&',0Ah
endm

descInfoB:
irpc textB, <Descriptor Type: D or C, Growth: Up/Down, Conformance Bits.                              >
    db '&textB&',0Ah
endm

descInfoC:
irpc textC, <R/W/E Allowed or Not, Also Checking User-Bit: A/N.                                       >
    db '&textC&',0Ah
endm

descInfoD:
irpc textD, <Privilege (0..3), Presence Flag, AVL Bit, 16/32 mode.                                    >
    db '&textD&',0Ah
endm

descInfoSize equ 80

MainPMData ends

                end     RealInitEntry
