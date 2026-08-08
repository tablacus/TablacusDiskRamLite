;
;	Tablacus DISK RAM Lite - 似非RAMディスク書き込みルーチン
;
;	このファイルは2バンク目(ファイル先頭から2000H-3FFFHの位置)に配置され、
;	DISKIOが書き込み要求を受けた時にだけBANK1(6000h-7fffh)へ
;	マッピングされて実行される。
;
;	バンク選択レジスタBANK0_SELのアドレス(6000H)はBANK1の範囲内にある為、
;	書き込み中に自分自身(常駐している1バンク目のドライバ本体)を
;	バンク切り替えで消してしまわないように、このルーチンだけを
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
