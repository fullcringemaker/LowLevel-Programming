assume cs:code, ds:data

data segment

; ---- Для lgdt [OrgGdtDesc] ----
OrgGdtDesc  dw 0
            dw 0
            dw 0

OrgGdtSize  dw 0

; ---- PDE/PTE ----
PdeBase     dw 0
            dw 0
PteBase     dw 0
            dw 0

; ---- Переменные для декодирования дескриптора ----

; Здесь храним (LIMIT15..0)
DescLimitLow      dw ?
; (BASE15..0)
DescBaseLow       dw ?
; (BASE23..16) - 8 бит
DescBaseMid       dw ?
; (BASE31..24) - 8 бит
DescBaseHigh      dw ?
; (Access / Type) - 8 бит
DescAccess        db ?
; (High nibble limit + flags)
DescLimitFlags    db ?
; (Скопированный Type, если нужно)
DescType          db ?

; Для финального 32-битного Base (как 2 слова):
DescriptorBase32  dw 2 dup(?)

; Для финального 32-битного Limit (как 2 слова):
DescriptorLimit32 dw 2 dup(?)

; Вспомогательные «темпы»
TempLimitLow      dw ?
TempByte1         db ?
TempByte2         db ?

; ---------------------------
; Собственно GDT (5 дескрипторов по 8 байт)
; ---------------------------
; (0) Нулевой
GDTLabel dw 0FFFFh
         dw 0
         db 0
         db 0

; (1) Код (base=0, limit=FFFFF, G=1 => 4Гб)
         dw 0FFFFh
         dw 0
         db 10011010b
         db 11001111b

; (2) Данные (base=0, limit=FFFFF, G=1 => 4Гб)
         dw 0FFFFh
         dw 0
         db 10010010b
         db 11001111b

; (3) Доп. дескриптор
         dw 1
         dw 2
         db 10010010b
         db 00000000b

; (4) Доп. дескриптор
         dw 2
         dw 1
         db 10011010b
         db 00000000b

AlignPDE  db 0
PDE       dw 1024 dup(0)

AlignPTE  db 0
PTE       dw 1024*2 dup(0)

VidMsg  db 'Некорректный дескриптор$',0
GoodMsg db 'Descriptor OK$',0

; Для показа строк
CurRow dw ?
CurCol dw ?

data ends


code segment
start:
  mov ax, data
  mov ds, ax

  ; Очистим экран
  mov ax, 3
  int 10h

  cli
  xor ax, ax
  mov ss, ax
  mov sp, 1000h

  ;--------------------------------
  ;   Сформируем OrgGdtDesc
  ;   (5*8=40 байт, => limit=39)
  ;--------------------------------
  mov bx, (5*8 - 1)
  ; [OrgGdtSize] = bx
  mov si, offset OrgGdtSize
  mov [ds:si], bx

  ; ; limit => OrgGdtDesc[0..1]
  mov si, offset OrgGdtSize
  mov ax, [ds:si]
  mov si, offset OrgGdtDesc
  mov [ds:si], ax

  ; ; baseLow => offset GDTLabel
  mov bx, offset GDTLabel
  add si, 2
  mov [ds:si], bx

  ; ; baseHigh => ds
  mov bx, ds
  add si, 2
  mov [ds:si], bx

  ;--------------------------------
  ; lgdt [OrgGdtDesc]
  ; (0F 01 16 + disp16)
  ;--------------------------------
  db 0Fh, 01h, 16h
  dw OrgGdtDesc

  ;--------------------------------
  ; mov eax,cr0; and eax,0FFFFFFFEh; or eax,1; mov cr0,eax
  ;--------------------------------
  db 66h,0Fh,020h,0C0h
  db 66h,81h,0E0h,0FEh,0FFh,0FFh,0FFh
  db 66h,81h,0C8h,01h,0,0,0
  db 66h,0Fh,022h,0C0h

  ; Дальний прыжок (cs=8, ip=StartPM)
  db 0EAh
  dw StartPM
  dw 8

