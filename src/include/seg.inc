;====================================================================================================
; Segment Descriptors(段描述符)
;
; Format:
; 
; [ 0, 15]  Segment Limit(段界限)
; [16, 39]  Base Address(基地址)
; [40, 43]  Type(类型)         
; [44]      S(descriptor type)(0 = system; 1 = code or data)
; [45, 46]  DPL(descriptor privilege level)(0 = highest; 3 = lowest)
; [47]      P(segment present)(0 = not present; 1 = present)
; [48, 51]  Segment Limit(段界限)
; [52]      AVL(available for use by system software)(0 = available; 1 = not available)
; [53]      0(reserved)
; [54]      D/B(Default operation size)(0 = 16-bit() segment; 1 = 32-bit segment)
; [55]      G(Granularity)(0 = 1B; 1 = 4KB)(用于表示段界限的单位)
; [56, 63]  Base Address(基地址)
;====================================================================================================
; SDA_  : Segment Descriptor Attribute(段描述符属性)
;====================================================================================================
SDA_32		    EQU	4000h	; 32-bit segment
SDA_4K		    EQU	8000h	; 4KB granularity
SDA_DPL0		EQU	  00h	; DPL = 0
SDA_DPL1		EQU	  20h	; DPL = 1
SDA_DPL2		EQU	  40h	; DPL = 2
SDA_DPL3		EQU	  60h	; DPL = 3
;====================================================================================================
; type attribute(类型属性)
; D    : Data-Segment(read only)(数据段，只读)
; C    : Code-Segment(execute only)(代码段，只执行)
; R    : Readable(可读)
; W    : Writeable(可写)
; A    : Accessed(已访问)
; C    : Conforming(兼容\允许降级)
;====================================================================================================
; data segment
SDA_R		    EQU	90h     ; r--
SDA_RW		    EQU	92h     ; rw-
SDA_RW_E		EQU	93h     ; rw-   (expand-down)
; code segment
SDA_X		    EQU	98h     ; --x
SDA_RX		    EQU	9Ah	    ; r-x   
SDA_X_C		    EQU	9Ch     ; --x   (conforming)
SDA_RX_C 		EQU	9Eh     ; r-x   (conforming)
; system segment 
SDA_LDT		    EQU	82h	    ; 局部描述符表段类型值
SDA_TSS	        EQU	89h	    ; 可用 386 任务状态段类型值
;====================================================================================================
; Segment Selector(段选择子)
;
; Format:
; 
; [ 0,  1]  RPL(requested privilege level)(特权级)(0 = highest; 3 = lowest)
; [ 2]      TI(Table Indicator)(0 =  GDT; 1 = LDT)
; [ 3, 15]  index(索引)
;====================================================================================================
; SSA_  : Segment Selector Attribute(段选择子属性)
;====================================================================================================
SSA_RPL0		    EQU	0	    ; RPL = 0
SSA_RPL1		    EQU	1	    ; RPL = 1 
SSA_RPL2		    EQU	2	    ; RPL = 2 
SSA_RPL3		    EQU	3	    ; RPL = 3 
SSA_TIG		        EQU	0	    ; select GDT(Global Descriptor Table)(全局描述符表)
SSA_TIL		        EQU	4	    ; select LDT(Local Descriptor Table)(局部描述符表)
;====================================================================================================


;====================================================================================================
; GEN_SEG: Generate Segment Descriptors(生成段描述符)
; 
; usage: GEN_SEG Base, Limit, Attr
;        Base:  dd (32-bit address)
;        Limit: dd (20-bit limit)
;        Attr:  dw (use SDA_*)
;====================================================================================================
%macro GEN_SEG 3
    db  (%2 >>  0) & 0FFh                       ; Segment Limit(0-7)
    db  (%2 >>  8) & 0FFh                       ; Segment Limit(8-15)
    db  (%1 >>  0) & 0FFh                       ; Base Address(0-7)
    db  (%1 >>  8) & 0FFh                       ; Base Address(8-15)
    db  (%1 >> 16) & 0FFh                       ; Base Address(16-23)
    db  (%3 >>  0) & 0FFh                       ; Attribute(type, S, DPL, P)
    db  (%3 >>  8) & 0F0h | (%2 >> 16) & 0Fh    ; Attribute(AVL, 0, D/B, G)  | Segment Limit(16-19) 
    db  (%1 >> 24) & 0FFh                       ; Base Address(24-31)
%endmacro
;====================================================================================================
; Load_Base: Load Base Address(加载基地址)
;
; usage: Load_Base Base, Descriptor_Address
;        Base:  dd (32-bit address)
;        Descriptor_Address: dd (32-bit address)
;====================================================================================================
%macro Load_Base 2
	xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, %1
	mov	word [%2 + 2], ax
	shr	eax, 16
	mov	byte [%2 + 4], al
	mov	byte [%2 + 7], ah
%endmacro