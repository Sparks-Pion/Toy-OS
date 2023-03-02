;====================================================================================================
loader_base_addr equ 0x1000               ; loader的基地址
loader_offset    equ 0x100                ; loader的偏移地址
;====================================================================================================

org   0x7c00                ; 指明引导扇区的装载地址

;====================================================================================================
; 用于标准FAT12格式的软盘
; 一个1.44M的软盘，它有80个磁道，每个磁道有18个扇区，两面都可以存储数据，每个扇区512字节，所以总共有2880个扇区
BS_jmpBoot:                               ; 引导扇区的跳转指令(3字节)
    jmp   entry             ; 跳转指令
    nop                     ; NOP指令(0x90)
BS_OEMName        db    "Sparks  "        ; OEM标识符(8字节)
BPB_BytsPerSec    dw    512               ; 每个扇区(sector)的字节数(必须为512字节)
BPB_SecPerClus    db    1                 ; 每个簇(cluster)的扇区数(必须为1个扇区)
BPB_RsvdSecCnt    dw    1                 ; FAT的预留扇区数(包含boot扇区)
BPB_NumFATs       db    2                 ; FAT表的数量，通常为2
BPB_RootEntCnt    dw    224               ; 根目录文件的最大值(一般设为224项)
BPB_TotSec16      dw    2880              ; 磁盘的扇区总数，若为0则代表超过65535个扇区，需要使用20行记录
BPB_Media         db    0xf0              ; 磁盘的种类(本项目中设为0xf0代表1.44MB的软盘)
BPB_FATSz16       dw    9                 ; 每个FAT的长度(必须为9扇区)
BPB_SecPerTrk     dw    18                ; 1个磁道(track)拥有的扇区数(必须是18)
BPB_NumHeads      dw    2                 ; 磁头数(必须为2)
BPB_HiddSec       dd    0                 ; 隐藏的扇区数
BPB_TotSec32      dd    2880              ; 大容量扇区总数，若 BPB_TotSec16 记录的值为0则使用本行记录扇区数
BS_DrvNum         db    0                 ; 中断0x13的设备号
BS_Reserved1      db    0                 ; Windows NT标识符(未使用)
BS_BootSig        db    0x29              ; 扩展引导标识
BS_VolID          dd    0xffffffff        ; 卷序列号
BS_VolLab         db    "Sparks-OS  "     ; 卷标(11字节)
BS_FileSysType    db    "FAT12   "        ; 文件系统类型(8字节)
;====================================================================================================


;====================================================================================================
; 常数定义
SECTOR_SIZE       equ 512                 ; 扇区大小
ROOT_DIR_SECTOR   equ 19                  ; 根目录扇区号
ROOT_DIR_SIZE     equ 14                  ; 根目录大小(扇区数)
;====================================================================================================

; 代码部分
entry:
    ; 初始化段寄存器
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax              ; 设置数据段、附加段、堆栈段均为代码段，保证寻址正常
    mov sp, 0x7c00          ; 设置栈指针(栈从0x7c00开始向低地址增长)
    ; 清空屏幕
    mov ah,0x00             ; 清屏函数号
    mov al,0x03             ; 清屏属性
    int 0x10                ; 调用中断
    ;软盘复位
    xor ah, ah
    xor dl, dl
    int 0x13                ; 软盘复位
    ; 读入根目录
    ; 扇区号20-33为根目录，从C0-H1-S2到C0-H1-S15 (这里扇区号从1开始)
    ; 读入到 0x8000-0x9c00
    mov ax, 0x0800        
    mov es, ax              ; 先读入到 0x8000
    xor bx, bx              ; es:bx = 0x8000
    
    mov ah, 2               ; 读扇区
    mov dl, 0               ; 驱动器号 0
    mov ch, 0               ; 柱面号 C0
    mov dh, 1               ; 磁头号 H1
    mov cl, 2               ; 起始扇区号 S2
    mov al, 14              ; 读14个扇区
    int 0x13                ; 读入根目录
    jc print_error          ; 读入失败则跳转到error
    jmp find_file           ; 读入成功则跳转到find_file

; 查找文件 loader.bin
; LOADER  BIN
filename db "OS      BIN", 0x00

find_file:
    mov cx, [BPB_RootEntCnt]; 根目录最多224项
    mov si, 0x8000          ; 根目录起始地址
    mov di, filename        ; 文件名起始地址

.loop1:
    push cx                 ; 保存cx
    push si                 ; 保存si
    mov cx, 11              ; 比较11个字符

