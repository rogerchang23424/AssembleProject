INCLUDE Irvine32.inc
INCLUDE Bool.inc
INCLUDE group_14_SmallWinEx.inc

MAJOR_VERSION = 0
MINOR_VERSION = 6
THIRD_VERSION = 0

PUBLIC hout
PUBLIC hin

zeek_pane PROTO
about_proc PROTO
help_proc PROTO
myprint PROTO, hout:HANDLE, ddd:PTR BYTE
Select_Method PROTO
WriteWideString PROTO, hout:HANDLE, _ddd:PTR WORD
ConsoleCompatibility PROTO

EXTERN act:WORD
EXTERN print_method:DWORD
EXTERN map_main_color:DWORD

main EQU start@0

.data
square BYTE "■", 0
hout DWORD ?
hin DWORD ?
draw BYTE "Draw      ", 0
jeek BYTE "Start     ", 0
help BYTE "Help      ", 0
about BYTE "About     ", 0
exit_name BYTE "Exit      ", 0
menuitem DWORD OFFSET jeek, OFFSET help, OFFSET about, OFFSET exit_name
title_name BYTE "Jeek 1", 0
select DWORD 1
message1 BYTE "Group 14 Final Project", 0ah, 0
message2 BYTE "Version: %d.%d.%d", 0ah, 0
message3 BYTE "組員：張聿程、郭竣喨", 0ah, 0
message4 BYTE "Operating System Version: %d.%d.%d", 0ah, 0
message5 BYTE "OS:%s %s", 0ah, 0

help_main_charactor BYTE "遊戲主角", 0
help_colon BYTE ':'
help_control_title BYTE "操作物件說明", 0
help_control_allow BYTE "鍵盤上、下、左、右:控制角色", 0
help_f1 BYTE "F1:重新開始", 0
help_f2 BYTE "F2:跳關", 0
help_esc BYTE "Esc:離開", 0
help_item_title BYTE "遊戲物件說明", 0
help_item_1 BYTE "表示圍牆", 0
help_item_2 BYTE "表示冰與泥土圍牆", 0
help_item_3 BYTE "表示泥土牆", 0
help_item_4 BYTE "表示黃花，50分", 0
help_item_5 BYTE "表示空地", 0
help_item_6 BYTE "表示蘋果", 0
help_item_7 BYTE "表示紅菇(代表終點)", 0
help_item_8 BYTE "表示食人花(花朵打開的樣子)，靠近會死亡", 0
help_item_9 BYTE "表示食人花(花朵縮小的樣子)", 0
help_item_10 BYTE "表示食人花(花朵中的樣子)", 0
help_item_11 BYTE "表示食人花(花朵膨脹的樣子)", 0
help_item_12 BYTE "表示核廢料", 0
help_item_13 BYTE "表示門，需要鑰匙打開", 0
help_item_14 BYTE "表示鑰匙、最多只能攜帶一把", 0
help_item_15 BYTE "表示炸彈，啟動後會炸掉上、下、左、右", 0
help_item_16 BYTE "表示六角柱，上下左右有時會聯合消除", 0
help_item_17 BYTE "表示裡面有錢的寶箱，1000分", 0
help_item_18 BYTE "表示黃色球體", 0
help_item_19 BYTE "表示綠色毒菇", 0
help_item_20 BYTE "表示藍花", 0
help_item_21 BYTE "表示一個踏墊，用來把藍花和黃花互換", 0
help_item_22 BYTE "表示隱形丸，可以隱身8秒", 0
help_item_23 BYTE "表示雷射眼", 0
help_item_24 BYTE "表示恐龍，遊戲一開始接先向右移動", 0
help_item_25 byte "表示啟動中的狀態", 0

win2000 BYTE "Windows 2000", 0
winxp BYTE "Windows XP", 0
win2003 BYTE "Windows Server 2003", 0
winvista BYTE "Windows Vista", 0
win7 BYTE "Windows 7", 0
win2008 BYTE "Windows Server 2008", 0
win2008r2 BYTE "Windows Server 2008 R2", 0
win8 BYTE "Windows 8", 0
win8p1 BYTE "Windows 8.1", 0
win2012 BYTE "Windows Server 2012", 0
win2012r2 BYTE "Windows Server 2012 R2", 0
win10 BYTE "Windows 10", 0
win2016 BYTE "Windows Server 2016", 0
other BYTE "Client", 0

osver OSVERSIONINFOEX <>

