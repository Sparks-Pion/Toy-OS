L3_PDT_base equ 0x230000
L3_PET_base equ 0x231000
task3_base  equ 0x330000
;====================================================================================================
[section .LDT]
align    32
LDT3_base:
_L3_code:          GEN_SEG 0, L3_code_len,  (SDA_RX | SDA_32 | SDA_DPL3)    ; 32位代码段(ring3)
L3_code            equ _L3_code - LDT3_base + SSA_TIL + SSA_RPL3
_L3_stack:         GEN_SEG 0, L3_stack_top, (SDA_RW | SDA_32 | SDA_DPL3)    ; 32位堆栈段(ring3)
L3_stack           equ _L3_stack - LDT3_base + SSA_TIL + SSA_RPL3
_L3_data:          GEN_SEG 0, L3_data_len,  (SDA_RW | SDA_32 | SDA_DPL3)    ; 32位数据段(ring3)
L3_data            equ _L3_data - LDT3_base + SSA_TIL + SSA_RPL3
_L3_stack_0:       GEN_SEG 0, L3_stack_0_top, (SDA_RW | SDA_32 | SDA_DPL0)  ; 32位堆栈段(ring0)
L3_stack_0         equ _L3_stack_0 - LDT3_base + SSA_TIL + SSA_RPL0
LDT3_len    equ $ - LDT3_base - 1
;====================================================================================================
[section .stack]
align    32
[bits    32]
L3_stack_base:  db 512 dup(0)
L3_stack_top    equ $ - L3_stack_base - 1
;====================================================================================================
[section .stack_0]
align    32
[bits    32]
L3_stack_0_base:  db 512 dup(0)
L3_stack_0_top    equ $ - L3_stack_0_base - 1
;====================================================================================================
[section .data]
align    32
[bits    32]
L3_data_base:   db 0
L3_data_len     equ $ - L3_data_base - 1
;====================================================================================================
[section .code]
align    32
[bits    32]
L3_code_base:
.start:
    call flat_code:task_addr
    jmp .start

task3_offset    equ $ - L3_code_base
.task3:
    mov    ah, 0Ch                      ; 0000: 黑底    1100: 红字
    mov    al, 'M'
    mov [gs:((80 * 20 + 15) * 2)], ax   ; 屏幕第 20 行, 第 15 列
    mov    al, 'R'
    mov [gs:((80 * 20 + 16) * 2)], ax   ; 屏幕第 20 行, 第 16 列
    mov    al, 'S'
    mov [gs:((80 * 20 + 17) * 2)], ax   ; 屏幕第 20 行, 第 17 列
    mov    al, 'U'
    mov [gs:((80 * 20 + 18) * 2)], ax   ; 屏幕第 20 行, 第 18 列
    
    mov    ah, 0Fh                      ; 0000: 黑底    1111: 白字
    mov    al, 'V'
    mov [gs:((80 * 20 + 0) * 2)], ax    ; 屏幕第 20 行, 第 0 列
    mov    al, 'E'
    mov [gs:((80 * 20 + 1) * 2)], ax    ; 屏幕第 20 行, 第 1 列
    mov    al, 'R'
    mov [gs:((80 * 20 + 2) * 2)], ax    ; 屏幕第 20 行, 第 2 列
    mov    al, 'Y'
    mov [gs:((80 * 20 + 3) * 2)], ax    ; 屏幕第 20 行, 第 3 列
    mov    al, ' '
    mov [gs:((80 * 20 + 4) * 2)], ax    ; 屏幕第 20 行, 第 4 列
    mov    al, 'L'
    mov [gs:((80 * 20 + 5) * 2)], ax    ; 屏幕第 20 行, 第 5 列
    mov    al, 'O'
    mov [gs:((80 * 20 + 6) * 2)], ax    ; 屏幕第 20 行, 第 6 列
    mov    al, 'V'
    mov [gs:((80 * 20 + 7) * 2)], ax    ; 屏幕第 20 行, 第 7 列
    mov    al, 'E'
    mov [gs:((80 * 20 + 8) * 2)], ax    ; 屏幕第 20 行, 第 8 列
    mov    al, ' '
    mov [gs:((80 * 20 + 9) * 2)], ax    ; 屏幕第 20 行, 第 9 列
    mov    al, 'H'
    mov [gs:((80 * 20 + 10) * 2)], ax   ; 屏幕第 20 行, 第 10 列
    mov    al, 'U'
    mov [gs:((80 * 20 + 11) * 2)], ax   ; 屏幕第 20 行, 第 11 列
    mov    al, 'S'
    mov [gs:((80 * 20 + 12) * 2)], ax   ; 屏幕第 20 行, 第 12 列
    mov    al, 'T'
    mov [gs:((80 * 20 + 13) * 2)], ax   ; 屏幕第 20 行, 第 13 列
    mov    al, ' '
    mov [gs:((80 * 20 + 14) * 2)], ax   ; 屏幕第 20 行, 第 14 列
    retf
task3_len       equ $ - L3_code_base - task3_offset

L3_code_len  equ $ - L3_code_base - 1
;====================================================================================================
[SECTION .TSS]
ALIGN    32
[BITS    32]
TSS3_base:
        DD    0            ; Back
        DD    L3_stack_0_top ; 0 级堆栈
        DD    L3_stack_0   ; selector
        DD    0            ; 1 级堆栈
        DD    0            ; selector
        DD    0            ; 2 级堆栈
        DD    0            ; selector
        DD    L3_PDT_base  ; CR3
        DD    0            ; EIP
        DD    0x200        ; EFLAGS
        DD    0            ; EAX
        DD    0            ; ECX
        DD    0            ; EDX
        DD    0            ; EBX
        DD    L3_stack_top ; ESP
        DD    0            ; EBP
        DD    0            ; ESI
        DD    0            ; EDI
        DD    0            ; ES
        DD    L3_code      ; CS
        DD    L3_stack     ; SS
        DD    L3_data      ; DS
        DD    0            ; FS
        DD    G_video      ; GS
        DD    LDT3         ; LDT
        DW    0            ; 调试陷阱标志
        DW    $ - TSS3_base + 2 ; I/O位图基址
        DB    0ffh            ; I/O位图结束标志
TSS3_len        equ    $ - TSS3_base - 1
;====================================================================================================