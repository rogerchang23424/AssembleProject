TITLE 時人花                (jeek.ASM)

;地圖資料儲存號碼 
;         1 牆壁
;		  2 冰與泥土牆壁
;         3 泥土牆壁
;         4 花朵
;         5 地板
;         6 蘋果
;         7 香菇
;         8 食人花(開)
;         9 食人花(小)
;        10 食人花(中)
;        11 食人花(大)
;        12 核廢料
;        13 門
;        14 鑰匙
;        15 炸彈
;        16 六角形
;        17 寶箱
;        18 球
;        19 毒菇
;		 20 藍花
;        21 藍黃交替店
;        22 隱形藥
;        23 雷射眼
;        24 恐龍
;		 25 啟動中的炸彈

INCLUDE Irvine32.inc
;包括boolean的相關定義
INCLUDE Bool.inc
INCLUDE group_14_jeek_declare.inc

; main          EQU start@0
EXTERN hout:DWORD
EXTERN hin:DWORD
EXTERN dinosaur_location:COORD
EXTERN dinosaur_move_dir:DIRECTION
EXTERN sum_of_dinosaur:DWORD
EXTERN temp_laser_location:COORD
EXTERN sum_of_laser_eye:DWORD

PUBLIC map
PUBLIC map_size
PUBLIC map_main_color
PUBLIC level
PUBLIC main_char_location
PUBLIC is_des
PUBLIC piranha_sta
PUBLIC piranha_in
PUBLIC dinosaur
PUBLIC cs_print
PUBLIC act
PUBLIC print_method
PUBLIC is_hidden

.data
map WORD 12 DUP(17 DUP(?))
map_main_color DWORD 0
map_size COORD <>

;字串圖形區，起始點
flower WORD 058Dh, 0 ; "֍"
score_name BYTE "分數:", 0
level_name BYTE "等級:", 0
key_name BYTE "鑰匙:", 0
explosion_time BYTE "炸彈啟動:", 0
win_message BYTE "You win!", 0
lose_message BYTE "Wou lose.", 0
square WORD 25a0h, 0 ; "■"
apple WORD 860bh, 0  ; "蘋"
piranha_open WORD 958bh, 0 ; "開"
piranha_small WORD 5c0fh, 0 ; "小"
piranha_medium WORD 4e2dh, 0 ; "中"
piranha_big WORD 5927h, 0   ; "大"
medium_shade WORD 2593h, 0 ; "▓"
mushroom WORD 83c7h, 0	; "菇"
act WORD 32a3h, 0		; "㊣"
ball WORD 25cfh, 0		; "●"
space WORD 20h, 20h, 0	; "  "
key WORD 0e192h, 0		; ""
door WORD 03a0h, 0		; "Π"
bomb WORD 06ddh, 0		; "۝"
nuclear WORD 2605h, 0	; "★"
hexagon WORD 2b23h, 0	; "⬣"
box WORD 0e130h, 0		; ""
hidden_pill WORD 24beh, 0 ; "Ⓘ"
laser_eye WORD 2299h, 0 ; "⊙"
dinosaur WORD 9f8dh, 0 ; "龍"
lefttop WORD 2554h, 0	; "╔"
righttop WORD 2557h, 0	; "╗"
cross   WORD 256ch, 0	; "╬"
leftdown WORD 255ah, 0	; "╚"
rightdown WORD 255dh, 0	; "╝"
horizon  WORD 2550h, 0	; "═"
vertical WORD 2551h, 0	; "║"
;字串圖形區，終點

;主角位置
main_char_location COORD <>

;print_method 為放置所有印出函數位址的陣列
print_method DWORD 0, print_wall, print_ice_dirt_wall, print_dirt_wall, print_flower
			 DWORD print_floor, print_apple, print_mushroom, print_piranha_open
			 DWORD print_piranha_small, print_piranha_medium, print_piranha_big
			 DWORD print_nuclear, print_door, print_key, print_bomb, print_hexagon
			 DWORD print_box, print_ball, print_toxic_mushroom, print_blue_flower
			 DWORD print_cross_pad, print_hidden_pill, print_laser_eye, print_dinosaur, print_active_bomb

safe_print_method DWORD 0, PrintMainChar, PrintScore, PrintLevel, PrintKeys, PrintActiveBombCount, PrintTime
			      DWORD PrintDinosaur
;表示有哪些十人花在吃
piranha_sta PIRANHA_STATUS 20 DUP(<>)
piranha_in BYTE 0

;分數
score DWORD 0

;階級
level WORD 0

;是否有鑰匙
keys BOOL FALSE

;計時器
counter DWORD 0

;啟動時間
startTime DWORD 0

;現在時間
curTime DWORD 0

;隱藏時間結束戳記
hidden_end DWORD 0

is_eat BOOL FALSE	;主角有沒有被吃
is_des BOOL FALSE	;是否抵達終點
is_removing_hexagon BOOL FALSE ;是否正在移除物品
force_destination BOOL FALSE	;強制抵達終點，用來偵錯
is_exit_key BOOL FALSE			;是否按下離開建
is_function_key BOOL FALSE		;是否按下f2
is_hidden BOOL FALSE		;角色是否隱藏

print_int BYTE "%d", 0
print_short BYTE "%hd", 0
time_format BYTE "%02d:%02d", 0
num_of_thread DWORD 0	;有多少個分流
threads HANDLE 10 DUP(?)	;為一個放置THREAD HANDLE的陣列
t_value DWORD 0

cs_print RTL_CRITICAL_SECTION <>
cs_bomb RTL_CRITICAL_SECTION <>
cs_piranha RTL_CRITICAL_SECTION <>

active_bomb_location BOMB_STATUS 10 DUP(<>)		;有哪些位置的炸彈是啟動的
active_bomb_count DWORD 0	;炸彈啟動總數
active_hexagon COORD <-1,-1>	;啟動消除位置
hexagon_near_tag BYTE 0		;tag的表示法   0, 0, 0, 0, 上, 下, 左, 右

.code
zeek_pane PROC
	
	call Clrscr
	call InitGameScene	;導入遊戲場景
continue1:
	invoke InitializeCriticalSection, ADDR cs_print		;將輸出主控台關鍵段初始化
	invoke InitializeCriticalSection, ADDR cs_bomb
	invoke InitializeCriticalSection, ADDR cs_piranha
	call LoadMap	;讀取
	call InitiateStatusBar
	call PrintMap	;印出地圖
	call PrintMainChar	;印出主角
while_loop:
	call IsDestination	;是否到了終點
	test eax, eax
	jnz next_game	;是的話下一關
	call MoveCharactor	;移動角色
	mov al, is_eat
	test al, al
	jnz lose_game	;被吃的話，結束遊戲

	jmp while_loop
next_game:
	mov is_des, TRUE
	invoke WaitForMultipleObjects, num_of_thread, OFFSET threads, TRUE, INFINITE ;等待所有執行緒結束
	invoke DeleteCriticalSection, ADDR cs_print		;刪除cs_print關鍵區域
	invoke DeleteCriticalSection, ADDR cs_bomb		;刪除cs_bomb關鍵區域
	invoke DeleteCriticalSection, ADDR cs_piranha   ;刪除cs_piranha關鍵區域
	cmp level, TOTAL_LEVEL	;檢查所有關是否已過
	jne continue1
	mov al, is_function_key		;有沒有作弊
	test al, al
	jnz end_game	;如果有不顯示勝利畫面
	call WinGame	;把贏的畫面寫出來
	jmp end_game	

lose_game:
	mov is_des, TRUE
	invoke WaitForMultipleObjects, num_of_thread, OFFSET threads, TRUE, INFINITE;等待所有執行緒結束
	invoke DeleteCriticalSection, ADDR cs_print		;刪除cs_print關鍵區域
	invoke DeleteCriticalSection, ADDR cs_bomb		;刪除cs_bomb關鍵區域
	invoke DeleteCriticalSection, ADDR cs_piranha   ;刪除cs_piranha關鍵區域
	mov al, is_exit_key		;是否按下離開建
	test al, al
	jnz end_game			;直接結束遊戲
	call LoseGame			;顯示輸遊戲畫面

end_game:
	call ExitZeekProcess	;清除所有執行留下來的資料
	ret
zeek_pane ENDP

ConsoleCompatibility PROC
	LOCAL osvi:OSVERSIONINFO

	mov osvi.dwOSVersionInfoSize, SIZEOF OSVERSIONINFO	; 初始化 OSVERSIONINFO之 dwOSVersionInfoSize

	invoke GetVersionExA, ADDR osvi	;取得作業系統版本訊息，並寫入在osvi
	mov eax, osvi.dwMajorVersion	
	cmp eax, 10						;檢查使用者的作業系統是否為Windows 10
	jge end_proc

	mov key, 9470h	; "鑰"
	mov flower, 82b1h ; "花" 
	mov bomb, 5f48h ; "彈"
	mov hexagon, 67f1h	; "柱"
	mov box, 7bb1h	; "箱"
	mov hidden_pill, 2460h ; "①"

end_proc:
	ret
ConsoleCompatibility ENDP

InitGameScene PROC
	;左半部部分
	LOCAL csbi:CONSOLE_SCREEN_BUFFER_INFO
	invoke WriteWideString, hout, OFFSET lefttop	;印出左上角的符號
	mov ecx, 28
L1:
	push ecx
	invoke WriteWideString, hout, OFFSET horizon	;印出水平線的符號
	pop ecx
	loop L1
	invoke WriteWideString, hout, OFFSET righttop	;印出右上角的符號
	mov ecx, 23
L2:
	call Crlf	;印出換行符
	push ecx	;自己保留ecx暫存器的值，因為Kernel32.dll的函式庫不會幫你保留暫存器的值
	invoke WriteWideString, hout, OFFSET vertical	;印出垂直符
	invoke GetConsoleScreenBufferInfo, hout, ADDR csbi	;獲取主控台螢幕緩衝資訊
	add csbi.dwCursorPosition.X, 56						;跳至最右端
	invoke SetConsoleCursorPosition, hout, csbi.dwCursorPosition	;設定游標位置
	invoke WriteWideString, hout, OFFSET vertical	;印出垂直符
	pop ecx		;取出ECX
	loop L2
	
	call Crlf
	invoke WriteWideString, hout, OFFSET leftdown		;印出左下角符
	mov ecx, 28
