;
;	Tablacus DISK RAM Lite - BANK1(6000h-7fffh)常駐コード置き場
;
;	このファイルは2バンク目(ファイル先頭から2000H-3FFFHの位置/
;	セグメント#1)に配置される。普段はディスクデータ(セグメント2
;	以降)の読み出しウィンドウとして使われるBANK1(6000h-7fffh)に、
;	必要な時だけ切り替えてマッピングして使う。
;
;	現在ここに置いているもの:
;	  - DISK_WRITE_RAM: 似非RAMディスクへの書き込みルーチン
;	  - CHK_RAM他: 起動時のみ使うRAM検出ルーチン
;
;	バンク選択レジスタBANK0_SELのアドレス(6000H)はBANK1の範囲内にある為、
;	書き込み中に自分自身(常駐している1バンク目のドライバ本体)を
;	バンク切り替えで消してしまわないように、DISK_WRITE_RAMだけを
;	BANK1側に置いて実行する。BANK0(4000h-5fffh)側を切り替えて
;	似非RAMディスクの書き込みウィンドウとして使う。
;
;	呼び出し規約(DISKIO1と同じ):
;	  A  = 書き込み先ディスクの起点バンク(GET_DISK_BANKの結果)
;	  B  = 残りのセクタ数
;	  DE = セクタ番号
;	  HL = 転送元メモリアドレス(書き込みたいデータがあるバッファ)
;	戻り値:
;	  A  = 0(成功)
;	  B  = 呼び出し時のセクタ数
;
;	※MUL_AHLは1バンク目(BANK0)常駐なので、書き込み中(BANK0が
;	  RAMセグメントに切り替わっている間)は直接CALLできない。
;	  その為このバンクにも同じ内容のコピーを用意する。
;
MUL_AHL_W:
	SCF			;無限ループ回避
MUL_AHL_W1:
	RRA			;->CF
	RET	C
	ADD	HL,HL
	JR	MUL_AHL_W1

DISK_WRITE_RAM:
	DI			;BANK0切り替え中の割り込みを防止
	PUSH	HL
DISKIO1W:
	PUSH	BC		;B=残りのセクタ数
	PUSH	DE		;DE=セクタ番号
	PUSH	AF		;A=8KB単位でカートリッジ内のディスクが存在する位置を指定

	EX	DE,HL		;DE=書き込み元のメモリアドレス HL=セクタ番号
	PUSH	AF
	LD	A,(SECSZ_H)
	CALL	MUL_AHL_W
	POP	AF
	LD	C,L		;C=書き込み元アドレスのセグメント内オフセット(下位)
	ADD	HL,HL		;64KB→32KB
	ADD	HL,HL		;32KB→16KB
	ADD	HL,HL		;16KB→8KB	バンク切り替えのサイズに合わせる
	ADD	A,H		;A=書き込み先の8KBバンク番号
	OR	080H		;似非RAMディスクのバンク(80H以降)を指定する
	LD	(BANK0_SEL),A			;ASCII-8K/Konami-8K
					;BANK0(4000h-5fffh)にRAMセグメントを表示させる
	LD	A,C		;C=書き込み元アドレスのセグメント内オフセット
	AND	01FH		;セグメントのサイズでフィルタする(8K:1F)
	ADD	A,high BANK0_ADR
	LD	H,A
	LD	BC,(SECSZ)	;BCは書き込むセクタサイズ
	LD	L,C		;L=0
	EX	DE,HL		;HL=書き込み元メモリアドレス DE=書き込み先(RAMディスクウィンドウ)
	LDIR
	POP	AF
	POP	DE
	INC	DE
	POP	BC
	DJNZ	DISKIO1W
	LD	B,C

	POP	HL
	XOR	A		;バンク0を元(ドライバ本体/セグメント0)に戻す
	LD	(BANK0_SEL),A			;ASCII-8K/Konami-8K
	EI
	RET

;
;	RAM検出ルーチン(起動時の初期化(INIT_300)からのみ呼ばれる)
;	INIT_300側で事前にBANK1(6000h-7fffh)へこのセグメント#1を
;	マッピングしてから呼び出すこと。呼び出し後、INIT_300側で
;	BANK1をディスクA:のデータ領域(DISK_BANK)に戻す必要がある。
;
;	RDSLTX/_WRSLTはBANK0側(セグメント0)常駐なので、ここから
;	CALLしても問題ない(切り替わるのはBANK1側だけの為)。
;
CHK_RAM:
	PUSH	HL
	CALL	CHK_RAM0
	POP	HL
	RET	Z
	LD	A,(EXPTBL)		;スロット#0
	AND	080H
	CALL	CHK_RAM_SLT
	RET	Z
	LD	A,(EXPTBL+1)		;スロット#1
	AND	080H
	ADD	A,1
	CALL	CHK_RAM_SLT
	RET	Z
	LD	A,(EXPTBL+2)		;スロット#2
	AND	080H
	ADD	A,2
	CALL	CHK_RAM_SLT
	RET	Z
	LD	A,(EXPTBL+3)		;スロット#3
	AND	080H
	ADD	A,3
CHK_RAM_SLT:
	PUSH	HL
	CALL	CHK_RAM0		;スロット#X or X-0
	POP	HL
	RET	Z
	BIT	7,C
	JR	Z,CHK_RAM_E		;スロットは拡張されていない
	LD	A,C
	OR	4			;スロット#X-1
	PUSH	HL
	CALL	CHK_RAM0
	POP	HL
	RET	Z
	LD	A,C
	OR	00CH			;スロット#X-3
	PUSH	HL
	CALL	CHK_RAM0
	POP	HL
	RET	Z
	LD	A,C
	AND	0F3H			;スロット#X-2
	OR	8
	PUSH	HL
	CALL	CHK_RAM0
	POP	HL
CHK_RAM_E:
	XOR	A
	INC	A			;ZF=0にする
	LD	A,0
	RET

CHK_RAM0:
	LD	C,A
	LD	L,0
CHK_RAM1:
	LD	A,C
	CALL	RDSLTX
	ADD	A,0E5H
	LD	B,A
	LD	E,A
	LD	A,C
	PUSH	BC
	CALL	_WRSLT
	POP	BC
	LD	A,C
	CALL	RDSLTX
	CP	B
	RET	NZ
	SUB	0E5H
	LD	A,C
	LD	E,A
	PUSH	BC
	CALL	_WRSLT
	POP	BC
	INC	H
	LD	A,L
	ADD	A,4
	LD	L,A
	JR	NZ,CHK_RAM1
	LD	A,C		;ZF=1のハズ
	RET
