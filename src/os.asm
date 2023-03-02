
%include "./include/seg.inc"
%include "./include/gate.inc"
%include "./include/page.inc"
%include "./include/ARDS.inc"

org 0x100   ; 兼容FreeDOS ;留0x100的栈空间，以免栈溢出 [0x10010]
jmp start
;====================================================================================================
task_addr  equ 0x400000    ; 0000000001 0000000000 000000000000(PDE=1, PTE=0, offset=0)
;====================================================================================================
[section .IDT] ; IDT 段
align 32
IDT_base:
    %rep 32
            GEN_GATE G_code, other_handler, 0, GDA_IGate
    %endrep
    .020h:  GEN_GATE G_code, clock_handler, 0, GDA_IGate
    %rep 95
            GEN_GATE G_code, other_handler, 0, GDA_IGate
    %endrep
    .080h:  GEN_GATE G_code,  user_handler, 0, GDA_IGate
IDT_len         equ    $ - IDT_base - 1
IDTR:
    .limit      dw IDT_len     ; IDT 段界限
    .base:      dd 0           ; IDT 基地址
saved_IDTR:     dd 0, 0        ; 保存原先的 IDTR
;====================================================================================================
[section .GDT] ; GDT 段
align 32
GDT_base:
    _G_null:            dw 0, 0, 0, 0                                   ; GDT的开头是8个字节的空值
    G_null              equ _G_null - GDT_base
    _G_code16:          GEN_SEG 0, 0xffff, (SDA_X)                      ; 16位代码段(用于返回实模式)
    G_code16            equ _G_code16 - GDT_base
    _G_code:            GEN_SEG 0, code_len,  (SDA_RX | SDA_32)         ; 32位代码段
    G_code              equ _G_code - GDT_base
    _G_stack:           GEN_SEG 0, stack_top, (SDA_RW | SDA_32)         ; 32位堆栈段
    G_stack             equ _G_stack - GDT_base
    _G_data:            GEN_SEG 0, data_len,  (SDA_RW)                  ; 数据段(用于存储变量)
    G_data              equ _G_data - GDT_base
    _G_video:           GEN_SEG 0xB8000, 0xffff, (SDA_RW | SDA_DPL3)    ; 视频段(用于显示字符串)
    G_video             equ _G_video - GDT_base
    _flat_code:         GEN_SEG 0, 0xfffff, (SDA_RX | SDA_32 | SDA_4K | SDA_DPL3)  ; 虚拟地址空间的代码段(4G)
    flat_code           equ _flat_code - GDT_base
    _flat_data:         GEN_SEG 0, 0xfffff, (SDA_RW | SDA_32 | SDA_4K | SDA_DPL3)  ; 虚拟地址空间的数据段(4G)
    flat_data           equ _flat_data - GDT_base
    _LDT0:              GEN_SEG 0, LDT0_len, SDA_LDT                    ; LDT0
    LDT0                equ _LDT0 - GDT_base
    _LDT1:              GEN_SEG 0, LDT1_len, SDA_LDT                    ; LDT1
    LDT1                equ _LDT1 - GDT_base
    _LDT2:              GEN_SEG 0, LDT2_len, SDA_LDT                    ; LDT2
    LDT2                equ _LDT2 - GDT_base
    _LDT3:              GEN_SEG 0, LDT3_len, SDA_LDT                    ; LDT3
    LDT3                equ _LDT3 - GDT_base
    _TSS0:              GEN_SEG 0, TSS0_len, SDA_TSS                    ; TSS0
    TSS0                equ _TSS0 - GDT_base
    _TSS1:              GEN_SEG 0, TSS1_len, SDA_TSS                    ; TSS1
    TSS1                equ _TSS1 - GDT_base
    _TSS2:              GEN_SEG 0, TSS2_len, SDA_TSS                    ; TSS2
    TSS2                equ _TSS2 - GDT_base
    _TSS3:              GEN_SEG 0, TSS3_len, SDA_TSS                    ; TSS3
    TSS3                equ _TSS3 - GDT_base
GDT_len         equ $ - GDT_base - 1
GDTR:  
    .limit      dw GDT_len      ; GDT 段界限
    .base:      dd 0            ; GDT 基地址
