;	Tablacus DISK RAM Lite for MSX
;	書き込み対応版(似非RAMディスク用) / 似非DOS(メインRAM64KB使用)版
;	本体16KB / ASCII-8K, Konami-8K, Konami-SCC専用
;
_RAM64K		EQU	1	;メインRAM 64KB使用可能
_RAM_WRITE	EQU	1	;似非RAMディスクへの書き込みに対応する(本体16KB)

	INCLUDE	"DISKROM.ASM"
