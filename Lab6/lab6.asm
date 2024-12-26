;------------------------------------------
; Имя файла: pm_gdt_pages.asm
; Скомпилировать в TASM:
;     tasm pm_gdt_pages.asm
;     tlink /3 pm_gdt_pages.obj
; Запустить из-под DOS (или DosBox).
;------------------------------------------

.286                     ; используем инструкции до 80286
.model  small           ; модель памяти small
.stack  256             ; маленький стек, нам много не надо

;------------------------------------------
; Сегменты, которые мы объявляем для TASM
;------------------------------------------
assume  cs:code, ds:data

data segment
; -----------------------------------------
; Здесь храним таблицу страниц, GDT и буферы
; -----------------------------------------

; ==== Сообщение (для отладки в реальном режиме, если захотите) ====
msg db "Start real-mode code...$", 0

; ----------------------------------------------------
; GDT (Global Descriptor Table)
; Каждая запись GDT — 8 байт
; Ниже пример с 6 дескрипторами.
; ----------------------------------------------------
GDT_LABEL:              ; метка начала GDT

; 0-й дескриптор (Null Descriptor) ---
gdt_null  dd 0
          dd 0

; 1-й дескриптор: Код-сегмент (base=0, limit=FFFFF при гранулярности 4К) ---
;   limit(0:15)    = 0FFFFh
;   base(0:15)     = 0
;   base(16:23)    = 0
;   access byte    = 9Ah (10011010b):
;       P=1 (присутствует),
;       DPL=00b (привилегия 0),
;       S=1 (код/данные),
;       Type=1010b (исполняемый, не конформный, доступен для чтения),
;   flags (G=1, D=1, 0=0, AVL=0) и limit(16:19) = 0Fh
;   итого Flags = 1100 (C=1, D=1, L=0, AVL=0 => 0xC) + (limit_high=F)
;   => 0CFh (1100 1111b)
gdt_code  dw 0FFFFh       ; limit low
          dw 0            ; base low
          db 0            ; base mid
          db 10011010b    ; access
          db 11001111b    ; limit high(4 bits) + flags(4 bits)
          db 0            ; base high

; 2-й дескриптор: Дата-сегмент (base=0, limit=FFFFF) ---
;   access = 92h (10010010b):
;       P=1, DPL=0, S=1, Type=0010b (доступен для чтения/записи), и т.д.
;   flags = 0CFh, аналогично коду
gdt_data  dw 0FFFFh
          dw 0
          db 0
          db 10010010b
          db 11001111b
          db 0

; 3-й дескриптор: Заглушка (покажем как выводится «неправильный» или другой) 
;   Здесь можно задать, например, нулевой limit и base, но Access сделать 0
;   чтобы дескриптор считался «неприсутствующим», и т.д.
gdt_stub1 dw 0
          dw 0
          db 0
          db 00000000b    ; не задан (или неправильно задан)
          db 00000000b
          db 0

; 4-й дескриптор: ещё одна «заглушка»
gdt_stub2 dw 1234h
          dw 5678h
          db 56h
          db 00000000b
          db 00000000b
          db 0

; 5-й дескриптор: пример «корректного» с ограниченным лимитом
;   Сделаем limit = 0x0FFF, base=0x20000, DPL=3, data read/write
gdt_stub3 dw 0FFFh         ; limit low
          dw 0x0000        ; base low
          db 020h          ; base mid
          db 10010011b     ; P=1, DPL=3, S=1, Type=0010b
          db 01000000b     ; limit high=0, G=1? (тогда 0FFFh -> 0FFFh<<12=0xFFF0 - условно)
          db 0             ; base high

; -----------------------------------------
GDT_END_LABEL:

GDT_SIZE  equ (GDT_END_LABEL - GDT_LABEL)  ; размер GDT в байтах
GDT_LIMIT equ (GDT_SIZE - 1)

; -----------------------------------------
; Структура pseudo-descriptor для загрузки регистров GDTR
; -----------------------------------------
gdt_descriptor:
  dw  GDT_LIMIT       ; Limit (размер таблицы - 1)
  dd  GDT_LABEL       ; Base (линейный адрес GDT)

