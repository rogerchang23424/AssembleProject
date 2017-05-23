INCLUDE Irvine32.inc
;包括boolean的相關定義
INCLUDE Bool.inc
INCLUDE group_14_jeek_declare.inc

EXTERN map:DWORD
EXTERN map_size:COORD
EXTERN map_main_color:DWORD
EXTERN level:WORD
EXTERN main_char_location:COORD

.data
dinosaur_location COORD <>
dinosaur_move_dir DIRECTION ?
sum_of_dinosaur DWORD ?
.code
DinosaurProc PROC
while1:
	jmp while1
	ret
DinosaurProc ENDP

DinosaurMove PROC
	ret
DinosaurMove ENDP
END