.cmp_byte:
    mov al, [di]            ; al = 文件名第一个字符
    mov ah, [si]            ; ah = 根目录中文件名
    cmp al, ah              ; 比较al和ah
    jne .next               ; 不相等则跳转到.next
    inc si                  ; si 自增1
    inc di                  ; di 自增1
    loop .cmp_byte          ; 循环比较11个字符

    jmp .found              ; 找到文件则跳转到.found

.next:
    pop cx                  ; 恢复cx
    pop si                  ; 恢复si
    add si, 32              ; si 自增32
    mov di, filename        ; di 指向文件名
    loop .loop1

    call print_not_found    ; 没有找到文件则跳转到not_found

.found:
    pop si                  ; 恢复si
    call print_found_it     ; 调用文件输出函数
    mov ax, [si+26]         ; ax = 文件起始簇号
    push ax                 ; 将文件起始簇号压入栈,保存起来

    ; 读入FAT1表
    ; 扇区号2-10为FAT1表，从C0-H0-S2到C0-H0-S10 (这里扇区号从1开始)
    ; 读入到 0x8000-0x9200
    mov ax, 0x0800
    mov es, ax              ; 先读入到 0x8000
    xor bx, bx              ; es:bx = 0x8000

    mov ah, 2               ; 读扇区
    mov dl, 0               ; 驱动器号 0
    mov ch, 0               ; 柱面号 C0
    mov dh, 0               ; 磁头号 H0
    mov cl, 2               ; 起始扇区号 S2
    mov al, 9               ; 读9个扇区
    int 0x13                ; 读入FAT1表
    jc print_error          ; 读入失败则跳转到error
    
    call print_booting      ; 输出 "booting " 字符串
    mov ax, loader_base_addr
    mov es, ax              ; 文件加载到内存 loader_base_addr
    mov bx, loader_offset   ; es:bx = loader_base_addr:loader_offset
    jmp .load_file          ; 读入成功则跳转到load_file

.load_file:
    ; 读入一个簇
    pop ax                  ; 弹出文件簇号
    push ax                 ; 将文件簇号压入栈,保存起来
    add ax, 34-2            ; 文件簇号从2开始，前面是1+9+9+14=33个扇区，34个扇区就是第一个簇
    call read_sector        ; 读入一个簇
    ; 读入成功输出一个'.'字符
    mov al, '.'             ; 输出 '.' 字符
    mov ah, 0x0e            ; 显示一个文字
    mov bx, 0x0f            ; 指定字符颜色(黑底白字)
    int 0x10                ; 调用显卡BIOS
    ; es:bx = es:bx + 0x200
    mov ax, es              ; ax = es
    add ax, 0x20
    mov es, ax              ; es:bx 向后移动0x200
    mov bx, loader_offset   ; es:bx = loader_base_addr:loader_offset
    ; 从FAT中获取下一个簇
    pop ax                  ; 弹出文件簇号
    call get_next_cluster   ; 获取下一个簇号
    cmp ax, 0xff8           ; 判断是否为文件结束标志
    jae .end                ; 如果>=0xff8则跳转到.end
    push ax                 ; 将下一个簇号压入栈,保存起来
    jmp .load_file          ; 读入成功则跳转到load_file

.end:
    ; 输出一个换行符
    call print_newline      ; 输出一个换行符
    ; 跳转到0x10000 (loader.bin)
    call print_jump_loader  ; 输出 "jump to loader.bin" 字符串
    jmp loader_base_addr:loader_offset ; 跳转到 loader.bin

;====================================================================================================
; 获取文件簇号在FAT表中所指向的下一个簇号
; 输入 ax = 文件簇号
; 输出 ax = 下一个簇号
;====================================================================================================
get_next_cluster:
    push bx                 ; 保存bx
    push ax                 ; 保存ax
    shr ax, 1               ; ax = 文件簇号/2
    mov bx, 3               ; bx = 3
    mul bx                  ; ax = 文件簇号/2*3
    mov bx, ax              ; bx = 文件簇号/2*3
    pop ax                  ; ax = 文件簇号
    and ax, 1               ; ax = 文件簇号%2
    jnz .odd                ; 如果是奇数则跳转到.odd
.even:
    ; 偶数的情况 7654 3210 .... BA98 .... ....
    mov ax, word [0x8000+bx] ; ax = ....BA9876543210
    and ax, 0x0fff          ; ax = 0000BA9876543210
    jmp .end                ; 跳转到.end
.odd:
    ; 奇数的情况 .... .... 3210 .... BA98 7654
    mov ax, word [0x8000+bx+1] ; ax = BA9876543210....
    shr ax, 4               ; ax = 0000BA9876543210
    jmp .end                ; 跳转到.end