;------------------------------------------------------------------------------
; Protected mode
;------------------------------------------------------------------------------
StartPM:
  mov ax, 10h
  mov ds, ax
  mov es, ax
  mov ss, ax
  mov sp, 2000h

  ; Сохраним PDEBase / PTEBase
  mov bx, offset PDE
  mov si, offset PdeBase
  mov [ds:si], bx
  mov bx, ds
  add si,2
  mov [ds:si], bx

  mov bx, offset PTE
  mov si, offset PteBase
  mov [ds:si], bx
  mov bx, ds
  add si,2
  mov [ds:si], bx

  ;------------------------------------------------------------------------------
  ; Инициализируем PDE (1 запись, остальные 0)
  ;------------------------------------------------------------------------------
  mov si, offset PDE
  mov cx, 1024
InitPDE:
  push cx
  mov dx, cx
  dec dx
  cmp dx,0
  jne FillZeroPde

  ; Запись #0 => addr=PTE>>12, флаги=3
  ; Читаем PteBase
  mov di, offset PteBase
  mov ax,[ds:di]
  mov dx,[ds:di+2]
  mov bp,12
ShiftPdeLoop:
  clc
  rcr dx,1
  clc
  rcr ax,1
  dec bp
  jnz ShiftPdeLoop

  ; mov [si], ax
  mov [ds:si], ax
  add si,2
  mov [ds:si], dx
  add si,2

  ; or word ptr [ds:si-4],3
  sub si,4
  or word ptr [ds:si],3
  add si,4
  pop cx
  loop InitPDE
  jmp PDEdone

FillZeroPde:
  mov word ptr [ds:si],0
  add si,2
  mov word ptr [ds:si],0
  add si,2
  pop cx
  loop InitPDE

PDEdone:

  ;------------------------------------------------------------------------------
  ; Инициализируем PTE (страница2 => B8000h, иначе N<<12)
  ;------------------------------------------------------------------------------
  mov si, offset PTE
  mov cx,1024
InitPTE:
  mov dx,cx
  dec dx
  cmp dx,2
  je VideoPage
  ; dx<<12
  xor ax,ax
  mov bp,12
ShiftLeftPte:
  add ax,ax
  rcl dx,1
  dec bp
  jnz ShiftLeftPte
  jmp SetFrame

VideoPage:
  mov dx,0
  mov ax,0B800h

SetFrame:
  ; (dx:ax)>>12
  mov bp,12
ShiftRightPte:
  clc
  rcr dx,1
  clc
  rcr ax,1
  dec bp
  jnz ShiftRightPte

  ; Запишем
  mov [ds:si], ax
  add si,2
  mov [ds:si], dx
  add si,2
  ; or word ptr [ds:si-4],3
  sub si,4
  or word ptr [ds:si],3
  add si,4
  loop InitPTE

  ;------------------------------------------------------------------------------
  ; mov cr3, PDEbase
  ;------------------------------------------------------------------------------
  mov di, offset PdeBase
  mov ax,[ds:di]
  mov dx,[ds:di+2]
  mov bp,12
ShiftCr3:
  clc
  rcr dx,1
  clc
  rcr ax,1
  dec bp
  jnz ShiftCr3
  push ax
  push dx
  db 66h,58h
  db 0Fh,022h,0D8h

  ;------------------------------------------------------------------------------
  ; PG=1 в CR0
  ;------------------------------------------------------------------------------
  db 66h,0Fh,020h,0C0h
  db 66h,81h,0C8h,0,0,0,80h
  db 66h,0Fh,022h,0C0h

  ;------------------------------------------------------------------------------
  ; Теперь всё готово. Печатаем данные из GDT.
  ;------------------------------------------------------------------------------
NextStep:
  ; mov ax,0B800h + mov es,ax
  mov ax,0B800h
  mov es,ax

  xor ax,ax
  mov si, offset CurRow
  mov [ds:si], ax
  mov si, offset CurCol
  mov [ds:si], ax

  mov cx,5
  xor si,si   ; si=0 => деск.#0
  xor bx,bx   ; bx=0 => для цвета
ShowGDTLoop:
  push cx
  push si
  push bx

  ; Вызываем DecodeDescriptor( offset=GDTLabel+si )
  mov di, si
  add di, GDTLabel
  call DecodeDescriptor

  pop bx
  pop si
  add si,8
  pop cx
  inc bx
  loop ShowGDTLoop

