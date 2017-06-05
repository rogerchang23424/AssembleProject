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
EXTERN is_hidden:BOOL

PUBLIC temp_laser_location
PUBLIC sum_of_laser_eye

.data
temp_laser_location COORD <>
laser_eye_location COORD 20 DUP(<>)
sum_of_laser_eye DWORD 0

.code
LaserEyeCheck PROC
	LOCAL _coord:COORD
while1:
	invoke Sleep, 10
	mov al, is_des
	test al, al
	jnz end_proc
	mov al, is_hidden
	test al, al
	jnz while1
	mov ecx, sum_of_laser_eye
	test ecx, ecx
	jz while1
	mov esi, OFFSET laser_eye_location
L1:
	push esi
	push ecx
	mov eax, dword ptr [esi]
	mov _coord, eax				;_coord保存該雷射演座標
	mov ax, main_char_location.X
	cmp (COORD ptr [esi]).X, ax
	je y_insight
	mov ax, main_char_location.Y
	cmp (COORD ptr [esi]).Y, ax
	je x_insight
	jmp next_step

y_insight:
	mov ax, main_char_location.Y
	cmp (COORD ptr [esi]).Y, ax		;雷射眼.Y > 主角.Y，代表在上面
	jl at_down

at_top:
	movzx eax, _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax

at_top_continue:
	sub _coord.Y, 1
	js next_step
	sub esi, 34
	cmp word ptr [esi], 5
	jne next_step
	mov eax, _coord
	cmp main_char_location, eax
	jne skip1
	call SendDeadMessage
	jmp next_step
skip1:
	jmp at_top_continue

at_down:
	movzx eax, _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax

at_down_continue:
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge next_step
	add esi, 34
	cmp word ptr [esi], 5
	jne next_step
	mov eax, _coord
	cmp main_char_location, eax
	jne skip2
	call SendDeadMessage
	jmp next_step
skip2:
	jmp at_down_continue

x_insight:
	mov ax, main_char_location.X
	cmp (COORD ptr [esi]).X, ax		;雷射眼.X > 主角.X，代表在左邊
	jg at_left
at_right:
	movzx eax, _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax

at_right_continue:
	add _coord.X, 1
	cmp _coord.X, 17
	jge next_step
	add esi, 2
	cmp word ptr [esi], 5
	jne next_step
	mov eax, _coord
	cmp main_char_location, eax
	jne skip3
	call SendDeadMessage
	jmp next_step
skip3:
	jmp at_right_continue

at_left:
	movzx eax, _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax

at_left_continue:
	sub _coord.X, 1
	js next_step
	sub esi, 2
	cmp word ptr [esi], 5
	jne next_step
	mov eax, _coord
	cmp main_char_location, eax
	jne skip4
	call SendDeadMessage
	jmp next_step
skip4:
	jmp at_left_continue

next_step:
	pop ecx
	pop esi
	add esi, TYPE COORD
	dec ecx
	jnz L1
	jmp while1

end_proc:
	xor eax, eax
	ret
LaserEyeCheck ENDP

AddLaserEye PROC
	mov eax, sum_of_laser_eye
	mov ebx, temp_laser_location
	mov COORD ptr [(OFFSET laser_eye_location) + eax*(TYPE COORD)], ebx
	inc sum_of_laser_eye
	ret
AddLaserEye ENDP
END