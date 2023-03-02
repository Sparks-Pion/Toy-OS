;====================================================================================================
font_color  equ 0x0f      ; 字体颜色
;====================================================================================================
; 显示字符串
; ds:eax = 字符串地址
; gs:edi = 显示位置
;====================================================================================================
print_str:
    push eax
    push ebx
    mov bh, font_color
    .loop1:
        mov bl, [eax]
        mov [gs:edi], bx
        add edi, 2
        inc eax
        cmp byte [eax], 0
        jne .loop1
    pop ebx
    pop eax
    ret
;====================================================================================================
; 回车,计算edi的值
; gs:edi = 显示位置
;====================================================================================================
print_enter:
    push eax
	push ebx
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	ebx
	pop	eax
    ret
;====================================================================================================
; 显示 eax 中的十六进制数(0~FFFFFFFF)
; eax = num
; gs:edi = 显示位置
;====================================================================================================
print_eax:
    push eax
    mov eax, [esp]
    shr eax, 16
    call print_ax
    mov eax, [esp]
    call print_ax
    pop eax
    ret
;====================================================================================================
; 显示 ax 中的十六进制数(0~FFFF)
; ax = num
; gs:edi = 显示位置
;====================================================================================================
print_ax:
    push ax
    mov ax, [esp]
    shr ax, 12
    call print_a_hex
    mov ax, [esp]
    shr ax, 8
    call print_a_hex
    mov ax, [esp]
    shr ax, 4
    call print_a_hex
    mov ax, [esp]
    call print_a_hex
    pop ax
    ret
;====================================================================================================
; 显示 al 中的十六进制数(0~F)
; al = num
; gs:edi = 显示位置
;====================================================================================================
print_a_hex:
    push eax
    and eax, 0xf
    add eax, hex_str
    mov al, byte [ds:eax]
    mov ah, font_color
    mov [gs:edi], ax
    add edi, 2
    pop eax
    ret
;====================================================================================================
; usage: Load_function seg_LDT*, L*_code, task*_offset, task*_len, task*_base, L*_PDT_base
%macro Load_function 6
    mov ax, flat_data
    mov es, ax                          ; 初始化 es
    mov ax, %1
    lldt ax                             ; 加载 LDT0
    mov ax, %2
    mov ds, ax                          ; 初始化 ds
    mov ecx, %4                         ; 代码长度
    mov esi, %3                         ; 代码起始地址  
    mov edi, %5                         ; 代码加载地址
    cld                                 ; esi, edi 递增
    rep movsb                           ; ds:si -> es:di

    mov eax, [es:(%6 + 4 * 1)]                          ; read PDT[1]
    and eax, 0xfffff000                                 ; eax = base addr of PT1
    mov dword [es:eax], (%5 | PG_USU | PG_RW | PG_P)    ; PT1[0] = task*_base
%endmacro