; -----------------------------------------
; Таблица страниц: Page Directory (PDE) + Page Table (PTE)
; -----------------------------------------
; По заданию у нас 1024 PDE, каждый указывает на 4-КБлочные Page Table.
; Для простоты сделаем 1 PDE, указывающий на наш PT, а остальные — пустые;
; В PT — 1024 PTE. Для задания (чтобы показать идею) можно подменить
; физ.адрес страницы N*1000h на B8000h.
; Но для примера обычно берут страницу 0xB8 (т.к. 0xB8000 >> 12 = 0xB80),
; однако вы можете менять логику, исходя из условия.
; -----------------------------------------

PDE_COUNT  equ 1024
PTE_COUNT  equ 1024

page_directory  label dword
pd  dd PTE0 + 00000011b  ; PDE #0: Base=адрес pte, флаги P=1,R/W=1,U/S=0
     rept (PDE_COUNT-1)
       dd 0              ; остальные PDE = 0 (not present)
     endm

PTE0 label dword
pt0 dd 0                 ; мы инициализируем позже в коде
     rept (PTE_COUNT-1)
       dd 0
     endm

page_directory_end  label dword

; -----------------------------------------
; Псевдодескриптор для CR3 (каталог страниц)
; -----------------------------------------
pd_base equ page_directory

; -----------------------------------------
; Переменные для вывода в видео
; -----------------------------------------
CurrentLine dw 0   ; текущая строка при выводе
CurrentColor db 1  ; будем менять цвет для каждой строки

data ends

;------------------------------------------
; Сегмент кода
;------------------------------------------
code segment
start:
    mov ax, data
    mov ds, ax

    ;------------------------------------------------------------
    ; (1) Мини-вывод в реальном режиме (через int 21h) — опционально
    ;------------------------------------------------------------
    mov ah, 09h
    mov dx, offset msg
    int 21h

    ;------------------------------------------------------------
    ; (2) Подготовка GDT и включение защищённого режима
    ;------------------------------------------------------------
    cli                 ; запрет прерываний

    ; Загружаем регистр GDTR
    lgdt  [gdt_descriptor]

    ; Включаем PE-бит в CR0
    mov eax, cr0
    or  eax, 1
    mov cr0, eax

    ; Делаем короткий far jump, чтобы физически обновить CS
    ;   (Перейдём на метку ProtectedModeEntry)
    jmp  dword ptr 08h:ProtectedModeEntry  ; селектор 08h (gdt_code)

;------------------------------------------
; Код начинается уже в защищённом режиме
;------------------------------------------
ProtectedModeEntry:

    ; Инициализируем сегментные регистры для 32-битного кода
    mov ax, 10h     ; селектор data-сегмента (gdt_data)
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Установим стек (пока маленький, но для примера хватит)
    mov esp, 01000h

    ;------------------------------------------------------------
    ; (3) Инициализация таблицы страниц
    ;     По заданию надо сделать так, чтобы физ. адрес страницы
    ;     N*1000h  -> заменить на B8000h (видеопамять).
    ;     Для примера можно взять N=0xB8 (0xB8*1000h = 0xB8000)
    ;     Но Вы можете сделать логику по-своему.
    ;------------------------------------------------------------
    ; Заполним PTE так, чтобы первые 1024 страниц шли по стандарту:
    ;   PTE[i] = (i*1000h) + флаги (P=1, R/W=1).
    ; А PTE[B8h] = 0xB8000 + флаги.
    ;------------------------------------------------------------
    mov ebx, offset pt0
    xor edi, edi           ; i = 0
InitPTE_Loop:
    mov eax, edi           ; eax = i
    shl eax, 12            ; eax = i*1000h (т.е. i << 12)
    ; Признак присутствия + чт/зап (0...011b = 3)
    or  eax, 3
    ; Но если i == 0xB8, заменяем base на 0xB8000
    cmp edi, 0B8h
    jne short NotVideo
      and eax, 0FF000000h  ; обнулим верх на всякий случай
      mov eax, 0x0B8000 + 3
