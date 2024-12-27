assume cs:code, ds:data

data segment

OrgGdtDesc  dw 0
            dw 0
            dw 0

OrgGdtSize  dw 0

PdeBase     dw 0
            dw 0
PteBase     dw 0
            dw 0

DescLimitLow      dw ?
DescBaseLow       dw ?
DescBaseMid       db ?
DescBaseHigh      db ?
DescAccess        db ?
DescLimitFlags    db ?
DescType          db ?

DescriptorBase32  dw 2 dup(?)
DescriptorLimit32 dw 2 dup(?)

TempByte1         db ?
TempByte2         db ?

GDTLabel dw 0FFFFh
         dw 0
         db 0
         db 0

         dw 0FFFFh
         dw 0
         db 10011010b
         db 11001111b

         dw 0FFFFh
         dw 0
         db 10010010b
         db 11001111b

         dw 1
         dw 2
         db 10010010b
         db 00000000b

         dw 2
         dw 1
         db 10011010b
         db 00000000b

AlignPDE  db 0
PDE       dw 1024 dup(0)

AlignPTE  db 0
PTE       dw 1024*2 dup(0)

VidMsg     db 'Некорректный дескриптор$',0
GoodMsg    db 'Descriptor OK$',0
MsgBase    db 'Base=',0
MsgLimit   db 'Limit=',0
MsgAccess  db 'Access byte=',0
MsgDPL     db 'DPL=',0
MsgType    db 'Type=',0

Hex0X      db '0x',0
CRLF       db 13,10,0
OneCharBuff db 2 dup(0)

Db32 db 'D/B=32-bit$',0
Db16 db 'D/B=16-bit$',0
AvlYes db 'AVL=1$',0
AvlNo  db 'AVL=0$',0
G0     db 'G=0 (byte granularity)$',0
G1Str  db 'G=1 (4KB granularity)$',0
CodeExec db ' (Code execute+read)$',0
DataRead db ' (Data read/write)$',0
UnknownType db ' (Unknown type)$',0

CurRow dw ?
CurCol dw ?

data ends

code segment
start:
  mov ax, data
  mov ds, ax
  mov ax, 3
  int 10h
  cli
  xor ax, ax
  mov ss, ax
  mov sp, 1000h
  mov bx, (5*8 - 1)
  mov si, offset OrgGdtSize
  mov [ds:si], bx
  mov si, offset OrgGdtSize
  mov ax, [ds:si]
  mov si, offset OrgGdtDesc
  mov [ds:si], ax
  mov bx, offset GDTLabel
  add si, 2
  mov [ds:si], bx
  mov bx, ds
  add si, 2
  mov [ds:si], bx
  db 0Fh, 01h, 16h
  dw OrgGdtDesc
  db 66h,0Fh,020h,0C0h
  db 66h,81h,0E0h,0FEh,0FFh,0FFh,0FFh
  db 66h,81h,0C8h,01h,0,0,0
  db 66h,0Fh,022h,0C0h
  db 0EAh
  dw StartPM
  dw 8

StartPM:
  mov ax,10h
  mov ds,ax
  mov es,ax
  mov ss,ax
  mov sp,2000h
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
  mov si, offset PDE
  mov cx, 1024
InitPDE:
  push cx
  mov dx,cx
  dec dx
  cmp dx,0
  jne FillZeroPde
  mov di, offset PteBase
  mov ax,[ds:di]
  mov dx,[ds:di+2]
  mov bp,12
ShiftPDEloop:
  clc
  rcr dx,1
  clc
  rcr ax,1
  dec bp
  jnz ShiftPDEloop
  mov [ds:si], ax
  add si,2
  mov [ds:si], dx
  add si,2
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
  mov si, offset PTE
  mov cx,1024
InitPTE:
  mov dx,cx
  dec dx
  cmp dx,2
  je VideoPage
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
  mov bp,12
