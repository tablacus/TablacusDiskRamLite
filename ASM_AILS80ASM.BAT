rem
rem Tablacus DISK ROM for MSX assemble batch for AILZ80ASM
rem <https://github.com/AILight/AILZ80ASM>
rem

set ASM=\tool\AILSZ80\AILZ80ASM.exe

rem Tablacus DISK RAM Lite (‘‚«‚İ‘Î‰/16KB, ASCII-8K/Konami-8K/Konami-SCCê—p)
%ASM% -lst -bin DISKRAM.BIN -i DISKRAM.ASM -f -gap 0 -sym
%ASM% -lst -bin DISKRAM64K.BIN -i DISKRAM64K.ASM -f -gap 0 -sym

msxcat
