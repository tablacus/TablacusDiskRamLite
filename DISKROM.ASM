;	Tablacus DISK ROM Lite for MSX
;	Programmed by
;	Gaku (Lovers/Tablacus)

	INCLUDE	"DEF.ASM"
	ORG	RUN

; MSX ROM header
	DB	"AB"		; ID for auto-executable ROM
	DW	INIT_ROM	; Main program execution address.
	DW	STATEMENT	; STATEMENT
	DW	DEVICE_ENTRY	; DEVICE
	DW	0		; TEXT
	DW	0,0,0		; Reserved

	JP	DISKIO
	JP	DSKCHG
	JP	GETDPB
	JP	CHOICE
	JP	DSKFMT
	JP	DSKSTP
	JP	BASENT
	SCF
	JP	DSKFMT
	JP	DSKSTP
	NOP
	JP	GETSLT
	LD	HL,(0F34BH)
	RET

	ORG	0407FH
	RET
; Version
#if exists _RAM_WRITE
	DB	"Tablacus DISK RAM Lite"
#else
	DB	"Tablacus DISK ROM Lite"
#endif
	ALIGN	32
	DB	"v0.0.0.1"
	ALIGN	32
MSG_ERROR_ROM_MODE:
#if exists USE_NORMAL32K_OR_ASCII16
	DB	"Normal ROM/ASCII-16K only!",13,10
#else
	DB	"ASCII-8K/Konami-8K/Konami-SCC only!",13,10
#endif
	ORG	04100H
INIT_ROM:
	XOR	A
	LD	HL,0F300H
	LD	B,068H
	CALL	FILL_MEMORY

	LD	A,1
	LD	(DRVTBL),A

	LD	HL,(HIMEM)
	LD	DE,NEW_HIMEM
	AND	A
	SBC	HL,DE
	JR	C,INIT1
	EX	DE,HL
	LD	HL,(STKTOP)
	SBC	HL,DE
	LD	(STKTOP),HL	;起動時の空き容量表示の為
	LD	SP,HL
	LD	HL,(MEMSIZ)
	LD	A,H
	OR	L
	LD	(IS_BIOS),A
	JR	NZ,GENUINE
	LD	HL,0F180H	;C-BIOSの場合に補正する
	LD	(FRETOP),HL
GENUINE:
	SBC	HL,DE
	LD	(MEMSIZ),HL
	LD	HL,(FRETOP)
	SBC	HL,DE
	LD	(FRETOP),HL
	LD	HL,NEW_HIMEM
	LD	(HIMEM),HL
INIT1:
	XOR	A
	LD	(_DVSW),A
	DEC	A		;0FFH
	LD	(DEVICE),A
#if exists _RAM64K
	LD	HL,AT_ISC
	LD	DE,ISC
	LD	BC,ISC_E-ISC
	LDIR
#endif
	JP	INIT_300

	ORG	041BDH
	RET

	;MBR_Partition1 (2DDのデータ)
	DB	0		;ブートフラグ
	DB	0,0,0		;パーティションの最初のセクタ番号(CHS方式)
	DB	1		;識別子(FAT12)
	DB	0,0,0		;パーティションの最後のセクタ番号(CHS方式)
	DW	16,0		;パーティションの最初のセクタ番号(LBA方式)
	DW	1440,0		;パーティション内のセクタ数(LBA方式)

#if exists USE_NORMAL32K_OR_ASCII16
#else
	;MBR_Partition2 (2DDのデータ)
	DB	0		;ブートフラグ
	DB	0,0,0		;パーティションの最初のセクタ番号(CHS方式)
	DB	1		;識別子(FAT12)
	DB	0,0,0		;パーティションの最後のセクタ番号(CHS方式)
	DW	16+1440,0	;パーティションの最初のセクタ番号(LBA方式)
	DW	1440,0		;パーティション内のセクタ数(LBA方式)
#endif

	ORG	041FEH
	DB	055H,0AAH	;MBR_Sig

	INCLUDE	"TABLE.ASM"
	INCLUDE	"INIT.ASM"
	INCLUDE	"FILE.ASM"
	INCLUDE	"DISK.ASM"
	INCLUDE	"BDOS.ASM"
	INCLUDE	"SLOT.ASM"
LAST	EQU	$$
	DS	01FFFH-LAST
	DB	0

#if exists _RAM_WRITE
;=====================================================================
;	2バンク目 (ファイルオフセット 2000H-3FFFH / セグメント#1)
;
;	似非RAMディスクへの書き込み処理を行う間だけBANK1(6000h-7fffh)に
;	マッピングされる。それ以外の時間はBANK1は通常通りディスク
;	データ(セグメント2以降)の読み出しウィンドウとして使われる。
;
;	この2バンク目が常に存在する為、DEF.ASMでDISK_BANK=2に変更して
;	ディスクイメージの先頭(ドライブA)がセグメント2から始まるように
;	している。DISKROM.BIN(またはDISKRAM.BIN)本体が8KBから16KBに
;	なった分、後ろに連結するDSKファイルの位置がそのままズレるだけ
;	なので、連結の手順自体はROM Lite版と同じ(単純に連結するだけ)。
;=====================================================================
	ORG	06000H,$$
	INCLUDE	"DISKWRAM.ASM"
LAST2	EQU	$$
	DS	03FFFH-LAST2
	DB	0
#endif

	END