L3:
	push ecx
	invoke WriteWideString, hout, OFFSET horizon		;印出水平線
	pop ecx
	loop L3
	invoke WriteWideString, hout, OFFSET rightdown		;印出右下角符
	
	;右半部部分
	mov dl, 60
	mov dh, 0
	call Gotoxy
	invoke WriteWideString, hout, OFFSET lefttop		;印出左上角
	mov ecx, 7
L4:
	push ecx
	invoke WriteWideString, hout, OFFSET horizon	    ;印出水平線
	pop ecx
	loop L4
	invoke WriteWideString, hout, OFFSET righttop		;印出右上角
	
	mov ecx, 23
L5:
	call Crlf
	push ecx
	invoke GetConsoleScreenBufferInfo, hout, ADDR csbi;獲取主控台螢幕緩衝資訊
	add csbi.dwCursorPosition.X, 60
	invoke SetConsoleCursorPosition, hout, csbi.dwCursorPosition	;設定游標位置
	invoke WriteWideString, hout, OFFSET vertical
	invoke GetConsoleScreenBufferInfo, hout, ADDR csbi;獲取主控台螢幕緩衝資訊
	add csbi.dwCursorPosition.X, 14
	invoke SetConsoleCursorPosition, hout, csbi.dwCursorPosition	;設定游標位置
	invoke WriteWideString, hout, OFFSET vertical
	pop ecx
	loop L5
	
	mov dl, 60
	mov dh, 24
	call Gotoxy
	invoke WriteWideString, hout, OFFSET leftdown	;印出左下角符
	mov ecx, 7
L6:
	push ecx
	invoke WriteWideString, hout, OFFSET horizon	;印出水平線
	pop ecx
	loop L6
	invoke WriteWideString, hout, OFFSET rightdown	;印出右下角符
	
	mov dl, 64
	mov dh, 3
	call Gotoxy
	invoke myprint, hout, OFFSET score_name		;顯示 "分數" 字串
	
	mov dl, 64
	mov dh, 4
	call Gotoxy
	invoke myprint, hout, OFFSET level_name		;顯示 "階級" 字串

	mov dl, 64
	mov dh, 5
	call Gotoxy
	invoke myprint, hout, OFFSET key_name		;顯示 "鑰匙" 字串

	mov dl, 64
	mov dh, 6
	call Gotoxy
	invoke myprint, hout, OFFSET explosion_time	;顯示 "爆炸時間" 字串
	ret
InitGameScene ENDP

InitiateStatusBar PROC
	call PrintScore		;印出初始化分數
	call PrintLevel		;印出階級
	call PrintKeys		;印出鑰匙個數
	call PrintActiveBombCount		;印出幾秒後爆炸
	call clock
	mov startTime, eax
	call PrintTime

	call StartPiranhaThread			;開始時人花狀態分流
	call StartItemCheckerThread
	call StartTimeThread	;開始計時器分流
	call StartDinosaurProcessThread
	call StartLaserEyeThread

	ret
InitiateStatusBar ENDP

PrintMap PROC
	LOCAL _coord:COORD

	mov esi, OFFSET map ;esi為地圖指標
	
	mov _coord.Y, 0
	jmp check_y_forloop1	;先檢查y是否小於地圖大小的y
y_forloop1:

	mov _coord.X, 0
	jmp check_x_forloop1	;先檢查x是否小於地圖大小的x
x_forloop1:
	cmp word ptr [esi], 24
	jne skip
	invoke AddDinosaur, _coord
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;將該元素的位置印出來
	mov word ptr [esi], 5
	jmp next
skip:
	cmp word ptr [esi], 23
	jne skip_laser
	mov eax, _coord
	mov temp_laser_location, eax
	call AddLaserEye
skip_laser:
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;將該元素的位置印出來
next:
	add esi, 2
	add _coord.X, 1
check_x_forloop1:
	mov ax, _coord.X
	cmp ax, map_size.X			;比較x是否大於map_size的X
	jl  x_forloop1

	add _coord.Y, 1
check_y_forloop1:
	mov ax, _coord.Y
	cmp ax, map_size.Y			;比較y是否大於map_size的Y
	jl y_forloop1

	ret
PrintMap ENDP

PrintMapElement PROC,
	_data:WORD, x_coord:WORD, y_coord:WORD
	push esi

	mov ax, y_coord
	add ax, 4
	mov dl, al
	shl dx, 8
	mov ax, x_coord
	add ax, ax
	add ax, 9
	add dl, al
	call Gotoxy			;將地圖的位置轉換成主控台的位置
	
	mov esi, OFFSET print_method	;將esi設定成print_method函式指標陣列的頭，並依照資料的編號來決定印出的資料
	movzx ecx, _data
	shl ecx, 2
	add esi, ecx
	call dword ptr [esi]

	pop esi
	ret
PrintMapElement ENDP

cleanMap PROC	;此函式顧名思義就是把所有的資料恢復原始，除了level以外
	push edi
	push ecx

	mov edi, OFFSET map		;esi為地圖資料的指標
	mov ecx, 12*17			;ecx為迴圈要執行的次數
	xor eax, eax
	cld
	rep stosw

	mov map_size.X, 0			;清除地圖大小資料
	mov map_size.Y, 0
	mov main_char_location.X, 0	;清除主角位置資料
	mov main_char_location.Y, 0

	;將相關資料清除
	mov piranha_in, 0
	mov score, 0
	mov is_des, FALSE
	mov num_of_thread, 0
	mov keys, 0
	mov counter, 0
	mov active_bomb_count, 0
	mov is_removing_hexagon, FALSE
	mov sum_of_dinosaur, 0
	mov sum_of_laser_eye, 0
	mov is_hidden, FALSE
	mov hidden_end, 0

	pop ecx
	pop edi
	ret
cleanMap ENDP

PrintMainChar PROC
	LOCAL to_cmd_loc:COORD
	mov ax, main_char_location.Y
	add ax, 4
	mov dl, al
	shl dx, 8
	mov ax, main_char_location.X
	add ax, ax
	add ax, 9
	add dl, al
	call Gotoxy		;將地圖的位置轉換成主控台的位置

	mov al, is_hidden
	test al, al
	jz print_show

	mov eax, 1
	call SetTextColor
	invoke WriteWideString, hout, OFFSET act   ;把角色印出來
	jmp end_print_main_proc

print_show:
	mov eax, 12
	call SetTextColor
	invoke WriteWideString, hout, OFFSET act   ;把角色印出來

end_print_main_proc:
	ret
PrintMainChar ENDP

StartPiranhaThread PROC
	LOCAL pid:DWORD
	push esi
	push edx

	lea esi, pid
	push esi
	push 0
	push 0
	push CheckPiranhaStatus
	push 0
	push 0
	call CreateThread@24	;啟動檢查食人花的執行緒

	mov esi, OFFSET threads
	mov edx, num_of_thread
	shl edx, 2
	add esi, edx
	mov HANDLE PTR [esi], eax
	add num_of_thread, 1		;將該執行緒存到執行緒陣列裡

	pop edx
	pop esi
	ret
StartPiranhaThread ENDP

StartItemCheckerThread PROC
	LOCAL pid:DWORD
	push esi

	lea esi, pid
	push esi
	push 0
	push 0
	push ItemChecker
	push 0
	push 0
	call CreateThread@24	;啟動檢查物件的執行緒

	mov esi, OFFSET threads
	mov edx, num_of_thread
	shl edx, 2
	add esi, edx
	mov HANDLE PTR [esi], eax
	add num_of_thread, 1		;將該執行緒存到執行緒陣列裡

	pop esi
	ret
	ret
StartItemCheckerThread ENDP

StartTimeThread PROC
	LOCAL pid:DWORD
	push esi

	lea esi, pid
	push esi
	push 0
	push 0
	push TimeCounter
	push 0
	push 0
	call CreateThread@24	;啟動檢查計時器的執行緒

	mov esi, OFFSET threads
	mov edx, num_of_thread
	shl edx, 2
	add esi, edx
	mov HANDLE PTR [esi], eax
	add num_of_thread, 1		;將該執行緒存到執行緒陣列裡

	pop esi
	ret
StartTimeThread ENDP

StartDinosaurProcessThread PROC
	LOCAL pid:DWORD
	push esi

	lea esi, pid
	push esi
	push 0
	push 0
	push DinosaurProc
	push 0
	push 0
	call CreateThread@24	;啟動恐龍控制的執行緒

	mov esi, OFFSET threads
	mov edx, num_of_thread
	shl edx, 2
	add esi, edx
	mov HANDLE PTR [esi], eax
	add num_of_thread, 1		;將該執行緒存到執行緒陣列裡

	pop esi
	ret
StartDinosaurProcessThread ENDP

StartLaserEyeThread PROC
	LOCAL pid:DWORD
	push esi

	lea esi, pid
	push esi
	push 0
	push 0
	push LaserEyeCheck
	push 0
	push 0
	call CreateThread@24	;啟動雷射眼的執行緒

	mov esi, OFFSET threads
	mov edx, num_of_thread
	shl edx, 2
	add esi, edx
	mov HANDLE PTR [esi], eax
	add num_of_thread, 1		;將該執行緒存到執行緒陣列裡

	pop esi
	ret
StartLaserEyeThread ENDP

IsDestination PROC
	mov al, force_destination		;檢查是否強制終點
	test al, al
	jnz func_key

    movzx eax, main_char_location.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, main_char_location.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map		
	add esi, eax		;把esi指向該地圖的那個點
	cmp word ptr [esi], 7	;看看是否為終點
	je is_destination	;是的話回傳TRUE
	mov eax, FALSE		;沒跳躍表示不是終點，回傳FALSE
	jmp end_check

func_key:
	mov force_destination, FALSE	;將強制終點設定成否
is_destination:
	mov eax, TRUE

end_check:
	ret 
IsDestination ENDP

MoveCharactor PROC
    LOCAL uppergetch:BYTE, lowergetch:BYTE, temp:COORD
	call ReadChar	;等待使用者輸入
	mov uppergetch, ah
	mov lowergetch, al
	
	cmp al, 0		;判斷是否為擴張鍵
	je extend_method
	cmp al, 27		;esc
	je esc_method
	cmp al, 6ch
	je l_method
	cmp al, 4ch
	je l_method
	jmp end_switch
