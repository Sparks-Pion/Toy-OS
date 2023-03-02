;====================================================================================================
; ARDS(Address Range Descriptor)
;
; Format:
; 
; [ 0, 3] Base Address Low(低32位基址)
; [ 4, 7] Base Address High(高32位基址)
; [ 8, 11] Length Low(低32位长度)
; [12, 15] Length High(高32位长度)
; [16, 19] Type(类型)(0:系统内存, 1:保留, 2:ACPI表, 3:NVS内存)
;====================================================================================================
ARDS:
.BaseAddrLow     EQU 0
.BaseAddrHigh    EQU 4
.LengthLow       EQU 8
.LengthHigh      EQU 12
.Type            EQU 16
.size            EQU 20