saved_GDTR:     dd 0, 0         ; 保存原先的 GDTR
;====================================================================================================
[section .stack] ; 堆栈段
align 32
[bits 32]
stack_base:  db 512 dup 0
stack_top    equ    $ - stack_base - 1
;====================================================================================================
[section .real_mode] ; 实模式下的代码段
align 32
[bits 16]
start:
    ; 初始化段寄存器
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov [saved_sp], sp                  ; 保存栈指针
    mov sp, 0x100                       ; 初始化栈指针
    mov [jmp_ret_real_mode + 3], ax     ; 保存实模式下的 cs
    call get_ram_size                   ; 获取内存大小
    call get_cursor_pos                 ; 获取光标位置
    ; 将 addr_base 加载到 Segment Descriptor 中
    Load_Base code16_base, _G_code16
    Load_Base code_base, _G_code
    Load_Base stack_base, _G_stack
    Load_Base data_base, _G_data
    Load_Base LDT0_base, _LDT0
    Load_Base LDT1_base, _LDT1
    Load_Base LDT2_base, _LDT2
    Load_Base LDT3_base, _LDT3
    Load_Base TSS0_base, _TSS0
    Load_Base TSS1_base, _TSS1    
    Load_Base TSS2_base, _TSS2
    Load_Base TSS3_base, _TSS3
    Load_Base L0_code_base, _L0_code
    Load_Base L0_stack_base, _L0_stack
    Load_Base L0_stack_0_base , _L0_stack_0
    Load_Base L1_code_base, _L1_code
    Load_Base L1_stack_base, _L1_stack
    Load_Base L1_stack_0_base , _L1_stack_0
    Load_Base L2_code_base, _L2_code
    Load_Base L2_stack_base, _L2_stack
    Load_Base L2_stack_0_base , _L2_stack_0
    Load_Base L3_code_base, _L3_code
    Load_Base L3_stack_base, _L3_stack
    Load_Base L3_stack_0_base , _L3_stack_0
    ; load GDTR
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, GDT_base
    mov  [GDTR.base], eax               ; 将 GDT_base 基址加载到 GDTR 中
    sgdt [saved_GDTR]                   ; 保存原本的 GDTR
    lgdt [GDTR]                         ; 将新的 GDTR 加载到 GDTR 中
    ; load IDTR
    xor eax, eax
    mov ax, ds
    shl eax, 4
    add eax, IDT_base
    mov  [IDTR.base], eax               ; 将 IDT_base 基址加载到 IDTR 中
    sidt [saved_IDTR]                   ; 保存原本的 IDTR
    lidt [IDTR]                         ; 将新的 GDTR 加载到 GDTR 中
    ; 关中断
    cli
    ; 打开地址线 A20
    in al, 0x92
    or al, 00000010b
    out 0x92, al
    ; 开启保护模式
    mov eax, cr0
    or eax, 1                           ; cr0 寄存器的 PE 位置 在 0 位, 置 1
    mov cr0, eax                        ; cr0 寄存器的 PE 位置 1 , 开启保护模式
    ; 进入保护模式
    jmp dword G_code:code_start       ; cs:ip<-G_code:code_start
;====================================================================================================
get_cursor_pos:                         ; 获取光标位置
    pushad                              ; 保存寄存器
    mov ah, 3       
    mov bh, 0
    int 0x10                            ; 获取光标位置 (行:dh, 列:dl)
    mov al, dh                          ; al = dh = 行
    mov bl, 80
    mul bl                              ; ax = 行 * 80
    and dx, 0xff                        ; dx = dl = 列
    add ax, dx                          ; ax = 行 * 80 + 列
    and eax, 0xffff                     ; eax = ax = pos_cursor
    shl eax, 1                          ; eax = pos_cursor * 2(两个字节一个字符)
    mov [_pos_cursor], eax
    popad                               ; 恢复寄存器
    ret