extend_method:
	cmp ah, 4bh		 ;left-allow
	je left_method
	cmp ah, 4dh		 ;right-allow
	je right_method
	cmp ah, 48h		 ;up-allow
	je up_method
	cmp ah, 50h		 ;down-allow
	je down_method
	cmp ah, 3bh		 ;f1
	je f1_method
	cmp ah, 3ch		 ;f2
	je f2_method
	jmp end_switch
left_method:
	;測試左邊是否可以過去
	mov ax, main_char_location.X
	sub ax, 1
	mov temp.X, ax
	mov ax, main_char_location.Y
	mov temp.Y, ax
	cmp temp.X, 0
	jl cannot_move

	;檢查新位置是否有磚塊
	invoke IsBlock, temp, FALSE
	test eax, eax
	jnz cannot_move

	;檢查物品是否可搬動
	invoke ItemCanMove, temp, DIR_LEFT
	test eax, eax
	jz cannot_move

	;檢查是否有鑰匙，如果沒有就吃掉。門的時候，如果有鑰匙則打開門
	invoke EatKeyAndOpenDoor, temp
	test eax, eax
	jz cannot_move
	jmp can_move
right_method:
	;測試右邊是否可以過去
	mov ax, main_char_location.X
	add ax, 1
	mov temp.X, ax
	mov ax, main_char_location.Y
	mov temp.Y, ax
	cmp temp.X, 17
	jge cannot_move

	;檢查新位置是否有磚塊
	invoke IsBlock, temp, FALSE
	test eax, eax
	jnz cannot_move

	;檢查物品是否可搬動
	invoke ItemCanMove, temp, DIR_RIGHT
	test eax, eax
	jz cannot_move

	;檢查是否有鑰匙，如果沒有就吃掉。門的時候，如果有鑰匙則打開門
	invoke EatKeyAndOpenDoor, temp
	test eax, eax
	jz cannot_move
	jmp can_move
up_method:
	;測試上面是否可以過去
	mov ax, main_char_location.X
	mov temp.X, ax
	mov ax, main_char_location.Y
	sub ax, 1
	mov temp.Y, ax
	cmp ax, 0
	jl cannot_move

	;檢查新位置是否有磚塊
	invoke IsBlock, temp, FALSE
	test eax, eax
	jnz cannot_move

	;檢查物品是否可搬動
	invoke ItemCanMove, temp, DIR_UP
	test eax, eax
	jz cannot_move

	;檢查是否有鑰匙，如果沒有就吃掉。門的時候，如果有鑰匙則打開門
	invoke EatKeyAndOpenDoor, temp
	test eax, eax
	jz cannot_move
	jmp can_move
down_method:
	;測試下面是否可以過去
	mov ax, main_char_location.X
	mov temp.X, ax
	mov ax, main_char_location.Y
	add ax, 1
	mov temp.Y, ax
	cmp ax, map_size.Y
	jge cannot_move

	;檢查新位置是否有磚塊
	invoke IsBlock, temp, FALSE
	test eax, eax
	jnz cannot_move

	;檢查物品是否可搬動
	invoke ItemCanMove, temp, DIR_DOWN
	test eax, eax
	jz cannot_move

	;檢查是否有鑰匙，如果沒有就吃掉。門的時候，如果有鑰匙則打開門
	invoke EatKeyAndOpenDoor, temp
	test eax, eax
	jz cannot_move
	jmp can_move
f1_method:
	mov force_destination, TRUE		;將強制終點設為TRUE
	sub level, 1
	jmp cannot_move		;不移動角色
f2_method:
	mov force_destination, TRUE		;將強制終點設為TRUE
	mov is_function_key, TRUE
	jmp cannot_move		;不移動角色
esc_method:
	mov is_exit_key, TRUE
	jmp is_dead
l_method:
	jmp is_dead

end_switch:
	jmp cannot_move
can_move:
	;角色有沒有經過食人花
	invoke SetPiranhaOpen, main_char_location
	movzx eax, main_char_location.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, main_char_location.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], main_char_location
	;改變角色位置
	mov ax, temp.X
	mov main_char_location.X, ax
	mov ax, temp.Y
	mov main_char_location.Y, ax

	;將腳色印出來
	invoke SafePrintObject, PRINT_MAIN_CHAR, 0, main_char_location
	call IsFlowerAndBoxEat

	;吃到假的物品
	invoke EatFakeItem, main_char_location
	test eax, eax
	jnz is_dead

	;檢查張口的食人花是否在附近
	invoke IsPiranhaNear, main_char_location
	test eax, eax
	jz skip

is_dead:
	mov is_eat, al	;表示已陣亡

skip:
cannot_move:
	ret
MoveCharactor ENDP

IsBlock PROC, _coord:COORD, forcewall:BOOL
	push esi
	push ebx
	push edx	;將會用到的暫存器存入堆疊裡，除了回傳值

	movzx eax, _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax	;將esi指向該地圖的點

	mov al, forcewall
	test al, al
	jz not_force_wall	;是否把時人花當作障礙物
	
	cmp word ptr [esi], 1	;編號1~3代表強
	jl later_compare
	cmp word ptr [esi], 3
	jle is_block 

later_compare:
	cmp word ptr [esi], 12	;編號12代表核廢料罐
	je is_block
	jmp not_block

not_force_wall:
	;if((map[y][x] >= 0 && map[y][x] <= 3) || (map[y][x] >= 8 && map[y][x] <= 11))
	;	return ture
	;else
	;	return false
	cmp word ptr [esi], 1	;編號1~3代表強
	jl later_compare2
	cmp word ptr [esi], 3
	jle is_block

later_compare2:
	cmp word ptr [esi], 8	;編號8~11代表時人花各種狀態編號
	jl not_block

later_compare3:
	cmp word ptr [esi], 23
	jne not_block

is_block:
	mov eax, 1
	jmp end_of_procedure

not_block:
	xor eax, eax

end_of_procedure:
	pop edx		;還原堆疊裡的暫存器
	pop ebx
	pop esi
	ret
IsBlock ENDP

IsFlowerAndBoxEat PROC
	push eax
	push ebx
	push edx
	push esi	;將會用到的暫存器壓入堆疊

	movzx eax, main_char_location.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, main_char_location.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax			;將esi指向該地圖的點
	cmp word ptr [esi], 4	;是否為黃花
	je eat_flower
	cmp word ptr [esi], 17	;是否為寶相
	je eat_box
	cmp word ptr [esi], 21	;是否為藍黃交替店
	je change_flower
	cmp word ptr [esi], 22
	je eat_pill
	jmp end_procedure

eat_flower:
	mov word ptr [esi], 5	;將該點更正為空地
	add score, 50
	invoke SafePrintObject, PRINT_SCORE, 0, main_char_location	;印出分數
	jmp end_procedure
eat_box:
	mov word ptr [esi], 5	;將該點更正為空地
	add score, 1000
	invoke SafePrintObject, PRINT_SCORE, 0, main_char_location	;印出分數
	jmp end_procedure
change_flower:
	mov word ptr [esi], 5	;將該點更正為空地
	call YellowAndBlueExchange	;將藍花與黃花交替
	jmp end_procedure
eat_pill:
	mov word ptr [esi], 5	;將該點更正為空地
	call SetHidden	;將角色隱藏
	jmp end_procedure
end_procedure:
	pop esi
	pop edx
	pop ebx
	pop eax			;從堆疊取出
	ret
IsFlowerAndBoxEat ENDP

EatFakeItem PROC, _coord:COORD
	push ebx
	push edx
	push esi		;將會用到的暫存器壓入堆疊

	movzx eax,  _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx,  _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax			;將esi指向該地圖的點
	cmp word ptr [esi] ,19	;吃到毒菇
	jl false_method
	cmp word ptr [esi], 20	;吃到藍花
	jg false_method

true_method:
	mov eax, 1
	jmp end_proc

false_method:
	xor eax, eax

end_proc:
	pop esi
	pop edx
	pop ebx		;從堆疊取出
	ret
EatFakeItem ENDP

EatKeyAndOpenDoor PROC, _coord:COORD
	push esi
	push ebx
	push edx		;將暫存器放入堆疊，除了回傳值

	movzx eax, _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax		;將esi指向該地圖的點

	;檢查是否為門
	cmp word ptr [esi], 13
	je is_door
	;檢查是否為鑰匙
	cmp word ptr [esi], 14
	je is_key
	jmp can_move

is_door:
	mov al, keys
	test al, al		;看看使用者有沒有鑰匙，沒有鑰匙，無法開門
	jz cannot_move
	sub keys, 1		;用掉一把鑰匙
	invoke SafePrintObject, PRINT_KEYS, 0, main_char_location	;將鑰匙狀態印出來
	mov word ptr [esi] ,5		;設定該點為空地
	invoke SafePrintObject, MAP_ELEMENT, 5, _coord		;將地圖元素印出來
	jmp can_move

is_key:
	mov al, keys
	test al, al		;檢查使用者有沒有持鑰匙，如果有就無法拾取
	jnz cannot_move
	add keys, 1		;主角手上多一把鑰匙
	invoke SafePrintObject, PRINT_KEYS, 0, main_char_location	;將鑰匙狀態印出來
	mov word ptr [esi] ,5		;設定該點為空地
	invoke SafePrintObject, MAP_ELEMENT, 5, _coord		;將地圖元素印出來
	jmp can_move

cannot_move:
	mov eax, 0
	jmp end_proc

can_move:
	mov eax, 1

end_proc:
	pop edx
	pop ebx
	pop esi		;將暫存器從堆疊取出
	ret
EatKeyAndOpenDoor ENDP

IsPiranhaNear PROC, _coord:COORD
    LOCAL temp:COORD
	push ebx
	push edx		;將暫存器放入堆疊

	mov al, is_hidden
	test al, al
	jnz not_near

	mov ax, _coord.X
	mov temp.X, ax
	mov ax, _coord.Y
	mov temp.Y, ax
	movzx eax, temp.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, temp.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax		;將esi指向該地圖的點

	;檢查上面是否有十人花
	sub temp.Y, 1
	js next2			;有沒有越界
	sub esi, 34
	cmp word ptr [esi], 8
	mov eax, DIR_UP		;回傳DIR_UP
	je end_proc
	add esi, 34
