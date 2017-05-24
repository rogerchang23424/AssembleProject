INCLUDE Irvine32.inc
;包括boolean的相關定義
INCLUDE Bool.inc
INCLUDE group_14_jeek_declare.inc

EXTERN map:DWORD
EXTERN map_size:COORD
EXTERN map_main_color:DWORD
EXTERN level:WORD
EXTERN main_char_location:COORD
EXTERN is_des:BOOL

PUBLIC dinosaur_location
PUBLIC dinosaur_move_dir
PUBLIC sum_of_dinosaur

.data
dinosaur_location COORD <>
dinosaur_move_dir DIRECTION ?
sum_of_dinosaur DWORD ?
.code
DinosaurProc PROC
while1:
	mov al, is_des
	test al, al
	jnz end_proc
	invoke Sleep, 100
	jmp while1

end_proc:
	xor eax, eax
	ret
DinosaurProc ENDP

DinosaurMove PROC
	ret
DinosaurMove ENDP
END