;====================================================================================================
header_str:     db "  | BaseAddrLow  | BaseAddrHigh |  LengthLow   |  LengthHigh  |     Type     |", 0dh, 0ah, 0
;                  "  |  0x00000000  |  0x00000000  |  0x00000000  |  0x00000000  |  0x00000000  |  "
split_line:     db "  |  ", 0
_0x_str:        db "0x", 0
hex_digit:      db "0123456789ABCDEF", 0
ram_size_str:   db "RAM size: ", 0
ARDS_buffer:    db ARDS.size dup (0)
get_ram_size:                           ; 获取内存大小
    pushad                              ; 保存寄存器
    mov si, header_str
    call .print_str                     ; 打印表头
    xor ebx, ebx                        ; ebx = 0 
    mov di, ARDS_buffer                 ; di = ARDS_buffer
    
    .loop1:
        mov eax, 0x0000E820
        mov ecx, ARDS.size
        mov edx, 0x534D4150             ; edx = "SMAP"
        int 0x15                        ; 获取 ARDS, bx = 下一个 ARDS 的索引
        jc get_ARDS_error               ; 如果 CF = 1, 则获取 ARDS 失败
        call .calc_ram_size             ; 统计并打印这段内存大小
        cmp ebx, 0                      ; 如果 bx = 0, 则没有下一段 ARDS 了
        jne .loop1                      ; 如果 bx != 0, 则继续获取下一段 ARDS
        jmp .end
    .end:
        mov si, ram_size_str
        call .print_str                 ; 打印 "RAM size: "
        mov eax, [_ram_size]
        call .print_eax                 ; 打印内存大小
    
    ; 计算 PDE_num 和 PTE_num
    mov eax, [_ram_size]
    xor edx, edx
    mov ebx, 0x400000                   ; 一个页目录表项可以映射 4MB 的内存空间
    div ebx                             ; eax = ram_size / 4MB ; edx = ram_size % 4MB
    test edx, edx                       
    jz .4MB_aligned                     ; 如果 edx = 0, 则内存大小为 4MB 的整数倍
    inc eax                             ; 如果 edx != 0, 则内存大小不是 4MB 的整数倍, 则需要多一个页目录表项
    .4MB_aligned:
    mov [_PDE_num], eax                 ; 保存页目录表项数
    shl eax, 10                         ; eax = 页目录表项数 * 1024 (一个页表有 1024 个页表项)
    mov [_PTE_num], eax                 ; 保存页表项数
    popad                               ; 恢复寄存器
    ret
;====================================================================================================
.calc_ram_size:                         ; 计算内存大小
    push esi
    push eax
    push ebx
    mov eax, [ARDS_buffer + ARDS.BaseAddrLow]
    mov si, split_line
    call .print_str                     ; 打印分隔线
    call .print_eax                     ; 打印 BaseAddrLow
    mov eax, [ARDS_buffer + ARDS.BaseAddrHigh]
    call .print_str                     ; 打印分隔线
    call .print_eax                     ; 打印 BaseAddrHigh
    mov eax, [ARDS_buffer + ARDS.LengthLow]
    call .print_str                     ; 打印分隔线
    call .print_eax                     ; 打印 LengthLow
    mov eax, [ARDS_buffer + ARDS.LengthHigh]
    call .print_str                     ; 打印分隔线
    call .print_eax                     ; 打印 LengthHigh
    mov eax, [ARDS_buffer + ARDS.Type]
    call .print_str                     ; 打印分隔线
    call .print_eax                     ; 打印 Type
    call .print_str                     ; 打印分隔线
    mov eax, [ARDS_buffer + ARDS.Type]
    cmp eax, 1                          ; Type = 1 表示可用内存
    jne  .calc_ram_size_end
.calc_max_ram_size:
    mov eax, dword [ARDS_buffer + ARDS.BaseAddrLow] ; eax = BaseAddrLow
    mov ebx, dword [ARDS_buffer + ARDS.LengthLow] ; ebx = LengthLow
    add eax, ebx                        ; eax = BaseAddrLow + LengthLow = 这一段内存的末地址
    cmp eax, [_ram_size]
    jbe .calc_ram_size_end
    mov dword [_ram_size], eax          ; ram_size = max(ram_size, BaseAddrLow + LengthLow)
.calc_ram_size_end:
    pop ebx
    pop eax
    pop esi
    ret
;====================================================================================================
.print_eax:                             ; 打印 eax
    push si
    push eax
    mov si, _0x_str
    call .print_str                     ; 打印 "0x"
    mov eax, [esp]
    shr eax, 16
    call .print_ax                      ; 打印高 16 位
    mov eax, [esp]
    call .print_ax                      ; 打印低 16 位
    pop eax
    pop si
    ret
.print_ax:
    push ax
    mov ax, [esp]
    shr ax, 12
    call .print_a_hex
    mov ax, [esp]
    shr ax, 8
    call .print_a_hex
    mov ax, [esp]
    shr ax, 4
    call .print_a_hex
    mov ax, [esp]
    call .print_a_hex
    pop ax
    ret