next2:
	add temp.Y, 1		;回到原本的點

	;檢查下面是否有十人花
	add temp.Y, 1
	cmp temp.Y, 12
	jge next3			;有沒有越界
	add esi, 34
	cmp word ptr [esi], 8
	mov eax, DIR_DOWN	;回傳DIR_DOWN
	je end_proc
	sub esi, 34
next3:
	sub temp.Y, 1		;回到原本的點

	;檢查左邊是否有十人花
	sub temp.X, 1
	js next4			;有沒有越界
	sub esi, 2
	cmp word ptr [esi], 8
	mov eax, DIR_LEFT	;回傳 DIR_LEFT
	je end_proc
	add esi, 2
next4:
	add temp.X, 1		;回到原本的點

	;檢查右邊是否有十人花
	add temp.X, 1
	cmp temp.X, 17
	jge next5			;有沒有越界
	add esi, 2
	cmp word ptr [esi], 8
	mov eax, DIR_RIGHT	;回傳DIR_RIGHT
	je end_proc
	sub esi, 2
next5:
	sub temp.X, 1		;回到原本的點

not_near:
	xor eax, eax		;回傳0
	jmp end_proc

end_proc:
	pop edx
	pop ebx				;從堆疊取回暫存器
	ret
IsPiranhaNear ENDP

ItemCanMove PROC, _coord:COORD, _dir:DIRECTION
	push esi
	push ebx
	push edx		;將暫存器放入堆疊

	movzx eax,  _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx,  _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax	;將esi指向該地圖的點
	cmp word ptr [esi], 6	;是否為蘋果
	je is_apple
	cmp word ptr [esi], 18	;是否為球
	je is_ball
	cmp word ptr [esi], 16	;是否為六角住
	je is_hexagon
	cmp word ptr [esi], 15	;是否為炸彈
	je is_bomb
	cmp word ptr [esi], 25	;是否為啟動中的炸彈
	je is_bomb
	mov eax, 2
	jmp end_process
	
is_apple:
	cmp _dir, DIR_LEFT		;該方向是否為左
	je left_move
	cmp _dir, DIR_RIGHT		;該方向是否為右
	je right_move
	cmp _dir, DIR_UP		;該方向是否為上
	je up_move
	cmp _dir, DIR_DOWN		;該方向是否為下
	je down_move
	jmp cannot_move

left_move:
	sub _coord.X, 1
	js cannot_move		;檢查有沒有越界
    sub esi, 2
	cmp word ptr [esi], 5	;檢查是否有空地
	jne cannot_move
	mov word ptr [esi], 6	;將新位置的點設為蘋果
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;印出蘋果在新的位置
	invoke EatApple, _coord
	add _coord.X, 1
	add esi, 2				;回到原本的點
	mov word ptr [esi], 5	;將就的位置清除
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;印出空白
	jmp end_compare1
right_move:
	add _coord.X, 1
	cmp _coord.X, 17
	jge cannot_move		;檢查有沒有越界
    add esi, 2
	cmp word ptr [esi], 5	;檢查是否有空地
	jne cannot_move
	mov word ptr [esi], 6	;將新位置的點設為蘋果
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;印出蘋果在新的位置
	invoke EatApple, _coord
	sub _coord.X, 1
	sub esi, 2				;回到原本的點
	mov word ptr [esi], 5	;將就的位置清除
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;印出空白
	jmp end_compare1
up_move:
	sub _coord.Y, 1
	js cannot_move			;檢查有沒有越界
	sub esi, 34
	cmp word ptr [esi], 5	;檢查是否有空地
	jne cannot_move
	mov word ptr [esi], 6	;將新位置的點設為蘋果
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出蘋果在新的位置
	invoke EatApple, _coord
	add _coord.Y, 1
	add esi, 34				;回到原本的點
	mov word ptr [esi], 5	;將就的位置清除
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出空白
	jmp end_compare1
down_move:
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge cannot_move		;檢查有沒有越界
	add esi, 34
	cmp word ptr [esi], 5	;檢查是否有空地
	jne cannot_move
	mov word ptr [esi], 6	;將新位置的點設為蘋果
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出蘋果在新的位置
	invoke EatApple, _coord
	sub _coord.Y, 1
	sub esi, 34				;回到原本的點
	mov word ptr [esi], 5	;將就的位置清除
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出空白
	jmp end_compare1

is_ball:
	cmp _dir, DIR_LEFT		;該方向使否為左
	je left_move2
	cmp _dir, DIR_RIGHT		;該方向是否為右
	je right_move2
	cmp _dir, DIR_UP		;該方向是否為上
	je up_move2
	cmp _dir, DIR_DOWN		;該方向是否為下
	je down_move2
	jmp cannot_move

left_move2:
	sub _coord.X, 1
	js cannot_move			;檢查是否越界
	sub esi, 2
	cmp word ptr [esi], 5		;檢查薪點是否為空地
	jne cannot_move			
	mov word ptr [esi], 18
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新的位置設球
	add _coord.X, 1
	add esi, 2					;回到原本的點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原本的空地設為空地
	jmp end_compare1
right_move2:
	add _coord.X, 1
	cmp _coord.X, 17
	jge cannot_move		;檢查有沒有越界
	add esi, 2
	cmp word ptr [esi], 5	;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 18
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為球
	sub _coord.X, 1
	sub esi, 2				;回到原本的點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp end_compare1
up_move2:
	sub _coord.Y, 1
	js cannot_move		;檢查有沒有越界
	sub esi, 34
	cmp word ptr [esi], 5	;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 18
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為球
	add _coord.Y, 1
	add esi, 34				;回到原本的點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp end_compare1
down_move2:
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge cannot_move		;檢查有沒有越界
	add esi, 34
	cmp word ptr [esi], 5		;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 18
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為球
	sub _coord.Y, 1
	sub esi, 34					;回到原本的點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp end_compare1

is_hexagon:
	mov al, is_removing_hexagon
	test al, al
	jnz cannot_move
	cmp _dir, DIR_LEFT	;該方向是否為左
	je left_move3
	cmp _dir, DIR_RIGHT	;該方向是否為右
	je right_move3
	cmp _dir, DIR_UP	;該方向是否為上
	je up_move3
	cmp _dir, DIR_DOWN	;該方向是否為下
	je down_move3
	jmp cannot_move

left_move3:
	sub _coord.X, 1
	js cannot_move		;檢查有沒有越界
	sub esi, 2
	cmp word ptr [esi], 5	;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 16
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為六角柱
	add _coord.X, 1
	add esi, 2				;回到原本的點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp hexagon_next
right_move3:
	add _coord.X, 1
	cmp _coord.X, 17
	jge cannot_move		;檢查有沒有越界
	add esi, 2
	cmp word ptr [esi], 5	;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 16
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為六角住
	sub _coord.X, 1
	sub esi, 2				;回到原本的點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp hexagon_next
up_move3:
	sub _coord.Y, 1
	js cannot_move		;檢查有沒有越界
	sub esi, 34
	cmp word ptr [esi], 5		;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 16
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為六角住
	add _coord.Y, 1
	add esi, 34					;回到原本的點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp hexagon_next
down_move3:
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge cannot_move		;檢查有沒有越界
	add esi, 34
	cmp word ptr [esi], 5		;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 16
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為六角住
	sub _coord.Y, 1
	sub esi, 34					;回到原本的點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp hexagon_next

hexagon_next:
	cmp _dir, DIR_LEFT			;檢查是否往左移
	je left_move3_1
	cmp _dir, DIR_RIGHT			;檢查是否往右移
	je right_move3_1
	cmp _dir, DIR_UP			;檢查是否往上移
	je up_move3_1
	cmp _dir, DIR_DOWN			;檢查是否往下移
	je down_move3_1
	jmp end_process

left_move3_1:
	sub esi, 2
	sub _coord.X, 1
	jmp next_step				;指向新的六角住位置
right_move3_1:
	add esi, 2
	add _coord.X, 1
	jmp next_step				;指向新的六角住位置
up_move3_1:
	sub esi, 34
	add _coord.Y, -1	
	jmp next_step				;指向新的六角住位置
down_move3_1:	
	add esi, 34
	add _coord.Y, 1				;指向新的六角住位置
	jmp next_step

next_step:
	invoke CheckHexagonNear, _coord	;檢查附近有沒有六角柱，如果有就把所有的六角柱消除
	jmp end_compare1

is_bomb:
	cmp _dir, DIR_LEFT		;該方向是否為左
	je left_move4
	cmp _dir, DIR_RIGHT		;該方向是否為右
	je right_move4
	cmp _dir, DIR_UP		;該方向是否為上
	je up_move4
	cmp _dir, DIR_DOWN		;該方向是否為下
	je down_move4
	jmp cannot_move

left_move4:
	sub _coord.X, 1
	js cannot_move		;檢查有沒有越界
	sub esi, 2
	cmp word ptr [esi], 5		;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 25
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為炸彈
	add _coord.X, 1
	add esi, 2					;回到原點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp bomb_next
right_move4:
	add _coord.X, 1
	cmp _coord.X, 17
	jge cannot_move		;檢查有沒有越界
	add esi, 2
	cmp word ptr [esi], 5		;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 25
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為炸彈
	sub _coord.X, 1
	sub esi, 2					;回到原點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp bomb_next
up_move4:
	sub _coord.Y, 1
	js cannot_move		;檢查有沒有越界
	sub esi, 34
	cmp word ptr [esi], 5		;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 25
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為炸彈
	add _coord.Y, 1
	add esi, 34					;回到原點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp bomb_next
down_move4:
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge cannot_move		;檢查有沒有越界
	add esi, 34
	cmp word ptr [esi], 5		;檢查薪點是否有空地
	jne cannot_move
	mov word ptr [esi], 25
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將新點設為炸彈
	sub _coord.Y, 1
	sub esi, 34					;回到原點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將原點設為空地
	jmp bomb_next

bomb_next:
	invoke ChangeBombStatus, _coord, _dir		;改變炸彈狀態

end_compare1:
	mov eax, 1
	jmp end_process		;表示能移動

cannot_move:
	xor eax, eax		;表示不能移動

end_process:
	pop edx
	pop ebx
	pop esi			;從堆疊取出
	ret
ItemCanMove ENDP