ShiftRightPte:
  clc
  rcr dx,1
  clc
  rcr ax,1
  dec bp
  jnz ShiftRightPte
  mov [ds:si], ax
  add si,2
  mov [ds:si], dx
  add si,2
  sub si,4
  or word ptr [ds:si],3
  add si,4
  loop InitPTE
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
  db 66h,0Fh,020h,0C0h
  db 66h,81h,0C8h,0,0,0,80h
  db 66h,0Fh,022h,0C0h

NextStep:
  mov ax,0B800h
  mov es,ax
  xor ax,ax
  mov si, offset CurRow
  mov [ds:si], ax
  mov si, offset CurCol
  mov [ds:si], ax
  mov cx,5
  xor si,si
  xor bx,bx
ShowGDTLoop:
  push cx
  push si
  push bx
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

DecodeDescriptor proc near
  push ax
  push dx
  push bp
  push si
  push di
  mov bp, di
  mov ax,[ds:bp]
  mov si, offset DescLimitLow
  mov [ds:si], ax
  add bp,2
  mov ax,[ds:bp]
  mov si, offset DescBaseLow
  mov [ds:si], ax
  add bp,2
  mov al,[ds:bp]
  mov si, offset DescBaseMid
  mov [ds:si], al
  inc bp
  mov al,[ds:bp]
  mov si, offset DescAccess
  mov [ds:si], al
  inc bp
  mov al,[ds:bp]
  mov si, offset DescLimitFlags
  mov [ds:si], al
  inc bp
  mov al,[ds:bp]
  mov si, offset DescBaseHigh
  mov [ds:si], al
  mov si, offset DescAccess
  mov al,[ds:si]
  mov si, offset DescType
  mov [ds:si], al
  call MakeDescriptorBase
  call MakeDescriptorLimit
  mov si, offset DescAccess
  mov al,[ds:si]
  test al,10000000b
  jz MarkInvalid
  test al,00010000b
  jz MarkInvalid
  jmp OutputDesc

MarkInvalid:
  push bx
  call PrintStringError
  pop bx
  jmp DoneDecode

OutputDesc:
  push bx
  call PrintStringOK
  pop bx
  call PrintBaseField
  call PrintLimitField
  call PrintAttributes
DoneDecode:
  pop di
  pop si
  pop bp
  pop dx
  pop ax
  ret
DecodeDescriptor endp

MakeDescriptorBase proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  mov si, offset DescBaseLow
  mov ax,[ds:si]
  mov di, offset DescriptorBase32
  mov [ds:di], ax
  mov si, offset DescBaseMid
  xor ah,ah
  mov al,[ds:si]
  mov cx,16
ShiftMidBase:
  clc
  rcl ax,1
  dec cx
  jnz ShiftMidBase
  mov si, offset DescriptorBase32
  mov dx,[ds:si]
  add dx,ax
  mov [ds:si], dx
  mov si, offset DescBaseHigh
  xor ax,ax
  mov al,[ds:si]
  mov cx,24
ShiftHighBase:
  clc
  rcl ax,1
  dec cx
  jnz ShiftHighBase
  mov si, offset DescriptorBase32
  mov dx,[ds:si]
  add dx,ax
  mov [ds:si], dx
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
MakeDescriptorBase endp

MakeDescriptorLimit proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  mov si, offset DescLimitLow
  mov ax,[ds:si]
  mov di, offset DescriptorLimit32
  mov [ds:di], ax
  mov si, offset DescLimitFlags
  mov al,[ds:si]
  and al,0Fh
  mov cx,16
ShiftLimHigh:
  clc
  rcl ax,1
  dec cx
  jnz ShiftLimHigh
  mov si, offset DescriptorLimit32
  mov dx,[ds:si]
  add dx,ax
  mov [ds:si], dx
  mov si, offset DescLimitFlags
  mov al,[ds:si]
  and al,80h
  cmp al,0
  je LDone
  mov si, offset DescriptorLimit32
  mov dx,[ds:si]
  mov cx,12