NotVideo:
    mov [ebx], eax
    add ebx, 4
    inc edi
    cmp edi, PTE_COUNT
    jb  InitPTE_Loop

    ; CR3 = pd_base
    mov eax, pd_base
    mov cr3, eax

    ; Теперь включим бит PG (paging) в CR0
    mov eax, cr0
    or  eax, 80000000h     ; устанавливаем PG=1
    mov cr0, eax

    ;------------------------------------------------------------
    ; (4) Теперь мы в защищённом режиме с включённым пэйджингом.
    ;     Обращение к адресу 0x00B8000 будет идти через PDE/PT
    ;     Но по заданию мы «привязываем» какую-то страницу к B8000h
    ;     и будем писать туда (через виртуальный адрес).
    ;     Для простоты оставим адрес видеопамяти тем же 0xB8000,
    ;     но фактически он теперь «виртуальный».
    ;------------------------------------------------------------

    ; Очистим экран (25 строк по 80 символов) — заполним пробелами
    call ClearScreen

    ;------------------------------------------------------------
    ; (5) Обход всех дескрипторов GDT, вывод информации
    ;     У нас в GDT 6 дескрипторов. Если нужно больше — увеличить.
    ;------------------------------------------------------------
    xor ecx, ecx      ; ecx будет индекс дескриптора: 0..5
ShowGDTLoop:
    cmp ecx, 6
    jae  DoneShowGDT      ; выходим, если больше нет

    push ecx
    call PrintDescriptor  ; вывести данные о дескрипторе ecx
    pop ecx

    inc ecx
    jmp short ShowGDTLoop

DoneShowGDT:

    ;------------------------------------------------------------
    ; (6) Вечный цикл
    ;------------------------------------------------------------
    jmp $