.print_a_hex:
    push ax
    and eax, 0xf
    mov al, [hex_digit + eax]
    mov ah, 0x0e
    mov bx, 15
    int 0x10
    pop ax
    ret
;====================================================================================================
; si = str_addr
.print_str:                             ; 打印字符串            
    push si                             ; 保存寄存器
    push ax                             
    push bx
    .loop3:
        mov al, [si]                    ; al = 字符串内容
        cmp al, 0                       ; 比较al和0
        je end                          ; 相等则跳转到end
        mov ah, 0x0e                    ; 显示一个文字
        mov bx, 15                      ; 指定字符颜色(黑底白字)
        int 0x10                        ; 调用显卡BIOS
        inc si                          ; si 自增
        jmp .loop3                      ; 跳转到 .loop3
    end:
        pop bx                          ; 恢复寄存器
        pop ax
        pop si
        ret
;====================================================================================================
memory_error_str: db "Get ARDS Error!", 0dh, 0ah, 0
get_ARDS_error:                         ; 获取 ARDS 失败
    mov   si, memory_error_str
    .loop1:
        mov   al, [si]
        inc   si
        cmp   al, 0
        jz    .end

        mov   ah, 0x0e                  ; 显示一个文字
        mov   bx, 15                    ; 指定字符颜色
        int   0x10                      ; 调用显卡BIOS
        jmp   .loop1
    .end:
        mov ax, 0x4c00
        int    0x21
;====================================================================================================
saved_sp: dd 0
ret_real_mode:                          ; 从保护模式跳回到实模式就到了这里
    ; 实模式下只有一个段, 所以 cs = ds = es = ss
    mov ax, cs
    mov ds, ax                          ; 恢复数据段
    mov es, ax                          ; 恢复附加段
    mov ss, ax                          ; 恢复堆栈段
    mov sp, [saved_sp]                  ; 恢复栈指针
    lidt [saved_IDTR]                   ; 恢复 IDTR
    lgdt [saved_GDTR]                   ; 恢复 GDTR
    in  al, 0x92                        ; 关闭 A20 地址线
    and al, 11111101b
    out 0x92, al
    sti                                 ; 开中断    
    mov ax, 0x4c00                      ; 回到 DOS
    int 0x21
;====================================================================================================
[SECTION .data] ; 数据段
align 32
[bits 32]
data_base:
    _pos_cursor:        dd  0                               ; 光标位置
    pos_cursor          equ _pos_cursor - data_base
    _hex_str:           db  "0123456789ABCDEF", 0           ; 十六进制字符串
    hex_str             equ _hex_str - data_base
    _in_protect_str:    db  "In Protect Mode now. ^-^", 0   ; 进入保护模式后显示此字符串
    in_protect_str      equ _in_protect_str - data_base
    _ram_size           dd  0                               ; 内存大小
    ram_size            equ _ram_size - data_base
    _PDE_num            dd  0                               ; PDE 个数
    PDE_num             equ _PDE_num - data_base
    _PTE_num            dd  0                               ; PTE 个数
    PTE_num             equ _PTE_num - data_base
    _current_tick       dd  0                               ; 当前 tick
    current_tick        equ _current_tick - data_base
    _current_task       dd  0                               ; 当前任务
    current_task        equ _current_task - data_base
    _task_priority      dd  16, 10, 8, 6, 0                 ; 任务优先级
    task_priority       equ _task_priority - data_base
    _task_num           dd  4                               ; 任务个数
    task_num            equ _task_num - data_base
    _task_is_finished   dd  0, 0, 0, 0, 0, 0                ; 任务是否结束
    task_is_finished    equ _task_is_finished - data_base