LoopForever:
  jmp LoopForever


;------------------------------------------------------------------------------
; DecodeDescriptor
; DS:DI => на 8байт дескриптора
; BX => индекс дескриптора (для цвета)
; Вычитываем поля в глобальные переменные, анализируем, выводим
;------------------------------------------------------------------------------
DecodeDescriptor proc near
  push ax
  push dx
  push bp
  push si
  push di

  ; 1) Считать LIMIT15..0 => DescLimitLow
  mov bp, di
  mov ax, [ds:bp]
  mov si, offset DescLimitLow
  mov [ds:si], ax

  ; 2) BASE15..0 => DescBaseLow
  add bp,2
  mov ax, [ds:bp]
  mov si, offset DescBaseLow
  mov [ds:si], ax

  ; 3) BASE23..16 => DescBaseMid
  add bp,2
  mov al, [ds:bp]
  mov si, offset DescBaseMid
  mov [ds:si], al

  ; 4) Access => DescAccess
  inc bp
  mov al, [ds:bp]
  mov si, offset DescAccess
  mov [ds:si], al

  ; 5) LIMIT19..16(4bit) + flags(4bit) => DescLimitFlags
  inc bp
  mov al, [ds:bp]
  mov si, offset DescLimitFlags
  mov [ds:si], al

  ; 6) BASE31..24 => DescBaseHigh
  inc bp
  mov al, [ds:bp]
  mov si, offset DescBaseHigh
  mov [ds:si], al

  ;-----------------------------------
  ; Сохраняем DescType= DescAccess (Type/attrib)
  ;-----------------------------------
  mov si, offset DescAccess
  mov al, [ds:si]
  mov si, offset DescType
  mov [ds:si], al

  ;-----------------------------------
  ; Формируем Base32 = (BaseLow + BaseMid<<16 + BaseHigh<<24) упрощённо
  ; Для TASM 2.02 вручную пишем 2 слова
  ;-----------------------------------
  ; BaseLow (16бит)
  mov si, offset DescBaseLow
  mov ax, [ds:si]   ; baseLow
  mov di, offset DescriptorBase32
  mov [ds:di], ax   ; нижние 16 бит
  ; BaseMid (8бит)
  mov si, offset DescBaseMid
  xor ah,ah
  mov al,[ds:si]
  ; Сдвинем AL на 16 бит => вручную rcl
  mov cx,16
ShiftMidBase:
  clc
  rcl ax,1
  dec cx
  jnz ShiftMidBase
  ; Прибавим к DescriptorBase32
  mov si, offset DescriptorBase32
  mov dx,[ds:si]
  add dx,ax
  mov [ds:si], dx

  ; BaseHigh (8бит) => <<24
  mov si, offset DescBaseHigh
  xor ax,ax
  mov al,[ds:si]
  mov cx,24
ShiftHighBase:
  clc
  rcl ax,1
  dec cx
  jnz ShiftHighBase
  ; Прибавим
  mov si, offset DescriptorBase32
  mov dx,[ds:si]
  add dx,ax
  mov [ds:si], dx

  ;-----------------------------------
  ; Формируем Limit20 = LimitLow + (LimitHigh<<16)[4бита]
  ; Если G=1 => физ.лимит = (Limit20<<12 + 0FFFh)
  ;-----------------------------------
  mov si, offset DescLimitLow
  mov ax,[ds:si]
  mov di, offset DescriptorLimit32
  mov [ds:di], ax  ; нижние 16 бит (пока)

  ; Выделим high nibble
  mov si, offset DescLimitFlags
  mov al,[ds:si]
  and al,0Fh
  xor ah,ah
  ; Сдвинем AL на 16
  mov cx,16