CheckHexagonNear PROC, _coord:COORD
	LOCAL hex_near:BOOL, tag:BYTE
		;tag的表示法   0, 0, 0, 0, 上, 下, 左, 右

	mov hex_near, FALSE			;假設附近沒有六角住
	xor eax, eax				;將eax設為零，用來儲存tag

	;檢查上面是否有六角柱
	sub esi, 34
	sub _coord.Y, 1
	js skip1
	cmp word ptr [esi], 16
	jne skip1
	mov hex_near, TRUE			;代表有，自己可以移除
	or eax, 1					;在該位置標記
skip1:
	shl eax, 1
	add esi, 34
	add _coord.Y, 1

	;檢查下面是否有六角柱
	add esi, 34
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge skip2
	cmp word ptr [esi], 16
	jne skip2
	mov hex_near, TRUE			;代表有，自己可以移除
	or eax, 1					;在該位置標記
skip2:
	shl eax, 1
	sub esi, 34
	sub _coord.Y, 1

	;檢查左邊是否有六角柱
	sub esi, 2
	sub _coord.X, 1
	js skip3
	cmp word ptr [esi], 16
	jne skip3
	mov hex_near, TRUE		;代表有，自己可以移除
	or eax, 1				;在該位置標記
skip3:
	shl eax, 1
	add esi, 2
	add _coord.X, 1

	;檢查右邊是否有六角柱
	add esi, 2
	add _coord.X, 1
	cmp _coord.X, 17
	jge skip4
	cmp word ptr [esi], 16
	jne skip4
	mov hex_near, TRUE		;代表有，自己可以移除
	or eax, 1				;在該位置標記
skip4:
	sub esi, 2
	sub _coord.X, 1
	mov tag, al

	mov al, hex_near
	test al, al
	jz end_process		;檢查該六角住的四周是否有六角住
	mov al, tag
	mov hexagon_near_tag, al
	mov eax, _coord
	mov active_hexagon, eax
	mov is_removing_hexagon, TRUE	;呼叫另一個執行緒移除六角柱

end_process:
	ret
CheckHexagonNear ENDP

SoftRemoveHexagon PROC
	LOCAL _coord:COORD
	;tag的表示法   0, 0, 0, 0, 上, 下, 左, 右
	mov eax, active_hexagon
	mov _coord, eax

	movzx eax,  _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx,  _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax			;esi指向該位置

	mov al, hexagon_near_tag

	push eax
	mov ecx, 300			;延遲3秒
L1:
	mov al, is_des
	test al, al
	jnz end_proc
	push ecx
	invoke Sleep, 10	;執行續休眠十秒
	pop ecx
	loop L1
	pop eax

	;移除右邊的六角柱
	test al, 1				;檢查該bit是否為1
	jz skip1
	add _coord.X, 1
	add esi, 2
	push eax
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;該點設為空地
	pop eax
	sub _coord.X, 1
	sub esi, 2
skip1:
	shr al, 1

	;移除左邊的六角柱
	test al, 1				;檢查該bit是否為1
	jz skip2
	sub _coord.X, 1
	sub esi, 2
	push eax
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;該點設為空地
	pop eax
	add _coord.X, 1
	add esi, 2
skip2:
	shr al, 1

	;移除下面的六角柱
	test al, 1				;檢查該bit是否為1
	jz skip3
	add _coord.Y, 1
	add esi, 34
	push eax
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;該點設為空地
	pop eax
	sub _coord.Y, 1
	sub esi, 34
skip3:
	shr al, 1

	;移除上面的六角柱
	test al, 1			;檢查該bit是否為1
	jz skip4
	sub _coord.Y, 1
	sub esi, 34
	push eax
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;該點設為空地
	pop eax
	add _coord.Y, 1
	add esi, 34
skip4:
	shr al, 1

	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;該原本六角柱的點設為空地

end_proc:
	mov hexagon_near_tag, 0
	mov is_removing_hexagon, FALSE
	ret
SoftRemoveHexagon ENDP

ChangeBombStatus PROC, _coord:COORD, _dir:DIRECTION
	LOCAL result:DWORD
	
	invoke BombFind, _coord	;查看該炸彈是否再啟動清單內
	mov result, eax

	cmp _dir, DIR_LEFT		;炸彈往左移
	je left
	cmp _dir, DIR_RIGHT		;炸彈往右移
	je right
	cmp _dir, DIR_UP		;炸彈往上移
	je up_method
	cmp _dir, DIR_DOWN		;炸彈往下移
	je down_method

left:
	sub _coord.X, 1
	mov eax, result		
	cmp eax, -1			;是否在內
	je add_bomb
	invoke ModifyBomb, eax, _coord	;改變炸彈位址
	jmp end_proc
add_bomb:
	invoke AddBomb, _coord		;把該炸彈添加到啟動清單內
	jmp end_proc
right:
	add _coord.X, 1
	mov eax, result		;是否在內
	cmp eax, -1
	je add_bomb2
	invoke ModifyBomb, eax, _coord	;改變炸彈位址
	jmp end_proc
add_bomb2:
	invoke AddBomb, _coord		;把該炸彈添加到啟動清單內
	jmp end_proc
up_method:
	sub _coord.Y, 1
	mov eax, result		;是否在內
	cmp eax, -1
	je add_bomb3
	invoke ModifyBomb, eax, _coord	;改變炸彈位址
	jmp end_proc
add_bomb3:
	invoke AddBomb, _coord		;把該炸彈添加到啟動清單內
	jmp end_proc
down_method:
	add _coord.Y, 1
mov eax, result		;是否在內
	cmp eax, -1
	je add_bomb4
	invoke ModifyBomb, eax, _coord	;改變炸彈位址
	jmp end_proc
add_bomb4:
	invoke AddBomb, _coord		;把該炸彈添加到啟動清單內
	jmp end_proc

end_proc:
skip:
	ret
ChangeBombStatus ENDP

ModifyBomb PROC, _loc:DWORD, _coord:COORD
	push esi		;將這些暫存器放入堆疊
	push eax

	invoke EnterCriticalSection, ADDR cs_bomb		;進入cs_bomb關鍵區域

	mov esi, _loc
	mov eax, _coord
	mov (BOMB_STATUS PTR [(OFFSET active_bomb_location)+esi*(TYPE active_bomb_location)])._pos, eax			;更新該陣列區塊的炸彈位址

	invoke LeaveCriticalSection, ADDR cs_bomb		;離開cs_bomb關鍵區域

	pop eax
	pop esi		;取出這些暫存器值
	ret
ModifyBomb ENDP

AddBomb PROC, _coord:COORD
	push esi
	push eax
	
	invoke EnterCriticalSection, ADDR cs_bomb		;進入cs_bomb關鍵區域

	mov eax, active_bomb_count
	lea eax, [eax*(TYPE active_bomb_location)]
	mov esi, OFFSET active_bomb_location
	add esi, eax
	mov eax, _coord
	mov (BOMB_STATUS PTR [esi])._pos, eax
	mov eax, curTime
	add eax, 8000
	mov (BOMB_STATUS PTR [esi])._time, eax		;指向active_bomb_location尾端
	add active_bomb_count, 1
	invoke SafePrintObject, PRINT_ACTIVE_COUNT, 0, main_char_location	;把啟動炸彈數目印在主控台上

	invoke LeaveCriticalSection, ADDR cs_bomb		;離開cs_bomb關鍵區域

	pop eax
	pop esi
	ret
AddBomb ENDP

BombFind PROC, _coord:COORD
	push esi
	push ecx
	push edx			;將暫存器放入堆疊

	invoke EnterCriticalSection, ADDR cs_bomb		;進入cs_bomb關鍵區域
	
	mov eax, -1
	mov esi, OFFSET active_bomb_location
	mov ecx, active_bomb_count						;把ecx設為啟動炸彈數目
	test ecx, ecx
	jz end_proc
L1:	
	inc eax
	mov edx, (BOMB_STATUS PTR [esi])._pos
	cmp edx, _coord									;座標相等時表示有找到
	je found
	add esi, TYPE BOMB_STATUS
	loop L1
	mov eax, -1						;該炸彈不在清單內
	jmp end_proc

found:
end_proc:
	push eax
	invoke LeaveCriticalSection, ADDR cs_bomb		;離開cs_bomb關鍵區域
	pop eax

	pop edx
	pop ecx
	pop esi			;從堆疊取出暫存器
	ret
BombFind ENDP

SetPiranhaOpen PROC, _coord:COORD
	push eax

	mov al, is_hidden
	test al, al
	jnz end_process

	movzx eax, _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax		;將esi指向該位置

	;檢查上面是否有十人花
	sub esi, 34
	sub _coord.Y, 1
	js skip1				;檢查有沒有越界
	cmp word ptr [esi], 9	;是否為小時人花
	jne skip1
	invoke change_open, _coord
skip1:
	add esi, 34
	add _coord.Y, 1			;回歸原點

	;檢查下面是否有十人花
	add esi, 34
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge skip2				;有沒有越界
	cmp word ptr [esi], 9	;是否為小時人花
	jne skip2
	invoke change_open, _coord
skip2:
	sub esi, 34
	sub _coord.Y, 1			;回歸原點

	;檢查左邊是否有十人花
	sub esi, 2
	sub _coord.X, 1
	js skip3				;有沒有越界
	cmp word ptr [esi], 9	;是否為小時人花
	jne skip3
	invoke change_open, _coord
skip3:
	add esi, 2
	add _coord.X, 1			;回歸原點

	;檢查右邊是否有十人花
	add esi, 2
	add _coord.X, 1
	cmp _coord.X, 17
	jge skip4				;有沒有越界
	cmp word ptr [esi], 9	;是否為小時人花
	jne skip4
	invoke change_open, _coord
skip4:
	sub esi, 2
	sub _coord.X, 1			;回歸原點
	jmp end_process

end_process:
	pop eax
	ret
SetPiranhaOpen ENDP

NearIsApple PROC, _coord:COORD
	;左邊有蘋果
	sub _coord.X, 1
	cmp _coord.X, 0
	jl next1
	sub esi, 2
	cmp word ptr [esi], 6		;看看左邊有沒有蘋果，如果沒有繼續下一個步驟
	jne skip
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將該點設為空地
	add esi, 2
	add _coord.X, 1
	mov word ptr [esi], 11
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將時人花設定成剛吃下蘋果的狀態，並加入檢查時人花狀態清單
	invoke AddCheckPiranhaStatus, _coord			;加入檢查時人花陣列
	jmp end_proc
skip:
	add esi, 2
next1:
	add _coord.X, 1		;回歸原點
