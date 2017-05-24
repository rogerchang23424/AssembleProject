INCLUDE group_14_SmallWinEx.inc
INCLUDE Bool.inc

;clock初始化
clock PROTO C

DIRECTION TEXTEQU <DWORD>

;幫direction做enum
DIR_LEFT = 1
DIR_RIGHT = 2
DIR_UP = 3
DIR_DOWN = 4

MAP_ELEMENT = 0
PRINT_MAIN_CHAR = 1
PRINT_SCORE = 2
PRINT_LEVEL = 3
PRINT_KEYS = 4
PRINT_ACTIVE_COUNT = 5
PRINT_TIME = 6


;定義食人花狀態架構
PIRANHA_STATUS STRUCT
	_local  COORD <>
	_times  WORD ?
PIRANHA_STATUS ENDS

BOMB_STATUS STRUCT
	_pos COORD <>
	_time DWORD ?
BOMB_STATUS ENDS

;Set total level
TOTAL_LEVEL = 25

;主控台的輸出相容性
ConsoleCompatibility PROTO
;初始化遊戲介面
InitGameScene PROTO
;讀取地圖
LoadMap PROTO
;初始化狀態類
InitiateStatusBar PROTO
;把地圖印在主控台上
PrintMap PROTO
;清除讀入的地圖
cleanMap PROTO
;將部分元素印在主控台上
PrintMapElement PROTO,
	_data:WORD, x_coord:WORD, y_coord:WORD
;此為將unicode字元在console上顯示的方法，不需要將主控台的cp值轉換，定義在fd.dll裡面
WriteWideString PROTO, _hout:HANDLE, msg:PTR WORD
myprint PROTO, _hout:HANDLE, msg:PTR BYTE
;將主角的位置顯示出來
PrintMainChar PROTO
;開始時人花執行緒
StartPiranhaThread PROTO
;開始六角柱執行緒
StartHexagonListenerThread PROTO
;開始炸彈執行緒
StartBombThread PROTO
;開始時間執行緒
StartTimeThread PROTO
;開始恐龍執行緒
StartDinosaurProcessThread PROTO
;控制鍵
MoveCharactor PROTO
;判斷是否為終點, Return register:eax
IsDestination PROTO
;判斷是否圍牆, Return register:eax
IsBlock PROTO, _coord:COORD, forcewall:BOOL
;判斷是否為花朵或寶相，如果是就吃掉它, Return register:eax
IsFlowerAndBoxEat PROTO
;判斷是否為要使
EatKeyAndOpenDoor PROTO, _coord:COORD
;是否吃到毒菇、藍花
EatFakeItem PROTO, _coord:COORD
;判斷上下左右是否有十人花，回傳eax:方向，esi該位置
IsPiranhaNear PROTO, _coord:COORD
;物件是否能移動
ItemCanMove PROTO, _coord:COORD, _dir:DIRECTION
;決定六角柱是否消除
CheckHexagonNear PROTO, _coord:COORD
;消除六角柱
SoftRemoveHexagon PROTO
;添加炸彈狀態
ChangeBombStatus PROTO, _coord:COORD, _dir:DIRECTION
;加入陣列
AddBomb PROTO, _coord:COORD
;修改炸彈
ModifyBomb PROTO, _loc:DWORD, _coord:COORD
;啟動炸彈是否在陣列中
BombFind PROTO, _coord:COORD
;決定時人花是否要開
SetPiranhaOpen PROTO, _coord:COORD
;打開花
change_open PROTO, _coord:COORD
;吃掉蘋果
EatApple PROTO, _coord:COORD
;黃藍花交替
YellowAndBlueExchange PROTO
;添加檢查食人花狀態
AddCheckPiranhaStatus PROTO, _coord:COORD
;檢查時人花狀態
CheckPiranhaStatus PROTO
;改變時人花狀態
ChangePiranhaStatus PROTO
;移除時人花狀態
RemovePiranhaStatus PROTO
;找到時人花狀態
FindPiranhaStatus PROTO, _coord:COORD
;六角柱傾聽者
HexagonListener PROTO
;檢查炸彈狀態
CheckBombStatus PROTO
;炸彈爆炸
Explosion PROTO, _coorda:COORD
;移除炸彈
RemoveBomb PROTO
;計時器
TimeCounter PROTO
;顯示分數
PrintScore PROTO
;顯示階級
PrintLevel PROTO
;顯示鑰匙個數
PrintKeys PROTO
;顯示爆炸時間
PrintActiveBombCount PROTO
;顯示計時結果
PrintTime PROTO
;離開遊戲程序
ExitZeekProcess PROTO
;贏遊戲的畫面
WinGame PROTO
;輸遊戲的畫面
LoseGame PROTO
;安全輸出
SafePrintObject PROTO, idType:DWORD, _data:WORD, _coord:COORD
;恐龍行程
DinosaurProc PROTO

;以下為印出元素的方法
print_wall PROTO
print_ice_dirt_wall PROTO
print_dirt_wall PROTO
print_flower PROTO
print_floor PROTO
print_apple PROTO
print_mushroom PROTO
print_piranha_open PROTO
print_piranha_small PROTO
print_piranha_medium PROTO
print_piranha_big PROTO
print_key PROTO
print_door PROTO
print_bomb PROTO
print_nuclear PROTO
print_hexagon PROTO
print_box PROTO
print_ball PROTO
print_toxic_mushroom PROTO
print_blue_flower PROTO
print_cross_pad PROTO
print_hidden_pill PROTO
print_laser_eye PROTO
print_dinosaur PROTO
print_active_bomb PROTO
;結束印出的方法

DinosaurMove PROTO