ShiftLimit32:
  add dx,dx
  dec cx
  jnz ShiftLimit32
  mov bx,0FFFh
  add dx,bx
  mov si, offset DescriptorLimit32
  mov [ds:si], dx
LDone:
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
MakeDescriptorLimit endp

PrintBaseField proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  push ds
  mov ax, ds
  mov si, offset MsgBase
  call PrintColoredLine
  pop ds
  push ds
  mov ax, ds
  mov si, offset Hex0X
  call PrintColoredLine
  pop ds
  mov di, offset DescriptorBase32
  mov dx,[ds:di]
  call PrintHex16
  push ds
  mov ax, ds
  mov si, offset CRLF
  call PrintColoredLine
  pop ds
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
PrintBaseField endp

PrintLimitField proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  push ds
  mov ax, ds
  mov si, offset MsgLimit
  call PrintColoredLine
  pop ds
  push ds
  mov ax, ds
  mov si, offset Hex0X
  call PrintColoredLine
  pop ds
  mov di, offset DescriptorLimit32
  mov dx,[ds:di]
  call PrintHex16
  push ds
  mov ax, ds
  mov si, offset CRLF
  call PrintColoredLine
  pop ds
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
PrintLimitField endp

PrintAttributes proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  mov si, offset DescAccess
  mov al,[ds:si]
  push ds
  mov ax, ds
  mov si, offset MsgAccess
  call PrintColoredLine
  pop ds
  push ds
  mov ax, ds
  mov si, offset Hex0X
  call PrintColoredLine
  pop ds
  push ax
  call PrintHex8
  pop ax
  push ds
  mov ax, ds
  mov si, offset CRLF
  call PrintColoredLine
  pop ds
  mov cl,2
  mov bl,0
GetDpl:
  clc
  rcr al,1
  rcr bl,1
  dec cl
  jnz GetDpl
  push ds
  mov ax, ds
  mov si, offset MsgDPL
  call PrintColoredLine
  pop ds
  add bl,'0'
  push ax
  push bx
  call PrintChar
  pop bx
  pop ax
  push ds
  mov ax, ds
  mov si, offset CRLF
  call PrintColoredLine
  pop ds
  mov si, offset DescAccess
  mov al,[ds:si]
  mov dx,00001111b
  and ax,dx
  push ax
  call PrintTypeField
  pop ax
  mov si, offset DescLimitFlags
  mov al,[ds:si]
  mov dx,80h
  and al,dl
  cmp al,0
  je Gbit0
  push bx
  mov bl,1
  call PrintGbit
  pop bx
  jmp CheckDB
Gbit0:
  push bx
  xor bl,bl
  call PrintGbit
  pop bx
CheckDB:
  mov si, offset DescLimitFlags
  mov al,[ds:si]
  mov dx,01000000b
  and al,dl
  cmp al,0
  je is16
  push ds
  mov ax, ds
  mov si, offset Db32
  call PrintColoredLine
  pop ds
  jmp AvlCheck
is16:
  push ds
  mov ax, ds
  mov si, offset Db16
  call PrintColoredLine
  pop ds
AvlCheck:
  mov si, offset DescLimitFlags
  mov al,[ds:si]
  mov dx,00010000b
  and al,dl
  cmp al,0
  je Avl0
  push ds
  mov ax, ds
  mov si, offset AvlYes
  call PrintColoredLine
  pop ds
  jmp AttrDone
Avl0:
  push ds
  mov ax, ds
  mov si, offset AvlNo
  call PrintColoredLine
  pop ds
AttrDone:
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
PrintAttributes endp

