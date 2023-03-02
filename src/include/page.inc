;====================================================================================================
; PDE(Page-Directory Entry) (页目录项)
; PTE(Page-Table Entry) (页表项)
;
; Format:
; 
; [ 0]      P(present)(0 = not present, 1 = present)
; [ 1]      R/W(read/write)(0 = read-only, 1 = read/write)
; [ 2]      U/S(user/supervisor)(0 = supervisor, 1 = user)
; [ 3]      PWT(page-level write-through)(0 = write-back, 1 = write-through)
; [ 4]      PCD(page-level cache disable)(0 = cache enabled, 1 = cache disabled)
; [ 5]      A(accessed)(0 = not accessed, 1 = accessed)
; [ 6]      D(dirty)(0 = not dirty, 1 = dirty)(PDE reserved 0)
; [ 7]      PS(page size)(0 = 4KB, 1 = 4MB)(PTE reserved 0)
; [ 8]      G(global page)(0 = not global, 1 = global)
; [ 9, 11]  AVL(available for system software)
; [12, 31]  Base address of page table or page directory
;====================================================================================================
PG_P        EQU    1    ; 页存在属性位
PG_R        EQU    0    ; R/W 属性位值, 读/执行
PG_RW       EQU    2    ; R/W 属性位值, 读/写/执行
PG_USS      EQU    0    ; U/S 属性位值, 系统级
PG_USU      EQU    4    ; U/S 属性位值, 用户级
;====================================================================================================
PDT_base    equ 0x200000  ; 页目录基址 [0x200000-0x200FFF] 4KB
PT_base     equ 0x201000  ; 页表基址   [0x201000-0x20FFFF] 60KB
;====================================================================================================
; usage: init_Page PDT_base, PT_base
%macro init_Page 2                      ; 初始化页机制
    ; 初始化段寄存器
    mov ax, flat_data
    mov es, ax                          ; es = 4G virt data
    ; 初始化页目录表
    mov ecx, [PDE_num]                  ; ecx = 页目录表项数
    mov edi, %1                         ; es:edi = PDT_base = 0x200000
    mov eax, %2 | PG_USU | PG_RW | PG_P ; eax = 页目录表项内容
    .loop_%1:
        stosd                           ; [es:edi] = eax ,  edi = edi + 4 
        add eax, 0x1000                 ; 每个页表目录项映射到一个 4KB 的页表
        loop .loop_%1
    ; 初始化页表
    mov ecx, [PTE_num]                  ; ecx = 页表项数
    mov edi, %2                         ; es:edi = PT1_base = 0x201000
    mov eax, 0 | PG_USU | PG_RW | PG_P  ; eax = 页表项内容
    .loop_%2:
        stosd                           ; [es:edi] = eax ,  edi = edi + 4 
        add eax, 0x1000                 ; 每个页表项映射到一个 4KB 的物理内存
        loop .loop_%2
%endmacro
;====================================================================================================