.code
main PROC
	LOCAL cci:CONSOLE_CURSOR_INFO, cor:COORD

	invoke GetStdHandle, STD_OUTPUT_HANDLE	   ;取得輸出HANDLE
	mov hout, eax

	invoke GetStdHandle, STD_INPUT_HANDLE		;取得輸入句炳
	mov hin, eax

	mov cci.dwSize, 1
	mov cci.bVisible, FALSE
	invoke SetConsoleCursorInfo, hout, ADDR cci		;隱藏游標
	invoke SetConsoleTitleA, OFFSET title_name		;設定主控台名稱

	call ConsoleCompatibility		;將字元改成舊版主控台可以顯示的字元，僅限cp950

			;以下為顯示主選單內容
while_loop1:
	mov ecx, LENGTHOF menuitem
L1:
	mov edx, ecx
	shl edx, 1
	add edx, 3
	mov cor.X, 33
	mov cor.Y, dx
	push ecx
	invoke SetConsoleCursorPosition, hout, cor	
	pop ecx
	cmp ecx, select
	je set_select
	mov eax, 7h
	call SetTextColor
	jmp endif1
set_select:
	mov eax, 70h
	call SetTextColor
endif1:
	mov esi, OFFSET menuitem
	mov edx, ecx
	shl edx, 2
	sub edx, 4
	add esi, edx
	mov edi, dword ptr [esi]
	mov edx, edi
	call WriteString
	loop L1
	;顯示主選單內容完

	call ReadChar	;讀取輸入
	cmp al, 0
	je extend_key	;是否為擴充建
	cmp al, 0dh
	je enter_key	;是否按下enter
	jmp end_switch

extend_key:
	cmp ah, 48h		;up_allow
	je up_allow_key
	cmp ah, 50h		;down_allow
	je down_allow_key
	jmp end_switch
up_allow_key:
	sub select, 1		
	add select, LENGTHOF menuitem	;往上選一個
	mov eax, select
	mov edx, 0
	mov ebx, LENGTHOF menuitem
	div ebx
	cmp edx, 0
	je change_to_zero
	mov select, edx
	jmp endif2

change_to_zero:
	mov select, LENGTHOF menuitem

endif2:
	jmp end_switch

down_allow_key:
	add select, 1
	add select, LENGTHOF menuitem	;往下選一個
	mov eax, select
	mov edx, 0
	mov ebx, LENGTHOF menuitem
	div ebx
	cmp edx, 0
	je change_to_zero2
	mov select, edx
	jmp endif3

change_to_zero2:
	mov select, LENGTHOF menuitem

endif3:
	jmp end_switch

enter_key:
	call Select_Method
	jmp end_switch

end_switch:
	jmp while_loop1
main ENDP

help_proc PROC
	invoke myprint, hout, OFFSET help_main_charactor
	mov al, help_colon
	call WriteChar
	call Crlf

	mov eax, 12
	call SetTextColor
	invoke WriteWideString, hout, OFFSET act
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_main_charactor
	call Crlf

	call Crlf
	invoke myprint, hout, OFFSET help_control_title
	mov al, help_colon
	call WriteChar
	call Crlf

	invoke myprint, hout, OFFSET help_control_allow
	call Crlf

	invoke myprint, hout, OFFSET help_f1
	call Crlf

	invoke myprint, hout, OFFSET help_f2
	call Crlf

	invoke myprint, hout, OFFSET help_esc
	call Crlf

	call Crlf
	invoke myprint, hout, OFFSET help_item_title
	mov al, help_colon
	call WriteChar
	call Crlf

	mov esi, OFFSET print_method
	add esi, 4
	mov map_main_color, 7
	call dword ptr [esi]
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_1
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_2
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_3
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_4
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_5
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_6
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_7
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_8
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_9
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_10
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_11
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_12
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_13
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_14
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_15
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_16
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_17
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_18
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_19
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_20
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_21
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_22
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_23
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_24
	call Crlf

	add esi, 4
	call dword ptr [esi]
	mov eax, 7
	call SetTextColor
	mov al, help_colon
	call WriteChar
	invoke myprint, hout, OFFSET help_item_25
	call Crlf

	call ReadChar
	call Clrscr
	ret
help_proc ENDP

GetOSName PROC, _osvi:PTR OSVERSIONINFOEX
	mov esi, _osvi
	cmp (OSVERSIONINFOEX PTR [esi]).dwMajorVersion, 10	;是否為WIN10
	je ver10
	cmp (OSVERSIONINFOEX PTR [esi]).dwMajorVersion, 6		;是否為WIN VISTA, WIN 7, WIN 8,WIN 8.1
	je ver6
	cmp (OSVERSIONINFOEX PTR [esi]).dwMajorVersion, 5		;是否為WIN 2000, WIN XP, WIN 2003
	je ver5
	jmp default
