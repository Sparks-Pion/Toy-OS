;====================================================================================================
; Gate Descriptors(门描述符)
;
; Format:
; 
; [ 0, 15]  Offset in Segment(偏移量)
; [16, 31]  Segment Selector(段选择子)
; [32, 36]  Parameter Count(参数计数)(仅对调用门有效)
; [37, 39]  0x000(保留位)
; [40, 43]  Type(类型)(0x0C = 386 任务门; 0x0E = 386 中断门; 0x0F = 386 陷阱门)
; [44]      S = 0(系统段)
; [45, 46]  DPL = 0(特权级)
; [47]      P = 1(存在位)
; [48, 63]  Offset in Segment(偏移量)
;====================================================================================================
; GDA_  : Gate Descriptor Attribute(门描述符属性)
;====================================================================================================
GDA_CGate    EQU      8Ch    ; 386 调用门类型值
GDA_IGate    EQU      8Eh    ; 386 中断门类型值
GDA_TGate    EQU      8Fh    ; 386 陷阱门类型值
GDA_DPL0     EQU      00h    ; DPL = 0
GDA_DPL1     EQU      20h    ; DPL = 1
GDA_DPL2     EQU      40h    ; DPL = 2
GDA_DPL3     EQU      60h    ; DPL = 3
;====================================================================================================
; GEN_GATE: Generate Gate Descriptors(生成门描述符)
; 
; usage: GEN_GATE Selector, Offset, PCount, Attr
;        Selector:  dw (16-bit selector)
;        Offset:    dd (32-bit address)
;        PCount:    db (parameter count)
;        Attr:      db (use GDA_*)
;====================================================================================================
%macro GEN_GATE 4
    db  (%2 >>  0) & 0FFh                       ; Offset(0-7)
    db  (%2 >>  8) & 0FFh                       ; Offset(8-15)
    db  (%1 >>  0) & 0FFh                       ; Selector(0-7)
    db  (%1 >>  8) & 0FFh                       ; Selector(8-15)
    db  (%3 >>  0) & 01Fh                       ; Parameter Count
    db  (%4 >>  0) & 0FFh                       ; Attribute
    db  (%2 >> 16) & 0FFh                       ; Offset(16-23)
    db  (%2 >> 24) & 0FFh                       ; Offset(24-31)
%endmacro
;====================================================================================================