right:
	;右邊有蘋果
	add _coord.X, 1
	cmp _coord.X, 17
	jge next2
	add esi, 2
	cmp word ptr [esi], 6		;看看右邊有沒有蘋果，如果沒有繼續下一個步驟
	jne skip2
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將該點設為空地
	sub esi, 2
	sub _coord.X, 1
	mov word ptr [esi], 11
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將時人花設定成剛吃下蘋果的狀態，並加入檢查時人花狀態清單
	invoke AddCheckPiranhaStatus, _coord		;加入檢查時人花陣列
	jmp end_proc
skip2:
	sub esi, 2
next2:
	sub _coord.X, 1		;回歸原點
up:
	;上面有蘋果
	sub _coord.Y, 1
	cmp _coord.Y, 0
	jl next3
	sub esi, 34
	cmp word ptr [esi], 6			;看看上邊有沒有蘋果，如果沒有繼續下一個步驟
	jne skip3
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將該點設為空地
	add esi, 34
	add _coord.Y, 1
	mov word ptr [esi], 11
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將時人花設定成剛吃下蘋果的狀態，並加入檢查時人花狀態清單
	invoke AddCheckPiranhaStatus, _coord		;加入檢查時人花陣列
	jmp end_proc
skip3:
	add esi, 34
next3:
	add _coord.Y, 1		;回歸原點
down:
	;下面有蘋果
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge next4
	add esi, 34
	cmp word ptr [esi], 6			;看看下邊有沒有蘋果，如果沒有繼續下一個步驟
	jne skip4
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將該點設為空地
	sub esi, 34
	sub _coord.Y, 1
	mov word ptr [esi], 11
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;將時人花設定成剛吃下蘋果的狀態，並加入檢查時人花狀態清單
	invoke AddCheckPiranhaStatus, _coord		;加入檢查時人花陣列
	jmp end_proc
skip4:
	sub esi, 34
next4:
	sub _coord.Y, 1		;回歸原點

end_proc:
	ret
NearIsApple ENDP

change_open PROC, _coord:COORD
    mov word ptr [esi], 8
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;把該點設為時人花開狀態並印出來
	invoke NearIsApple, _coord
	ret 
change_open ENDP

EatApple PROC, _coord:COORD
	push esi
	
	invoke IsPiranhaNear, _coord	
	test eax, eax
	jz end_proc					;先確保蘋果附近有沒有時人花
	mov word ptr [esi], 11		;將該時人花設為吃下去的狀態
	cmp eax, DIR_LEFT			;時人花在左邊
	je at_left
	cmp eax, DIR_RIGHT			;時人花在右邊
	je at_right
	cmp eax, DIR_UP				;時人花在上面
	je on_top
	cmp eax, DIR_DOWN			;時人花在下面
	je on_botton

at_left:
	sub _coord.X, 1
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出該時人花狀態
	invoke AddCheckPiranhaStatus, _coord						;加入檢查時人花之陣列
	add esi, 2
	add _coord.X, 1		;回歸原點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;將原點設為空地
	jmp end_proc
at_right:
	add _coord.X, 1
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出該時人花狀態
	invoke AddCheckPiranhaStatus, _coord						;加入檢查時人花之陣列
	sub esi, 2
	sub _coord.X, 1		;回歸原點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;將原點設為空地
	jmp end_proc
on_top:
	sub _coord.Y, 1
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出該時人花狀態
	invoke AddCheckPiranhaStatus, _coord						;加入檢查時人花之陣列
	add esi, 34
	add _coord.Y, 1		;回歸原點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;將原點設為空地
	jmp end_proc
on_botton:
	add _coord.Y, 1
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出該時人花狀態
	invoke AddCheckPiranhaStatus, _coord						;加入檢查時人花之陣列
	sub esi, 34
	sub _coord.Y, 1		;回歸原點
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;將原點設為空地

end_proc:
	pop esi
	ret
EatApple ENDP

YellowAndBlueExchange PROC
	LOCAL _coord:COORD

	push esi
	push eax

	mov esi, OFFSET map ;esi為地圖指標
	
	mov _coord.Y, 0
	jmp check_y_forloop1
y_forloop1:

	mov _coord.X, 0
	jmp check_x_forloop1
x_forloop1:
	cmp word ptr [esi], 4		;檢查是否黃花
	je change_blue				;改成蘭花
	cmp word ptr [esi], 20		;檢查是否藍花
	je change_yellow			;改成黃花
	jmp not_both

change_blue:
	mov word ptr [esi], 20	;改成藍花
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出藍花
	jmp end_change

change_yellow:
	mov word ptr [esi], 4	;改成黃花
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord	;印出黃花
	jmp end_change

not_both:
end_change:
	add esi, 2
	add _coord.X, 1
check_x_forloop1:
	mov ax, _coord.X
	cmp ax, map_size.X			;比較x是否大於map_size的X
	jl  x_forloop1

	add _coord.Y, 1
check_y_forloop1:
	mov ax, _coord.Y
	cmp ax, map_size.Y			;比較y是否大於map_size的Y
	jl y_forloop1

	pop eax
	pop esi
	ret
YellowAndBlueExchange ENDP

ItemChecker PROC
while1:
	mov al, is_des
	test al, al
	jnz end_proc
	call HexagonChecker
	call CheckBombStatus
	invoke Sleep, 10
	jmp while1
end_proc:
	xor eax, eax
	ret
ItemChecker ENDP

SendDeadMessage PROC
	LOCAL ir:INPUT_RECORD, dwtmp:DWORD
	mov ir.EventType, KEY_EVENT
	mov ir.Event.bKeyDown, TRUE
	mov ir.Event.dwControlKeyState, 0
	mov ir.Event.uChar.AsciiChar, 'l'
	mov ir.Event.wRepeatCount, 1
	mov ir.Event.wVirtualKeyCode, 'L'
	invoke MapVirtualKeyA, 'L', 0
	mov ir.Event.wVirtualScanCode, ax

	invoke WriteConsoleInputA, hin, ADDR ir, 1, ADDR dwtmp
	ret
SendDeadMessage ENDP

AddCheckPiranhaStatus PROC, _coord:COORD
	push esi
	push eax
	push edx		;將暫存器壓入堆疊

	invoke EnterCriticalSection, ADDR cs_piranha	;進入關鍵區域
	call RemovePiranhaStatus		;把以吃完蘋果的十人花移除

	mov esi, OFFSET piranha_sta
	movzx eax, piranha_in
	mov edx, eax
	shl edx, 2
	add eax, eax
	add edx, eax
	add esi, edx				;將時人花加入新的點
	mov ax, _coord.X
	mov (PIRANHA_STATUS PTR [esi])._local.X, ax
	mov ax, _coord.Y
	mov (PIRANHA_STATUS PTR [esi])._local.Y, ax
	mov (PIRANHA_STATUS PTR [esi])._times, 200		;設置時人花狀態
	add piranha_in, 1								;以添加

	invoke LeaveCriticalSection, ADDR cs_piranha	;離開cs_piranha關鍵區域

	pop edx
	pop eax
	pop esi			;取出暫存器值
	ret
AddCheckPiranhaStatus ENDP

CheckPiranhaStatus PROC
while1:
	mov al, is_des
	test al, al					;是否要結束該執行緒
	jnz end_proc
	invoke EnterCriticalSection, ADDR cs_piranha	;進入cs_piranha關鍵區域		
	movzx ecx, piranha_in
	mov esi, OFFSET piranha_sta
	test ecx, ecx				;時人花狀態陣列是否為空
	jz  skip_loop
L1:
	sub (PIRANHA_STATUS PTR [esi])._times, 1	;將該時人花減一
	jns skip_this								;有沒有小於零
	add (PIRANHA_STATUS PTR [esi])._times, 1	;將該時人花加一
skip_this:
	push ecx
	call ChangePiranhaStatus					;改變時人花狀態
	pop ecx
	add esi, TYPE PIRANHA_STATUS				;將esi指向下一個
	loop L1
skip_loop:
	invoke LeaveCriticalSection, ADDR cs_piranha	;離開cs_piranha關鍵區域
	invoke Sleep, 80							;執行緒休眠80毫秒
	jmp while1
end_proc:
	mov eax, 0
	ret
CheckPiranhaStatus ENDP

ChangePiranhaStatus PROC
	push esi

	cmp (PIRANHA_STATUS PTR [esi])._times, 100		;時間標記是否為100
	je change_to_middle
	cmp (PIRANHA_STATUS PTR [esi])._times, 1		;時間標記是否為1
	je change_to_small
	jmp end_proc
change_to_middle:
	invoke SafePrintObject, MAP_ELEMENT, 10, (PIRANHA_STATUS PTR [esi])._local	;改成中等狀態的十人花

	movzx eax, (PIRANHA_STATUS PTR [esi])._local.Y
	mov ebx, 34
	imul ebx
	movzx edx, (PIRANHA_STATUS PTR [esi])._local.X
	shl edx, 1
	add eax, edx
	mov esi, OFFSET map
	add esi, eax				;esi為該地圖的點
	mov word ptr [esi], 10		;將該點設為10
	jmp end_proc

change_to_small:
	invoke SafePrintObject, MAP_ELEMENT, 9, (PIRANHA_STATUS PTR [esi])._local	;改成小等狀態的十人花

	movzx eax, (PIRANHA_STATUS PTR [esi])._local.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, (PIRANHA_STATUS PTR [esi])._local.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax				;esi為該地圖的點
	mov word ptr [esi], 9		;將該點設為9
	jmp end_proc

end_proc:
	pop esi	
	ret
ChangePiranhaStatus ENDP

RemovePiranhaStatus PROC
	mov esi, OFFSET piranha_sta
	mov eax, 0
	jmp check_this_loop
this_loop:
	cmp (PIRANHA_STATUS PTR [esi])._times, 0		;檢查是否已結束
	jg end_this_loop

	add esi, TYPE PIRANHA_STATUS			;將ESI指向下一個
	add eax, 1								;eax加一
check_this_loop:
	cmp al, piranha_in
	jne this_loop							;是否把所有檢查完
end_this_loop:
	test eax, eax							;eax是否為零
	jz end_proc
	sub piranha_in, al						;將時人花改成有幾個要移除的
	movzx ecx, piranha_in					;將要移除的總數設定在ecx
	test ecx, ecx
	jz end_proc
	mov edi, OFFSET piranha_sta				;edi為時人花目標