PrintTypeField proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  push ds
  mov ax, ds
  mov si, offset MsgType
  call PrintColoredLine
  pop ds
  push ds
  mov ax, ds
  mov si, offset Hex0X
  call PrintColoredLine
  pop ds
  push ax
  call PrintHex8
  pop ax
  cmp al,0Ah
  jne NotA
  push ds
  mov ax, ds
  mov si, offset CodeExec
  call PrintColoredLine
  pop ds
  jmp TDone
NotA:
  cmp al,2
  jne No2
  push ds
  mov ax, ds
  mov si, offset DataRead
  call PrintColoredLine
  pop ds
  jmp TDone
No2:
  push ds
  mov ax, ds
  mov si, offset UnknownType
  call PrintColoredLine
  pop ds
TDone:
  push ds
  mov ax, ds
  mov si, offset CRLF
  call PrintColoredLine
  pop ds
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
PrintTypeField endp

PrintGbit proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  cmp bl,0
  jne G1
  push ds
  mov ax, ds
  mov si, offset G0
  call PrintColoredLine
  pop ds
  jmp Gdone
G1:
  push ds
  mov ax, ds
  mov si, offset G1Str
  call PrintColoredLine
  pop ds
Gdone:
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
PrintGbit endp

PrintChar proc near
  push si
  push ds
  push cx
  push dx
  push di
  mov si, offset OneCharBuff
  mov [ds:si], bl
  inc si
  mov byte ptr [ds:si],0
  mov si, offset OneCharBuff
  call PrintColoredLine
  pop di
  pop dx
  pop cx
  pop ds
  pop si
  ret
PrintChar endp

PrintHex16 proc near
  push ax
  push bx
  push cx
  push si
  push di
  mov bx, dx
  mov cx,4
NextNibble:
  mov ax,bx
  mov dx,0F000h
  and ax,dx
  mov si,12
ShiftRight12:
  clc
  rcr ax,1
  dec si
  jnz ShiftRight12
  add al,'0'
  cmp al,'9'
  jbe GoodDigit
  add al,('A' - '9' - 1)
GoodDigit:
  push ax
  call PrintChar
  pop ax
  mov si,4
ShiftLeft4:
  add bx,bx
  dec si
  jnz ShiftLeft4
  dec cx
  jnz NextNibble
  pop di
  pop si
  pop cx
  pop bx
  pop ax
  ret
PrintHex16 endp

PrintHex8 proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  mov ah,0
  mov bx, ax
  mov cx,2
NextNib:
  mov ax,bx
  mov dx,0F0h
  and ax,dx
  mov si,4
ShiftR4:
  clc
  rcr ax,1
  dec si
  jnz ShiftR4
  add al,'0'
  cmp al,'9'
  jbe GoodDig
  add al,('A' - '9' -1)
GoodDig:
  push ax
  call PrintChar
  pop ax
  mov si,4
ShLeft4:
  add bx,bx
  dec si
  jnz ShLeft4
  dec cx
  jnz NextNib
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
PrintHex8 endp

PrintColoredLine proc near
  push ax
  push bx
  push cx
  push dx
  push si
  push di
PrintLoop:
  lodsb
  cmp al,0
  je Done
  mov di, offset CurRow
  mov ax,[ds:di]
  mov di, offset CurCol
  mov dx,[ds:di]
  cmp ax,25
  jae SkipWrite
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
  mov cx, ax
  xor ax, ax
  mov bp,80
RowLoop:
  add ax, cx
  dec bp
  jnz RowLoop
  add ax, dx
  add ax, ax
  mov di, ax
  push ax
  push bx
  mov ah,07h
  add ah, bl
  and ah,0Fh
  mov [es:di], ax
  pop bx
  pop ax
  mov di, offset CurCol
  mov dx,[ds:di]
  inc dx
  mov [ds:di], dx
  jmp PrintLoop
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

PrintStringError proc near
  push ax
  push si
  push ds
  mov ax, ds
  mov si, offset VidMsg
  call PrintColoredLine
  pop ds
  pop si
  pop ax
  ret
PrintStringError endp

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

code ends
end start