ver10:
	cmp (OSVERSIONINFOEX PTR [esi]).wProductType, VER_NT_WORKSTATION
	jne not_workstation

	mov eax, OFFSET win10
	jmp end_proc
not_workstation:
	mov eax, OFFSET win2016
	jmp end_proc

ver6:
	cmp (OSVERSIONINFOEX PTR [esi]).dwMinorVersion, 1		;是否為WIN 7
	je ver6_1
	cmp (OSVERSIONINFOEX PTR [esi]).dwMinorVersion, 3		;是否為WIN 8.1
	je ver6_3
	cmp (OSVERSIONINFOEX PTR [esi]).dwMinorVersion, 2		;是否為WIN 8
	je ver6_2
	cmp (OSVERSIONINFOEX PTR [esi]).dwMinorVersion, 0		;是否為WIN VISTA
	je ver6_0
	jmp default

ver6_0:
	cmp (OSVERSIONINFOEX PTR [esi]).wProductType, VER_NT_WORKSTATION
	jne not_workstation2

	mov eax, OFFSET winvista
	jmp end_proc
not_workstation2:
	mov eax, OFFSET win2008
	jmp end_proc

ver6_1:
	cmp (OSVERSIONINFOEX PTR [esi]).wProductType, VER_NT_WORKSTATION
	jne not_workstation3

	mov eax, OFFSET win7
	jmp end_proc
not_workstation3:
	mov eax, OFFSET win2008r2
	jmp end_proc

ver6_2:
	cmp (OSVERSIONINFOEX PTR [esi]).wProductType, VER_NT_WORKSTATION
	jne not_workstation4

	mov eax, OFFSET win8
	jmp end_proc
not_workstation4:
	mov eax, OFFSET win2012
	jmp end_proc

ver6_3:
	cmp (OSVERSIONINFOEX PTR [esi]).wProductType, VER_NT_WORKSTATION
	jne not_workstation5

	mov eax, OFFSET win8p1
	jmp end_proc
not_workstation5:
	mov eax, OFFSET win2012r2
	jmp end_proc

ver5:
	cmp (OSVERSIONINFOEX PTR [esi]).dwMinorVersion, 1		;是否為WIN XP
	je ver5_1
	cmp (OSVERSIONINFOEX PTR [esi]).dwMinorVersion, 2		;是否為WIN 2003
	je ver5_2
	cmp (OSVERSIONINFOEX PTR [esi]).dwMinorVersion, 0		;是否為WIN 2000
	je ver5_0
	jmp default

ver5_0:
	mov eax, OFFSET win2000
	jmp end_proc
ver5_1:
	mov eax, OFFSET winxp
	jmp end_proc
ver5_2:
	cmp (OSVERSIONINFOEX PTR [esi]).wProductType, VER_NT_WORKSTATION
	je is_workstation

	mov eax, OFFSET win2003
	jmp end_proc
is_workstation:
	mov eax, OFFSET winxp
	jmp end_proc

default:
	mov eax, OFFSET other
	jmp end_proc
end_proc:
	ret
GetOSName ENDP

about_proc PROC
	call Clrscr
	mov edx, OFFSET message1
	call WriteString			;顯示專案名稱
	push THIRD_VERSION
	push MINOR_VERSION
	push MAJOR_VERSION
	push OFFSET message2
	call printf					;顯示專案版本
	add esp, 16
	invoke myprint, hout, OFFSET message3	;顯示組員

	mov osver.dwOSVersionInfoSize, TYPE OSVERSIONINFOEX
	invoke GetVersionExA, ADDR osver		;取得作業系統訊息

	invoke GetOSName, ADDR osver			;取得作業系統名稱
	push OFFSET osver.szCSDVersion
	push eax
	push OFFSET message5
	call printf
	add esp, 12

	push osver.dwBuildNumber
	push osver.dwMinorVersion
	push osver.dwMajorVersion
	push OFFSET message4					;取得作業系統版本號
	call printf
	add esp, 16

	call ReadChar
	call Clrscr
	ret
about_proc ENDP

Select_Method PROC
    mov eax, 7
	call SetTextColor
	cmp select, 1
	je select_is_1		;選擇jeek
	cmp select, 2
	je select_is_2		;選擇about
	cmp select, 3
	je select_is_3		;選擇離開
	cmp select, 4
	je select_is_4
	jmp end_switch
select_is_1:
	call zeek_pane
	jmp end_switch		;進入jeek
select_is_2:
	call Clrscr
	call help_proc
	jmp end_switch
select_is_3:
	call about_proc
	jmp end_switch		;顯示相關信息
select_is_4:
	exit				;結束程式
end_switch:
	call Clrscr
	ret
Select_Method ENDP
END main