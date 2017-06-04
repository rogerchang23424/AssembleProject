INCLUDE Irvine32.inc
;包括boolean的相關定義
INCLUDE Bool.inc
INCLUDE group_14_jeek_declare.inc

EXTERN map:WORD
EXTERN map_size:COORD
EXTERN map_main_color:DWORD
EXTERN level:WORD
EXTERN main_char_location:COORD
EXTERN is_des:BOOL
EXTERN cs_print:RTL_CRITICAL_SECTION

PUBLIC dinosaur_location
PUBLIC dinosaur_move_dir
PUBLIC sum_of_dinosaur

.data
dinosaur_location COORD 15 DUP(<>)
dinosaur_move_dir DIRECTION 15 DUP (?)
sum_of_dinosaur DWORD ?
.code
DinosaurProc PROC
while1:
	mov ecx, 5
L1:
	mov al, is_des
	test al, al
	jnz end_proc
	push ecx
	invoke Sleep, 100
	pop ecx
	loop L1
	invoke DinosaurMove
	jmp while1

end_proc:
	xor eax, eax
	ret
DinosaurProc ENDP

IsDinosaurBlock PROC, _coord:COORD, _dir:DIRECTION
	movzx eax, _coord.Y
	mov ebx, 34
	imul ebx
	movzx edx, _coord.X
	shl edx, 1
	add eax, edx
	mov esi, OFFSET map
	add esi, eax		;將esi指向該地圖的點

	cmp _dir, DIR_LEFT
	je move_left
	cmp _dir, DIR_RIGHT
	je move_right
	cmp _dir, DIR_UP
	je move_up
	cmp _dir, DIR_DOWN
	je move_down
	jmp cannot_move

move_left:
	sub _coord.X, 1
	js cannot_move
	sub esi, 2
	jmp next

move_right:
	add _coord.X, 1
	cmp _coord.X, 17
	jge cannot_move
	add esi, 2
	jmp next

move_up:
	sub _coord.Y, 1
	js cannot_move
	sub esi, 34
	jmp next

move_down:
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge cannot_move
	add esi, 34
	jmp next

next:
	cmp word ptr [esi], 3		;是否為牆壁
	jle cannot_move
	cmp word ptr [esi], 12		;是否為核廢料罐、門、鑰匙	
	jl can_move
	cmp word ptr [esi], 18		;是否為炸彈、六腳註、寶箱、球
	jle cannot_move
	cmp word ptr [esi], 23		;是否為雷射眼
	je cannot_move

can_move:
	mov eax, 1
	jmp end_proc

cannot_move:
	xor eax, eax
end_proc:
	ret
IsDinosaurBlock ENDP

DinosaurMove PROC
	LOCAL _coord:COORD, _dir:DIRECTION
	mov ecx, sum_of_dinosaur
	test ecx, ecx
	jz end_proc
	mov esi, OFFSET dinosaur_location
	mov edx, OFFSET dinosaur_move_dir
L1:
	push ecx
	mov eax, COORD ptr [esi]
	mov _coord, eax
	mov eax, DIRECTION ptr [edx]
	mov _dir, eax
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jz cannot_move
can_move:
	push esi
	push edx

	movzx eax, _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax		;將esi指向該地圖的點

	cmp _dir, DIR_LEFT
	je move_left
	cmp _dir, DIR_RIGHT
	je move_right
	cmp _dir, DIR_UP
	je move_up
	cmp _dir, DIR_DOWN
	je move_down

move_left:
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord
	sub _coord.X, 1
	sub esi, 2
	mov word ptr [esi], 3
	invoke PrintDinosaur, _coord
	jmp end_move

move_right:
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord
	add _coord.X, 1
	add esi, 2
	mov word ptr [esi], 3
	invoke PrintDinosaur, _coord
	jmp end_move

move_up:
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord
	sub _coord.Y, 1
	sub esi, 34
	mov word ptr [esi], 3
	invoke PrintDinosaur, _coord
	jmp end_move

move_down:
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord
	add _coord.Y, 1
	add esi, 34
	mov word ptr [esi], 3
	invoke PrintDinosaur, _coord
	jmp end_move

end_move:
	mov eax, _coord
	pop edx
	pop esi
	mov COORD ptr [esi], eax
	cmp eax, main_char_location
	jne next
	call SendDeadMessage
	jmp next

cannot_move:
	cmp _dir, DIR_LEFT
	je left_change
	cmp _dir, DIR_RIGHT
	je right_change
	cmp _dir, DIR_UP
	je up_change
	cmp _dir, DIR_DOWN
	je down_change

left_change:
	mov _dir, DIR_DOWN
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	mov _dir, DIR_UP
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	mov _dir, DIR_RIGHT
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	jmp next

right_change:
	mov _dir, DIR_UP
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	mov _dir, DIR_DOWN
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	mov _dir, DIR_LEFT
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	jmp next

up_change:
	mov _dir, DIR_LEFT
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	mov _dir, DIR_RIGHT
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	mov _dir, DIR_DOWN
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	jmp next

down_change:
	mov _dir, DIR_RIGHT
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	mov _dir, DIR_LEFT
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	mov _dir, DIR_UP
	push esi
	push edx
	invoke IsDinosaurBlock, _coord, _dir
	pop edx
	pop esi
	test eax, eax
	jnz change_dir
	jmp next

change_dir:
	mov eax, _dir
	mov DIRECTION ptr [edx], eax

next:
	add esi, TYPE COORD
	add edx, TYPE DIRECTION
	pop ecx
	sub ecx, 1
	jnz L1

end_proc:
	ret
DinosaurMove ENDP

AddDinosaur PROC, _coord:COORD
	mov eax, sum_of_dinosaur
	mov ebx, _coord
	mov COORD ptr [(OFFSET dinosaur_location) + eax*(TYPE COORD)], ebx
	invoke PrintDinosaur, COORD ptr [(OFFSET dinosaur_location) + eax*(TYPE COORD)]
	mov dword ptr [(OFFSET dinosaur_move_dir) + eax*(TYPE dinosaur_move_dir)], DIR_RIGHT
	inc sum_of_dinosaur
	ret
AddDinosaur ENDP

PrintDinosaur PROC, _loc:COORD
	push eax
	push edx

	invoke EnterCriticalSection, ADDR cs_print

	mov ax, _loc.Y
	add ax, 4
	mov dl, al
	shl dx, 8
	mov ax, _loc.X
	add ax, ax
	add ax, 9
	add dl, al
	call Gotoxy		;將地圖的位置轉換成主控台的位置

	call print_dinosaur

	invoke LeaveCriticalSection, ADDR cs_print		;離開關鍵區域

	pop edx
	pop eax
	ret
PrintDinosaur ENDP
END