loop2:
	mov eax, (PIRANHA_STATUS PTR [esi])._local
	mov (PIRANHA_STATUS PTR [edi])._local, eax
	mov ax, (PIRANHA_STATUS PTR [esi])._times
	mov (PIRANHA_STATUS PTR [edi])._times, ax
	add esi, TYPE PIRANHA_STATUS
	add edi, TYPE PIRANHA_STATUS			;改變陣列資料
	loop loop2
end_proc:
	ret
RemovePiranhaStatus ENDP

FindPiranhaStatus PROC, _coord:COORD
	push esi
	push ecx
	push ebx
	movzx ecx, piranha_in			;有多少在十人花內
	mov eax, -1
	test ecx, ecx
	jz end_proc
	mov esi, OFFSET piranha_sta		;將ESI設為時人花狀態的頭
L1:
	inc eax
	mov ebx, (PIRANHA_STATUS PTR [esi])._local
	cmp _coord, ebx
	je found					;有找到
	add esi, TYPE piranha_sta		;將esi指向下一個
	loop L1
	mov eax, -1				;沒有找到
	jmp end_proc

found:
end_proc:
	pop ebx
	pop ecx
	pop esi
	ret
FindPiranhaStatus ENDP

HexagonChecker PROC

	mov al, is_removing_hexagon
	test al, al
	jz skip
	call SoftRemoveHexagon
skip:

end_proc:
	ret
HexagonChecker ENDP

CheckBombStatus PROC

	invoke Sleep, 1	;執行緒休眠1毫秒
	mov ecx, active_bomb_count
	test ecx, ecx
	je end_proc
	mov esi, OFFSET active_bomb_location		;將esi指向啟動炸彈陣列的頭
L1:
	mov eax, curTime
	cmp (BOMB_STATUS PTR [esi])._time, eax
	jg skip			;如果現在時間戳記大於炸彈清單的時間戳記，爆炸
	push ecx
	push esi
	invoke Explosion, (BOMB_STATUS PTR [esi])._pos
	pop esi
	sub esi, TYPE BOMB_STATUS
	pop ecx
skip:
	add esi, TYPE BOMB_STATUS		;指向下一個
	loop L1


end_proc:
	ret
CheckBombStatus ENDP

Explosion PROC, _coorda:COORD
	LOCAL _coord:COORD

	mov eax, _coorda
	mov _coord, eax
	movzx eax, _coord.Y
	mov ebx, 17*(TYPE map)
	imul ebx
	movzx edx, _coord.X
	lea edx, [edx*(TYPE map)]
	add eax, edx
	mov esi, OFFSET map
	add esi, eax			;將esi設定為啟動該炸彈點

	;消除該位置的物品
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord

	;消除左邊的物品
	sub esi, 2
	sub _coord.X, 1
	js skip1
	invoke IsBlock, _coord, TRUE
	test eax, eax
	jnz skip1
	cmp word ptr [esi], 15		;是否為炸彈
	je add_bomb1
	cmp word ptr [esi], 25
	je add_bomb1
	cmp word ptr [esi], 10		;是否為中、大石人花
	jl skip_pi1
	cmp word ptr [esi], 11
	jg skip_pi1
	invoke FindPiranhaStatus, _coord		;檢查該時人花有沒有在十人花清單內
	push esi
	mov esi, OFFSET piranha_sta
	mov ebx, eax
	shl ebx, 2
	mov ecx, eax
	shl ecx, 1
	add ebx, ecx
	add esi, ebx
	mov (PIRANHA_STATUS PTR [esi])._times, 0		;將該時人花狀態設為零
	pop esi
skip_pi1:
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;消除該位置的物品
	mov eax, _coord
	cmp main_char_location, eax
	jne skip1
	call SendDeadMessage
	jmp skip1
add_bomb1:
	invoke BombFind, _coord		;該位置是否在啟動清單內
	cmp eax, -1
	jne skip1
	mov word ptr [esi], 25		;將該位置改成啟動狀態
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord
	invoke AddBomb, _coord		;添加該炸彈
skip1:
	add esi, 2
	add _coord.X, 1

	;消除右邊物品
	add esi, 2
	add _coord.X, 1
	cmp _coord.X, 17
	jge skip2
	invoke IsBlock, _coord, TRUE
	test eax, eax
	jnz skip2
	cmp word ptr [esi], 15		;是否為炸彈
	je add_bomb2
	cmp word ptr [esi], 25
	je add_bomb2
	cmp word ptr [esi], 10		;是否為中、大石人花
	jl skip_pi2
	cmp word ptr [esi], 11
	jg skip_pi2
	invoke FindPiranhaStatus, _coord		;檢查該時人花有沒有在十人花清單內
	push esi
	mov esi, OFFSET piranha_sta
	mov ebx, eax
	shl ebx, 2
	mov ecx, eax
	shl ecx, 1
	add ebx, ecx
	add esi, ebx
	mov (PIRANHA_STATUS PTR [esi])._times, 0		;將該時人花狀態設為零
	pop esi
skip_pi2:
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;消除該位置的物品
	mov eax, _coord
	cmp main_char_location, eax
	jne skip2
	call SendDeadMessage
	jmp skip2
add_bomb2:
	invoke BombFind, _coord		;該位置是否在啟動清單內
	cmp eax, -1
	jne skip2
	mov word ptr [esi], 25		;將該位置改成啟動狀態
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord
	invoke AddBomb, _coord		;添加該炸彈
skip2:
	sub esi, 2
	sub _coord.X, 1

	;消除上面物品
	sub esi, 34
	sub _coord.Y, 1
	js skip3
	invoke IsBlock, _coord, TRUE
	test eax, eax
	jnz skip3
	cmp word ptr [esi], 15		;是否為炸彈
	je add_bomb3
	cmp word ptr [esi], 25
	je add_bomb3
	cmp word ptr [esi], 10		;是否為中、大石人花
	jl skip_pi3
	cmp word ptr [esi], 11
	jg skip_pi3
	invoke FindPiranhaStatus, _coord		;檢查該時人花有沒有在十人花清單內
	push esi
	mov esi, OFFSET piranha_sta
	mov ebx, eax
	shl ebx, 2
	mov ecx, eax
	shl ecx, 1
	add ebx, ecx
	add esi, ebx
	mov (PIRANHA_STATUS PTR [esi])._times, 0		;將該時人花狀態設為零
	pop esi
skip_pi3:
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;消除該位置的物品
	mov eax, _coord
	cmp main_char_location, eax
	jne skip3
	call SendDeadMessage
	jmp skip3
add_bomb3:
	invoke BombFind, _coord		;該位置是否在啟動清單內
	cmp eax, -1
	jne skip3
	mov word ptr [esi], 25		;將該位置改成啟動狀態
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord
	invoke AddBomb, _coord		;添加該炸彈
skip3:
	add esi, 34
	add _coord.Y, 1

	;消除下面物品
	add esi, 34
	add _coord.Y, 1
	cmp _coord.Y, 12
	jge skip4
	invoke IsBlock, _coord, TRUE
	test eax, eax
	jnz skip4
	cmp word ptr [esi], 15		;是否為炸彈
	je add_bomb4
	cmp word ptr [esi], 25
	je add_bomb4
	cmp word ptr [esi], 10		;是否為中、大石人花
	jl skip_pi4
	cmp word ptr [esi], 11
	jg skip_pi4
	invoke FindPiranhaStatus, _coord		;檢查該時人花有沒有在十人花清單內
	push esi
	mov esi, OFFSET piranha_sta
	mov ebx, eax
	shl ebx, 2
	mov ecx, eax
	shl ecx, 1
	add ebx, ecx
	add esi, ebx
	mov (PIRANHA_STATUS PTR [esi])._times, 0		;將該時人花狀態設為零
	pop esi
skip_pi4:
	mov word ptr [esi], 5
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord		;消除該位置的物品
	mov eax, _coord
	cmp main_char_location, eax
	jne skip4
	call SendDeadMessage
	jmp skip4
add_bomb4:
	invoke BombFind, _coord		;該位置是否在啟動清單內
	cmp eax, -1
	jne skip4
	mov word ptr [esi], 25		;將該位置改成啟動狀態
	invoke SafePrintObject, MAP_ELEMENT, word ptr [esi], _coord
	invoke AddBomb, _coord		;添加該炸彈
skip4:
	call RemoveBomb		;移除啟動炸彈清單
	ret
Explosion ENDP

RemoveBomb PROC
	push esi
	push edi
	push ecx
	push eax

	invoke EnterCriticalSection, ADDR cs_bomb		;進入關鍵區域

	mov esi, (OFFSET active_bomb_location)+(TYPE BOMB_STATUS)	;將esi設為炸彈啟動清單的下一個
	mov edi, OFFSET active_bomb_location			;將EDI設為炸彈請動清單的頭
	mov ecx, active_bomb_count
L1:
	mov eax, (BOMB_STATUS PTR [esi])._pos
	mov (BOMB_STATUS PTR [edi])._pos, eax
	mov eax, (BOMB_STATUS PTR [esi])._time
	mov (BOMB_STATUS PTR [edi])._time, eax		;將ESI位址的資料搬到EDI位址
	add esi, TYPE BOMB_STATUS			;esi指向下一個
	add edi, TYPE BOMB_STATUS			;edi指向下一個
	loop L1

	sub active_bomb_count, 1
	invoke SafePrintObject, PRINT_ACTIVE_COUNT, 0, main_char_location		;印出啟動數目
	invoke LeaveCriticalSection, ADDR cs_bomb		;離開關鍵區域

	pop eax
	pop ecx
	pop edi
	pop esi
	ret
RemoveBomb ENDP

TimeCounter PROC
while1:
	invoke Sleep, 100			;執行緒休眠100毫秒
	mov al, is_des
	test al, al
	jnz end_proc				;是否要結束該執行緒
	invoke SafePrintObject, PRINT_TIME, 0, main_char_location		;印出時間
	jmp while1

end_proc:
	mov eax, 0
	ret
TimeCounter ENDP

SafePrintObject PROC, idType:DWORD, _data:WORD, _coord:COORD
	push esi
	push ebx

	invoke EnterCriticalSection, ADDR cs_print		;進入關鍵區域

	mov ebx, idType
	test ebx, ebx			;是否為元素
	jz print_map_element
	jmp other