ShiftLimHigh:
  clc
  rcl ax,1
  dec cx
  jnz ShiftLimHigh
  ; Прибавим
  mov si, offset DescriptorLimit32
  mov dx,[ds:si]
  add dx,ax
  mov [ds:si], dx

  ; Проверим G=bit7 DescLimitFlags
  mov si, offset DescLimitFlags
  mov al,[ds:si]
  and al,80h
  cmp al,0
  je No4k

  ; Если G=1 => (Limit20<<12 + 0FFFh)
  ; Для простоты: Limit20<<12 =>  сдвиг 12 раз, +0FFFh => прибавка
  ; Считаем DescriptorLimit32 в dx
  mov si, offset DescriptorLimit32
  mov dx,[ds:si]   ; 16 бит

  ; Сдвигаем <<12
  mov cx,12
ShiftLimit32:
  add dx,dx
  dec cx
  jnz ShiftLimit32

  ; Прибавим 0FFFh
  add dx,0FFFh
  mov si, offset DescriptorLimit32
  mov [ds:si], dx

No4k:

  ;-----------------------------------
  ; Проверяем корректность (P=1, S=1)
  ; DescAccess => bit7=P, bit4=S
  ;-----------------------------------
  mov si, offset DescAccess
  mov al,[ds:si]
  ; P=bit7?
  test al,10000000b
  jz MarkInvalid
  ; S=bit4?
  test al,00010000b
  jz MarkInvalid

  ; Если всё ок => выводим «Descriptor OK» + поля
  jmp OutputDesc

MarkInvalid:
  ; Вывести "Некорректный дескриптор"
  push bx
  call PrintStringError
  pop bx
  jmp DoneDecode

OutputDesc:
  push bx
  call PrintStringOK
  pop bx

DoneDecode:
  pop di
  pop si
  pop bp
  pop dx
  pop ax
  ret
DecodeDescriptor endp


;------------------------------------------------------------------------------
; Вывести «Некорректный дескриптор»
;------------------------------------------------------------------------------
PrintStringError proc near
  push ax
  push si
  push ds

  ; DS уже=DS, строка = VidMsg
  mov ax, ds
  mov si, offset VidMsg
  call PrintColoredLine

  pop ds
  pop si
  pop ax
  ret
PrintStringError endp

;------------------------------------------------------------------------------
; Вывести «Descriptor OK»
; (можно дописать вывод конкретных полей)
;------------------------------------------------------------------------------
PrintStringOK proc near
  push ax
  push si
  push ds

  mov ax, ds
  mov si, offset GoodMsg
  call PrintColoredLine

  pop ds
  pop si
  pop ax
  ret
PrintStringOK endp


;------------------------------------------------------------------------------
; Печать строки (DS:SI -> 0-terminated),
; ES=0B800h, BX=индекс дескриптора => цвет
; Учитываем CurRow/CurCol (25×80)
;------------------------------------------------------------------------------
PrintColoredLine proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di

PrintLoop:
  lodsb                    ; AL=очередной символ
  cmp al,0
  je Done

  ; Прочитаем CurRow->ax, CurCol->dx
  mov di, offset CurRow
  mov ax, [ds:di]
  mov di, offset CurCol
  mov dx, [ds:di]

  ; Если ax>=25 => не пишем
  cmp ax,25
  jae SkipWrite

  ; Если dx>=80 => перевод строки
  cmp dx,80
  jb WriteChar

NewLine:
  inc ax
  mov di, offset CurRow
  mov [ds:di], ax
  xor dx,dx
  mov di, offset CurCol
  mov [ds:di], dx

WriteChar:
  ; Высчитаем offset=(ax*80+dx)*2
  ; Умножение ax*80 => цикл
  mov cx,ax
  xor ax,ax
  mov bp,80
RowLoop:
  add ax,cx
  dec bp
  jnz RowLoop
  ; ax= cx*80
  add ax,dx
  add ax,ax   ; *2
  ; di=ax => адрес в видеопамяти
  mov di,ax

  ; AL=символ, цвет=(07h+BL)&0Fh
  push ax
  push bx
  mov ah,07h
  add ah,bl
  and ah,0Fh
  mov [es:di], ax
  pop bx
  pop ax

  ; CurCol++
  mov di, offset CurCol
  mov dx,[ds:di]
  inc dx
  mov [ds:di], dx

SkipWrite:
  jmp PrintLoop

Done:
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
PrintColoredLine endp

code ends
end start