data_len    equ    $ - data_base - 1
;====================================================================================================
[section .code]
align 32
[bits 32]
code_base:
;====================================================================================================
%include "./include/lib.inc"
;====================================================================================================
code_start equ $ - code_base
    xchg bx, bx                         ; magic breakpoint (bochs only)
    mov ax, G_video  
    mov gs, ax                          ; 初始化 gs = G_video
    mov ax, G_data
    mov ds, ax                          ; 初始化 ds = G_data
    mov ax, G_stack
    mov ss, ax                          ; 初始化 ss = G_stack
    mov esp, stack_top                  ; 初始化 esp = stack_top
    mov edi, [pos_cursor]               ; 初始化 edi = pos_cursor

    call print_enter                    ; 计算光标下一行的位置
    mov eax, in_protect_str 
    call print_str                      ; 打印 "In Protect Mode now. ^-^"
    call print_enter                    ; 计算光标下一行的位置

    init_Page L0_PDT_base, L0_PET_base  ; 初始化页表
    init_Page L1_PDT_base, L1_PET_base  ; 初始化页表
    init_Page L2_PDT_base, L2_PET_base  ; 初始化页表
    init_Page L3_PDT_base, L3_PET_base  ; 初始化页表
    ; 将 task 的代码加载到内存中 , 并在页表中建立映射
    Load_function LDT0, L0_code, task0_offset, task0_len, task0_base, L0_PDT_base 
    Load_function LDT1, L1_code, task1_offset, task1_len, task1_base, L1_PDT_base 
    Load_function LDT2, L2_code, task2_offset, task2_len, task2_base, L2_PDT_base 
    Load_function LDT3, L3_code, task3_offset, task3_len, task3_base, L3_PDT_base 

    int 80h                             ; 中断使用测试 , 显示'0' 
    call init_8259A                     ; 初始化 8259A
    sti                                 ; 需要开中断才能使用时钟中断

    mov eax, L0_PDT_base
    mov cr3, eax                        ; cr3 寄存器的值为页目录表的基地址
    mov eax, cr0
    or eax, 0x80000000                  ; cr0 寄存器的 PG 位置 在 31 位, 置 1
    mov cr0, eax                        ; cr0 寄存器的 PG 位置 1 , 开启分页机制
    
    mov ax, G_data
    mov ds, ax                          ; ds = G_data
    mov dword [current_task], 0         ; 当前任务为 0
    mov eax, [task_priority + 0 * 4]    ; eax = 16
    mov dword [current_tick], eax       ; 当前 tick 为 16
    jmp TSS0:0
    
    jmp $

    jmp G_code16:0
;====================================================================================================
init_8259A:
	mov	al, 011h
	out	020h, al	                    ; 主8259, ICW1.
	call io_delay

	out	0A0h, al	                    ; 从8259, ICW1.
	call io_delay

	mov	al, 020h	                    ; IRQ0 对应中断向量 0x20
	out	021h, al	                    ; 主8259, ICW2.
	call io_delay

	mov	al, 028h	                    ; IRQ8 对应中断向量 0x28
	out	0A1h, al	                    ; 从8259, ICW2.
	call io_delay

	mov	al, 004h	                    ; IR2 对应从8259
	out	021h, al	                    ; 主8259, ICW3.
	call io_delay

	mov	al, 002h	                    ; 对应主8259的 IR2
	out	0A1h, al	                    ; 从8259, ICW3.
	call io_delay

	mov	al, 001h
	out	021h, al	                    ; 主8259, ICW4.
	call io_delay

	out	0A1h, al	                    ; 从8259, ICW4.
	call io_delay

	mov	al, 11111110b	                ; 仅仅开启定时器中断
	;mov	al, 11111111b	            ; 屏蔽主8259所有中断
	out	021h, al	                    ; 主8259, OCW1.
	call io_delay

	mov	al, 11111111b	                ; 屏蔽从8259所有中断
	out	0A1h, al	                    ; 从8259, OCW1.
	call io_delay

	ret
;====================================================================================================
io_delay:
    nop
    nop
    nop
    nop
    ret
;====================================================================================================
clock_handler   equ    _clock_handler - code_base
_clock_handler:
    ; 更新 time
    inc byte [gs:((80 * 24 + 30) * 2)]  ; 屏幕第 24 行, 第 30 列
    mov ecx, 30
.loop1:
    cmp byte [gs:((80 * 24 + ecx) * 2)], 0x3a ; 0x3a = ':' 是 '9' 的下一个字符
    jnz .end_loop1
    mov byte [gs:((80 * 24 + ecx) * 2)], 0x30 ; 0x30 = '0'
    inc byte [gs:((80 * 24 + ecx - 1) * 2)] ; 向前进位
    loop .loop1