;====================================================================
; Процедура: PrintDescriptor
;   Вход: ecx = индекс дескриптора (0..5)
;====================================================================
PrintDescriptor proc near
    pushad

    ; Адрес дескриптора = GDT_LABEL + ecx*8
    mov eax, ecx
    shl eax, 3                  ; eax = ecx * 8
    add eax, GDT_LABEL
    mov esi, eax                ; esi указывает на начало дескриптора

    ; Считаем 8 байт дескриптора
    mov ax, [esi]               ; limit (low 16 bits)
    mov bx, [esi+2]             ; base (low 16 bits)
    mov cx, [esi+4]             ; (cx = byte4: base mid (low8) + access(byte5 high8??)
                                ; но аккуратно: [esi+4] = base mid(8 bits) + access(8 bits)
    mov dx, [esi+6]             ; (dx = byte6 + byte7)
    ; В TASM считывать покусочно удобнее db, но здесь для примера так.

    ; Разберём поля:
    ; limit_low  = AX
    ; base_low   = BX
    ; base_mid   = (CX & 0x00FF)
    ; access     = (CX >> 8) & 0x00FF
    ; limit_high = (DX & 0x000F)
    ; flags      = (DX & 0x00F0) >> 4
    ; base_high  = (DX >> 8) & 0x00FF

    ; Сохраним в регистры/переменные:
    mov edi, eax ; временно

    ; Вычислим Base (полный 32-бит):
    ; base = base_low(16) + base_mid(8) << 16 + base_high(8) << 24
    ; Удобнее сделать это на «C-подобном» языке,
    ; но раз уж ассемблер:
    ;   EAX = base_low + (base_mid << 16) + (base_high << 24)
    mov ax, bx          ; base_low
    mov ebx, 0
    mov bx, cx
    and bx, 0FFh        ; base_mid
    shl ebx, 16         ; EBX = base_mid<<16
    mov bl, dh          ; base_high = DX>>8
    ; EBX = base_mid<<16 + base_high (низ 8 бит)
    shl ebx, 8          ; EBX <<= 8
    ; Теперь EAX = base_low, EBX содержит mid/high
    movzx edx, ax       ; EDX = base_low (16-bit -> 32-bit)
    or  ebx, edx
    mov eax, ebx        ; EAX = полный Base

    push eax            ; сохраним base

    ; Вычислим Limit:
    ; limit = limit_low + (limit_high << 16)
    ; а если флаг G=1, то реальный limit = limit<<12 (по 4К)
    mov ax, word ptr [esi]     ; limit_low
    mov bx, word ptr [esi+6]   ; bx = DX, но аккуратно
    and bx, 0Fh                ; limit_high (4 бита)
    shl bx, 16
    movzx edx, ax
    or  edx, ebx               ; EDX = limit (без учёта гранулярности)

    ; Проверим флаг G (bit7 of flags)
    mov ax, word ptr [esi+6]
    shr ax, 12         ; флаги = DX >> 4 (т.к. DX & 0xF0 => shift 4)
    and ax, 0Fh        ; оставить младшие 4 бита флага
    ; bit3 = G, bit2 = D, bit1=0?, bit0=AVL
    ; G=1 => умножаем limit на 4096
    bt  ax, 3
    jc  short L_gran_4k
    jnc short L_no_gran

L_gran_4k:
    shl edx, 12
L_no_gran:

    push edx   ; сохраним limit

    ; Достаём access byte
    ; access = (CX >> 8)
    mov ax, cx
    shr ax, 8
    mov bx, ax
    ; access byte:
    ;  P(1) DPL(2) S(1) Type(4)
    ;  Прочие биты: если P=0, дескриптор невалиден
    ;  Проверим P
    bt  bx, 7      ; P = bit7
    jc short desc_valid
    ; если P=0, то считаем некорректным — выведем «Invalid descriptor»
    jmp short print_invalid_desc

desc_valid:
    ; Выведем:
    ; "Desc X: BASE=..., LIMIT=..., Type=..., DPL=..., Code/Data, RW=..., etc."
    ; Для демонстрации выведем всё короче (в одной строке).
    call PrintStringHeader

    ; Распечатаем индекс
    mov eax, ecx  ; ecx = индекс дескриптора
    call PrintNumber32h

    ; BASE
    call PrintSpace
    call PrintStringBase
    pop edx        ; наш сохранённый limit (мы пушили limit последним, значит снимаем stack в обратном порядке)
    pop eax        ; base
    call PrintHex32 ; распечатать base
    ; вернём limit в стеке
    push edx

    ; LIMIT
    call PrintSpace
    call PrintStringLimit
    pop edx
    call PrintHex32
    ; всё, теперь стек чист

    ; Type/Attributes
    call PrintSpace
    call PrintStringType
    mov ax, bx    ; в ax хранится access
    call PrintHex16

    ; Flags
    call PrintSpace
    call PrintStringFlags
    mov ax, word ptr [esi+6]
    call PrintHex16

    ; Следующая строка
    call NextLine
    jmp short done_print

print_invalid_desc:
    ; Выведем: "Desc X: Invalid descriptor"
    call PrintStringHeader
    mov eax, ecx
    call PrintNumber32h
    call PrintSpace
    call PrintStringInvalid
    call NextLine

done_print:
    popad
    ret
PrintDescriptor endp

;====================================================================
; Вспомогательные «процедуры» вывода
;====================================================================

;--------------------------------------------------------------------
; PrintStringHeader: "Desc "
;--------------------------------------------------------------------
PrintStringHeader proc near
    pushad
    mov si, offset desc_header
.nextc:
    lodsb
    or  al, al
    jz .done
    call PutChar
    jmp .nextc
.done:
    popad
    ret
PrintStringHeader endp

desc_header db "Desc ",0

;--------------------------------------------------------------------
; PrintStringInvalid: "Invalid descriptor"
;--------------------------------------------------------------------
PrintStringInvalid proc near
    pushad
    mov si, offset invalid_text
.nextc:
    lodsb
    or  al, al
    jz .done
    call PutChar
    jmp .nextc
.done:
    popad
    ret
PrintStringInvalid endp

invalid_text db "Invalid descriptor",0

;--------------------------------------------------------------------
; PrintStringBase: "BASE="
;--------------------------------------------------------------------
PrintStringBase proc near
    pushad
    mov si, offset base_text
.nextc:
    lodsb
    or  al, al
    jz .done
    call PutChar
    jmp .nextc
.done:
    popad
    ret
PrintStringBase endp

base_text db "BASE=",0

;--------------------------------------------------------------------
; PrintStringLimit: "LIMIT="
;--------------------------------------------------------------------
PrintStringLimit proc near
    pushad
    mov si, offset limit_text
.nextc:
    lodsb
    or  al, al
    jz .done
    call PutChar
    jmp .nextc
.done:
    popad
    ret
PrintStringLimit endp

limit_text db "LIMIT=",0

;--------------------------------------------------------------------
; PrintStringType: "TYPE="
;--------------------------------------------------------------------
PrintStringType proc near
    pushad
    mov si, offset type_text
.nextc:
    lodsb
    or  al, al
    jz .done
    call PutChar
    jmp .nextc
.done:
    popad
    ret
PrintStringType endp

type_text db "TYPE=",0

;--------------------------------------------------------------------
; PrintStringFlags: "FLAGS="
;--------------------------------------------------------------------
PrintStringFlags proc near
    pushad
    mov si, offset flags_text
.nextc:
    lodsb
    or  al, al
    jz .done
    call PutChar
    jmp .nextc
.done:
    popad
    ret
PrintStringFlags endp

flags_text db "FLAGS=",0

;--------------------------------------------------------------------
; PrintSpace: вывод пробела
;--------------------------------------------------------------------
PrintSpace proc near
    pushad
    mov al, ' '
    call PutChar
    popad
    ret
PrintSpace endp

;--------------------------------------------------------------------
; NextLine: переход на новую строку
;--------------------------------------------------------------------
NextLine proc near
    pushad
    inc CurrentLine
    ; Если строк уже 25, начнём заново (для простоты)
    cmp CurrentLine, 25
    jb .ok
    mov CurrentLine, 0
    ; цвет тоже меняем
    inc CurrentColor
    and CurrentColor, 0Fh
.ok:
    popad
    ret
NextLine endp

;--------------------------------------------------------------------
; PrintNumber32h: печатает число EAX в hex (8 символов)
;--------------------------------------------------------------------
PrintNumber32h proc near
    pushad
    mov ebx, eax   ; EBX = число для вывода
    mov ecx, 8     ; 8 hex digits
.hex_loop:
    mov eax, ebx
    shl ebx, 4
    shr eax, 28    ; берём старшие 4 бита
    and eax, 0Fh
    cmp eax, 10
    jl .digit
    add eax, 'A' - 10
    jmp .store
.digit:
    add eax, '0'
.store:
    mov al, byte ptr [eax]
    call PutChar
    loop .hex_loop
    popad
    ret
PrintNumber32h endp

;--------------------------------------------------------------------
; PrintHex16: печатает AX в hex (4 символа)
;--------------------------------------------------------------------
PrintHex16 proc near
    pushad
    mov bx, ax
    mov cx, 4
.hex_loop:
    mov ax, bx
    shl bx, 4
    shr ax, 12
    and ax, 0Fh
    cmp ax, 10
    jl .digit
    add ax, 'A' - 10
    jmp .store
.digit:
    add ax, '0'
.store:
    mov al, byte ptr [ax]
    call PutChar
    loop .hex_loop
    popad
    ret
PrintHex16 endp

;--------------------------------------------------------------------
; PutChar: вывод символа AL в текущую позицию экрана
;--------------------------------------------------------------------
PutChar proc near
    pushad
    ; Координаты:
    ;   CurrentLine (0..24), но колонку будем считать глобально.
    ;   Для упрощения здесь «самопальный» счётчик столбцов не ведём;
    ;   можно выводить подряд как текстовую строку 80 символов.
    ; Адрес видеопамяти (текстовый режим 80x25) = B8000h,
    ; но мы уже «спроецировали» его через пэйджинг.
    ; Виртуальный адрес тот же, 0xB8000.
    ; Считаем, что у нас есть глобальный «текущий_символьный_индекс».
    ; Или просто всегда пишем в конец текущей строки…
    ; Для наглядности сделаем, что символы кладём подряд.
    ;
    ;   offset = (CurrentLine*80 + X) * 2
    ;   где X мы будем накапливать в statics. Но здесь упрощённо:
    ;   мы всегда добавляем +2 после каждого символа.
    ;
    ; Чтобы не усложнять пример, будет простая глобальная переменная
    ; screen_ofs — офсет от начала B8000h. Когда доходим до конца
    ; строки (80 символов), делаем NextLine, обнуляем локально.
    ;
    ; Но в задаче сказано «Информацию по каждому *следующему* дескриптору писать другим цветом».  
    ; Мы это сделали через CurrentColor, инкрементируем при NextLine.
    ;
    ; Для упрощения: будем считать, что каждый дескриптор занимает
    ; одну строку. То есть, как только выводим NextLine, цвет новый.
    ;
    ; Итого: расчёт адреса:
    ;   row = CurrentLine
    ;   col = не храним, просто глобально «screen_ofs».
    ;
    ;   phys_addr = 0xB8000 + row*80*2 + screen_ofs.
    ;
    ; Для упрощения в таком учебном примере можно просто «добавлять +2»
    ; на каждый символ, и обнулять при переходе на новую строку.
    ;
    ; Здесь сделаем так:
    ;   Если мы видим, что символов вышло за 80, следующая печать пойдёт
    ;   на новую строку. (Логику можно доработать при желании).
    ;
    ; Для наглядности — статическая переменная:
    ;
    staticOfs label word
    staticOfs dw 0

    ; Возьмём row из CurrentLine
    mov dx, CurrentLine
    mov bx, 80        ; кол-во символов в строке
    mul bx            ; dx:ax = dx*bx
    shl ax, 1         ; умножаем на 2, потому что 2 байта на символ
    ; AX = offset начала этой строки

    ; Прибавим staticOfs
    add ax, [staticOfs]

    ; Запишем символ AL
    mov bx, 0B8000h
    ; DS уже у нас = data, но нам нужно именно доступ по линейному адресу,
    ; который за счёт paging отразится на видеопамять.
    ; В 32-битном режиме можем использовать «flat» доступ, но раз у нас
    ; модель small, мы делаем вид, что seg = DS = чего-то.  
    ; Важно, что физически CR3 «подменяет».
    ;
    ; Запишем AL, и цвет (CurrentColor).
    mov es, bx
    mov di, ax
    mov [es:di], al
    inc di
    mov al, CurrentColor
    mov [es:di], al

    ; сдвигаем staticOfs на 2 (следующий символ)
    add [staticOfs], 2
    ; если превысило 80 символов => следующая строка
    cmp [staticOfs], 160
    jb .done
    ; иначе перенос
    mov [staticOfs], 0
    inc CurrentLine
    cmp CurrentLine, 25
    jb .done
    mov CurrentLine, 0
    inc CurrentColor
    and CurrentColor, 0Fh
.done:
    popad
    ret
PutChar endp

;--------------------------------------------------------------------
; ClearScreen: очистка экрана 80x25
;--------------------------------------------------------------------
ClearScreen proc near
    pushad
    mov ax, 0B800h
    mov es, ax
    xor di, di
    mov cx, 80*25
    mov al, ' '
    mov ah, 07h   ; цвет по умолчанию (серый на чёрном)
.fill_loop:
    mov [es:di], al
    inc di
    mov [es:di], ah
    inc di
    loop .fill_loop

    ; сбросим параметры
    mov CurrentLine, 0
    mov CurrentColor, 1
    mov word ptr staticOfs, 0
    popad
    ret
ClearScreen endp

;------------------------------------------
; Завершение сегмента
;------------------------------------------
code ends

end start