print_map_element:
	invoke PrintMapElement, _data, _coord.X, _coord.Y		;印出地圖元素
	jmp end_switch

other:
	mov esi, OFFSET safe_print_method
	shl ebx, 2
	add esi, ebx
	call dword ptr [esi]

end_switch:
	invoke LeaveCriticalSection, ADDR cs_print		;離開關鍵區域

	pop ebx
	pop esi
	ret
SafePrintObject ENDP

PrintScore PROC
	mov dl, 69
	mov dh, 3
	call Gotoxy			;設定為印出分數座標
	mov eax, 7
	call SetTextColor	;設定印出顏色
	mov ecx, 6
L1:
	mov al, ' '
	call WriteChar		;清空螢幕緩衝
	loop L1
	mov dl, 69
	mov dh, 3
	call Gotoxy			;設定為印出分數座標
	push score
	push OFFSET print_int
	call printf			;印出分數
	add esp, 8
	ret
PrintScore ENDP

PrintLevel PROC
	mov dl, 69
	mov dh, 4
	call Gotoxy			;設定為印出階級座標
	mov eax, 7
	call SetTextColor	;設定印出顏色
	mov ecx, 3
L1:
	mov al, ' '
	call WriteChar		;清空螢幕資訊
	loop L1
	mov dl, 69
	mov dh, 4
	call Gotoxy			;設定為印出階級座標
	push level
	push OFFSET print_short
	call printf			;印出階級
	add esp, 6
	ret
PrintLevel ENDP

PrintKeys PROC
	mov dl, 69
	mov dh, 5
	call Gotoxy			;設定為印出鑰匙座標
	mov eax, 7
	call SetTextColor	;設定印出顏色
	mov ecx, 3
L1:
	mov al, ' '
	call WriteChar		;清空螢幕資訊
	loop L1
	mov dl, 69
	mov dh, 5
	call Gotoxy			;設定為印出鑰匙座標
	movzx edx, keys
	push edx
	push OFFSET print_int
	call printf			;印出鑰匙
	add esp, 8
	ret
PrintKeys ENDP

PrintActiveBombCount PROC
	mov dl, 73
	mov dh, 6
	call Gotoxy			;設定為印出爆炸時間座標
	mov eax, 7
	call SetTextColor	;設定印出顏色
	mov ecx, 3
L1:
	mov al, ' '
	call WriteChar		;清空螢幕資訊
	loop L1
	mov dl, 73
	mov dh, 6
	call Gotoxy			;設定為印出爆炸時間座標
	push active_bomb_count
	push OFFSET print_int
	call printf			;印出爆炸時間
	add esp, 8
	ret
PrintActiveBombCount ENDP

PrintTime PROC
	mov dl, 65
	mov dh, 1
	call Gotoxy		;設置顯示時鐘位置
	
	mov eax, 7
	call SetTextColor	;設置顯示時鐘顏色

	call clock
	mov curTime, eax
	sub eax, startTime	;與起始時間點相減

	mov edx, 0
	mov ebx, 1000		;除以CLOCK_PER_SEC
	div ebx
	mov edx, 0
	mov ebx, 60			;除以六十，秒為edx，分為eax
	div ebx
	push edx
	push eax
	push OFFSET time_format		;印出時間
	call printf
	add esp, 12
	
	ret
PrintTime ENDP

WinGame PROC
	call Clrscr				;清空螢幕

	mov dl, 36
	mov dh, 9
	call Gotoxy				;移到該位置
	mov eax, 7
	call SetTextColor		;設定顏色
	mov edx, OFFSET win_message
	call WriteString		;寫下訊息
	call ReadChar			;等待使用者按下任意見
	ret
WinGame ENDP

LoseGame PROC
	call Clrscr				;清空螢幕

	mov dl, 36
	mov dh, 9
	call Gotoxy
	mov eax, 7
	call SetTextColor		;設定顏色
	mov edx, OFFSET lose_message
	call WriteString		;寫下訊息
	call ReadChar			;等待使用者按下任意見
	ret
LoseGame ENDP

ExitZeekProcess PROC
    call cleanMap
	mov level, 0
	mov main_char_location.X, 0
	mov main_char_location.Y, 0
	mov piranha_in, 0
	mov score, 0
	mov is_eat, FALSE
	mov is_des, FALSE
	mov is_exit_key, FALSE
	mov is_function_key, FALSE
	mov num_of_thread, 0	;把所有的資料清空
	ret
ExitZeekProcess ENDP

SetHidden PROC
	LOCAL pid:DWORD

	mov is_hidden, TRUE
	invoke SafePrintObject, PRINT_MAIN_CHAR, 0, main_char_location
	call clock
	add eax, 8000
	mov hidden_end, eax

	lea esi, pid
	push esi
	push 0
	push 0
	push CheckHidden
	push 0
	push 0
	call CreateThread@24	;啟動檢查隱形狀態執行續

	mov ebx, num_of_thread
	mov HANDLE ptr [(OFFSET threads)+ebx*(TYPE HANDLE)], eax
	add num_of_thread, 1

	ret
SetHidden ENDP

CheckHidden PROC
start:
	mov al, is_des
	test al, al
	jnz end_proc
	invoke Sleep, 1
	call clock
	cmp eax, hidden_end		;檢查現在時間標記是否比隱藏結束時間標記大
	jl start
	mov is_hidden, FALSE		;將角色設定為非隱形狀態
	invoke SafePrintObject, PRINT_MAIN_CHAR, 0, main_char_location
	invoke IsPiranhaNear, main_char_location
	test eax, eax
	jz end_proc
	call SendDeadMessage
end_proc:
	sub num_of_thread, 1
	ret
CheckHidden ENDP

print_wall PROC		;印出牆
	mov eax, map_main_color
	call SetTextColor
	invoke WriteWideString, hout, OFFSET square
	ret
print_wall ENDP

print_ice_dirt_wall PROC		;印出泥土與冰牆
	mov eax, 0B4h
	call SetTextColor
	invoke WriteWideString, hout, OFFSET medium_shade
	ret
print_ice_dirt_wall ENDP

print_dirt_wall PROC		;印出泥土牆
	mov eax, 4
	call SetTextColor
	invoke WriteWideString, hout, OFFSET square
	ret
print_dirt_wall ENDP

print_flower PROC			;印出花
	mov eax, 14
	call SetTextColor
	invoke WriteWideString, hout, OFFSET flower
	ret
print_flower ENDP

print_floor PROC			;印出空地
	mov eax, 7h
	call SetTextColor
	invoke WriteWideString, hout, OFFSET space
	ret
print_floor ENDP

print_apple PROC			;印出蘋果
	mov eax, 0Ch
	call SetTextColor
	invoke WriteWideString, hout, OFFSET apple
	ret
print_apple ENDP

print_mushroom PROC			;印出蘑菇
	mov eax, 12
	call SetTextColor
	invoke WriteWideString, hout, OFFSET mushroom
	ret
print_mushroom ENDP

print_piranha_open PROC		;印出時人花開的狀態
	mov eax, 13
	call SetTextColor
	invoke WriteWideString, hout, OFFSET piranha_open
	ret
print_piranha_open ENDP

print_piranha_small PROC	;印出時人花小的狀態
	mov eax, 13
	call SetTextColor
	invoke WriteWideString, hout, OFFSET piranha_small
	ret
print_piranha_small ENDP

print_piranha_medium PROC	;印出時人花中的狀態
	mov eax, 13
	call SetTextColor
	invoke WriteWideString, hout, OFFSET piranha_medium
	ret
print_piranha_medium ENDP

print_piranha_big PROC		;印出時人花大的狀態
	mov eax, 13
	call SetTextColor
	invoke WriteWideString, hout, OFFSET piranha_big
	ret
print_piranha_big ENDP

print_key PROC				;印出鑰匙
	mov eax, 14
	call SetTextColor
	invoke WriteWideString, hout, OFFSET key
	ret
print_key ENDP

print_door PROC				;印出門
	mov eax, 6
	call SetTextColor
	invoke WriteWideString, hout, OFFSET door
	ret
print_door ENDP

print_bomb PROC				;印出炸彈
	mov eax, 2
	call SetTextColor
	invoke WriteWideString, hout, OFFSET bomb
	ret
print_bomb ENDP

print_nuclear PROC			;印出核廢
	mov eax, 14
	call SetTextColor
	invoke WriteWideString, hout, OFFSET nuclear
	ret
print_nuclear ENDP

print_hexagon PROC			;印出六角住
	mov eax, 11
	call SetTextColor
	invoke WriteWideString, hout, OFFSET hexagon
	ret
print_hexagon ENDP

print_box PROC				;印出箱子
	mov eax, 6
	call SetTextColor
	invoke WriteWideString, hout, OFFSET box
	ret
print_box ENDP

print_ball PROC				;印出球
	mov eax, 14
	call SetTextColor
	invoke WriteWideString, hout, OFFSET ball
	ret
print_ball ENDP

print_toxic_mushroom PROC	;印出毒菇
	mov eax, 10
	call SetTextColor
	invoke WriteWideString, hout, OFFSET mushroom
	ret
print_toxic_mushroom ENDP

print_blue_flower PROC		;印出藍花
	mov eax, 9
	call SetTextColor
	invoke WriteWideString, hout, OFFSET flower
	ret
print_blue_flower ENDP

print_cross_pad PROC		;印出藍黃交替店
	mov eax, 9eh
	call SetTextColor
	invoke WriteWideString, hout, OFFSET ball
	ret
print_cross_pad ENDP

print_hidden_pill PROC		;印出隱形丸
	mov eax, 13
	call SetTextColor
	invoke WriteWideString, hout, OFFSET hidden_pill
	ret
print_hidden_pill ENDP

print_laser_eye PROC		;印出雷射眼
	mov eax, 0ach
	call SetTextColor
	invoke WriteWideString, hout, OFFSET laser_eye
	ret
print_laser_eye ENDP

print_dinosaur PROC			;印出恐龍
	mov eax, 10
	call SetTextColor
	invoke WriteWideString, hout, OFFSET dinosaur
	ret
print_dinosaur ENDP

print_active_bomb PROC		;印出啟動中的炸彈
	mov eax, 12
	call SetTextColor
	invoke WriteWideString, hout, OFFSET bomb
	ret
print_active_bomb ENDP
END