.end_loop1:
    mov al, 20h                         ; 发送 EOI
    out 020h, al                        ; 发送 EOI
    
    mov eax, G_data
    mov es, ax                          ; es = G_data
    dec dword [es:current_tick]         ; current_tick--
    jnz .end                            ; current_tick != 0, return
    mov eax, [es:current_task]          ; eax = current_task
    mov dword [es:task_is_finished + eax * 4], 1 ; task_is_finished[eax] = 1

.select_next_task:
    mov ecx, -1
.loop2:                                 
    inc ecx
    cmp dword [es:task_is_finished + ecx * 4], 1 ; task_is_finished[ecx] == 1                    
    jz .loop2                           ; continue
    cmp ecx, [es:task_num]              ; ecx >= task_num
    jae .end_loop2                      ; break
    mov eax, [es:task_priority + ecx * 4] ; eax = task_priority[ecx]
    cmp eax, [es:current_tick]          ; eax <= current_tick
    jbe .loop2                          ; continue
    mov [es:current_task], ecx          ; current_task = ecx
    mov [es:current_tick], eax          ; current_tick = eax
    jmp .loop2                          ; continue
.end_loop2:   
    cmp dword [es:current_tick], 0      ; current_tick != 0
    jnz .exchange                       ; 切换任务
    ; tick=0, 任务未被切换, 说明全部任务都已完成, 重置任务状态
    mov ecx, [es:task_num]              ; ecx = task_num
.loop3:
    dec ecx
    mov dword [es:task_is_finished + ecx * 4], 0 ; task_is_finished[ecx] = 0
    cmp ecx, 0                          ; ecx != 0
    jnz .loop3                          ; continue
    jmp .select_next_task               ; 重新选择任务

.exchange:
    mov eax, [es:current_task]          ; eax = current_task
    cmp eax, 0
    jz .0
    cmp eax, 1
    jz .1
    cmp eax, 2
    jz .2
    cmp eax, 3
    jz .3
.0:
    jmp TSS0:0
    jmp .end
.1:
    jmp TSS1:0
    jmp .end
.2:
    jmp TSS2:0
    jmp .end
.3:
    jmp TSS3:0
    jmp .end
.end:
    iretd
;====================================================================================================
user_handler    equ    _user_handler - code_base
_user_handler:
    mov ah, 0Ch                             ; 0000: 黑底    1100: 红字
    mov al, '0'
    mov ecx, 30
.loop1:
    mov [gs:((80 * 24 + ecx) * 2)], ax      ; 屏幕第 24 行, 全 '0'
    loop .loop1
    mov byte [gs:((80 * 24 + 1) * 2)], 't'
    mov byte [gs:((80 * 24 + 2) * 2)], 'i'
    mov byte [gs:((80 * 24 + 3) * 2)], 'm'
    mov byte [gs:((80 * 24 + 4) * 2)], 'e'
    mov byte [gs:((80 * 24 + 5) * 2)], ' '
    mov byte [gs:((80 * 24 + 6) * 2)], ':'
    mov byte [gs:((80 * 24 + 7) * 2)], ' '
    iretd
;====================================================================================================
other_handler equ    _other_handler - code_base
_other_handler:
    mov ah, 0Ch                         ; 0000: 黑底    1100: 红字
    mov al, 'i'
    mov [gs:((80 * 0 + 70) * 2)], ax    ; 屏幕第 0 行, 第 70 列。
    jmp $                               ; 无限循环 (方便调试时观察)
    iretd
;====================================================================================================
code_len equ $ - code_base - 1
;====================================================================================================
[section .code16]
align    32
[bits    16]
code16_base:
    ; cr0 寄存器的 PG 位 31, 关闭分页机制
    mov eax, cr0
    and eax, 0x7fffffff
    mov cr0, eax
    ; cr0 寄存器的 PE 位  0, 关闭保护模式
    mov eax, cr0
    and al, 11111110b
    mov cr0, eax
; 长跳转指令机器码格式
; [0-7] EA ; [8-15] offset ; [16-31] segment
; [jmp_ret_real_mode + 3] = offset
jmp_ret_real_mode:
    jmp    0:ret_real_mode
code16_len    equ    $ - code16_base - 1
;====================================================================================================
%include "./task0.asm"
;====================================================================================================
%include "./task1.asm"
;====================================================================================================
%include "./task2.asm"
;====================================================================================================
%include "./task3.asm"
;====================================================================================================