.end:
    pop bx                  ; 恢复bx
    ret
;====================================================================================================
; 从磁盘读入一个扇区到es:bx
; 输入 ax = 扇区号
;====================================================================================================
read_sector:
    ; 保存寄存器
    push ax                 ; 保存ax
    push cx                 ; 保存cx
    push dx                 ; 保存dx
    ; 计算扇区对应的柱面号、磁头号、扇区号
    dec ax                  ; 扇区号-1
    mov cx, 18              ; cx = 18
    div cx                  ; ax = (扇区号-1)/18 ; dx = (扇区号-1)%18
    push dx                 ; 保存dx = (扇区号-1)%18
    ; 计算磁头号
    mov dh, al              ; dx = (扇区号-1)/18
    and dh, 1               ; dh = (扇区号-1)/18%2 = 磁头号
    ; 计算柱面号
    shr ax, 1               ; ax = (扇区号-1)/18/2 = 柱面号
    mov ch, al              ; ch = 柱面号
    ; 计算扇区号
    pop ax                  ; ax = (扇区号-1)%18
    inc ax                  ; ax = (扇区号-1)%18 + 1
    mov cl, al              ; cl = 扇区号
    ; 读入扇区
    mov ah, 2               ; 读扇区
    mov dl, 0               ; 驱动器号 0
    mov al, 1               ; 读1个扇区
    int 0x13                ; 读入扇区
    jc print_error          ; 读入失败则跳转到error
    ; 恢复寄存器
    pop dx                  ; 恢复dx
    pop cx                  ; 恢复cx
    pop ax                  ; 恢复ax
    ret
;====================================================================================================
; 信息输出
;====================================================================================================
jump_loader_str db "jump to loader.bin", 0x0a, 0x0d, 0x00
print_jump_loader:
    push si                 ; 保存si
    mov si, jump_loader_str ; 获取字符串地址
    call print_str          ; 调用字符串输出函数
    pop si                  ; 恢复si
    ret
;====================================================================================================
; 信息输出
;====================================================================================================
enter_str db 0x0a, 0x0d, 0x00
print_newline:
    push si                 ; 保存si
    mov si, enter_str       ; 获取字符串地址
    call print_str          ; 调用字符串输出函数
    pop si                  ; 恢复si
    ret
;====================================================================================================
; 信息输出
;====================================================================================================
booting_str db "booting ", 0x00
print_booting:
    push si                 ; 保存si
    mov si, booting_str     ; 获取字符串地址
    call print_str          ; 调用字符串输出函数
    pop si                  ; 恢复si
    ret 
;====================================================================================================
; 信息输出
;====================================================================================================
nofound_str db "not found ", 0x00
print_not_found:
    mov si, nofound_str     ; 获取字符串地址
    call print_str          ; 调用字符串输出函数
    mov si, filename        ; 获取字符串地址
    call print_str          ; 调用字符串输出函数
    call print_newline      ; 调用字符串输出函数
    call error_str          ; 调用字符串输出函数 
    ret   
;====================================================================================================
; 信息输出
;====================================================================================================
found_str db "found ", 0x00
print_found_it:
    push si                 ; 保存si
    mov si, found_str       ; 获取字符串地址
    call print_str          ; 调用字符串输出函数
    mov si, filename        ; 获取字符串地址
    call print_str          ; 调用字符串输出函数
    call print_newline      ; 调用字符串输出函数
    pop si                  ; 恢复si
    ret
;====================================================================================================
; 错误处理
;====================================================================================================
error_str db "Error!", 0x0d, 0x0a, 0x00
print_error:
    mov si, error_str       ; 获取字符串地址
    call print_str          ; 调用字符串输出函数
    jmp $
;====================================================================================================
; 字符串输出
;====================================================================================================
print_str:                 
    push ax                 ; 保存寄存器
    push bx
    
.loop1:
    mov al, [si]            ; al = 字符串内容
    cmp al, 0               ; 比较al和0
    je end                  ; 相等则跳转到end

    mov ah, 0x0e            ; 显示一个文字
    mov bx, 0x0f            ; 指定字符颜色(黑底白字)
    int 0x10                ; 调用显卡BIOS

    inc si                  ; si 自增
    jmp .loop1              ; 跳转到 .loop1

end:
    pop bx                  ; 恢复寄存器
    pop ax

    ret
;====================================================================================================
; 结束标志
;====================================================================================================
db 510 - ($ - $$) dup 0
db 0x55, 0xaa
;====================================================================================================
    
