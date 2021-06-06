.386
.model	flat,stdcall
option	casemap:none

include   ./inc/windows.inc
includelib	windows.lib
include ./inc/user32.inc
includelib	user32.lib
include ./inc/kernel32.inc
includelib	kernel32.lib
include ./inc/gdi32.inc
includelib gdi32.lib

WinMain 		PROTO :DWORD,:DWORD,:DWORD,:DWORD
startGame	PROTO
changeSpeed1 PROTO :DWORD
changeSpeed2 PROTO :DWORD
moveSnake1 PROTO
moveSnake2 PROTO
SNAKE	struct
	
	posX	dw		?
	posY	dw		?
	next	BYTE	?
	axes	BYTE	?
	
SNAKE	ends

IDM_RES		equ	1000
sLen			equ	6
ID_TIMER1	equ	15
ID_TIMER2	equ	16
ID_TIMER3	equ	17
ID_TIMER4	equ	18

VK_A  equ  41H
VK_D  equ  44H
VK_S  equ  53H
VK_W  equ  57H
VK_G  equ  47H  ;蛇2的加速

.data
myClassName		db		"myWndClass",0
winCaption		db		"Speed Snake!",0
mButton			db		"BUTTON",0
goGame			db		"Continue Game!",0
fmts				db		"Score:%7d",0
fmtl				db		"Level:%7d",0


text				db		13 dup(?)
rand				dw		0
randX				dw		100
randY				dw		100
level				dw		1
score				dd		0
speed1				dw		300
speed2				dw		300
speedfood			dw      250
.data?
hInstance	dd		?
hMainWin		dd		?
dFood			SNAKE		<0,0,0,0>
sFood			SNAKE		100 dup(<0,0,0,0>)		;食物数组，axes为标志位，axes=0为空，可放入食物，axes=1为占用，需要拿走食物

axes1			BYTE 	4
sList1			SNAKE		100	dup(<100,100,0,0>)
sHead1			SNAKE		<>
sNum1			BYTE 	?
sAdd1			BYTE	?


axes2			BYTE 	4
sList2			SNAKE		100	dup(<100,100,0,0>)
sHead2			SNAKE		<>
sNum2			BYTE 	?
sAdd2			BYTE	?


.code

start:
	invoke	GetModuleHandle,NULL
	mov		hInstance,eax
	invoke	WinMain,hInstance,NULL,NULL,SW_SHOWDEFAULT
	invoke	ExitProcess,NULL
	

drawInfo proc 
	local	hdc:HDC
	
	invoke	GetDC,hMainWin
	mov		hdc,eax
	invoke	wsprintf,offset text,offset fmts,score
	invoke	TextOut,hdc,410,50,offset text,sizeof text
	
	invoke	wsprintf,offset text,offset fmtl,level
	invoke	TextOut,hdc,410,80,offset text,sizeof text
	invoke 	ReleaseDC,hMainWin,hdc
	ret
drawInfo endp

drawdFood proc
	local	x:DWORD
	local	y:DWORD
	local	_x:DWORD
	local	_y:DWORD
	local	hdc:HDC
	local	hPen:HPEN
	local	hBrush:HBRUSH
	local oldPen:HPEN
	local oldBrush:HBRUSH
	local	hScr:HBRUSH
	
	mov ax,dFood.posX
	mov x,eax
	add eax,10
	mov _x,eax
	mov ax,dFood.posY
	mov y,eax
	add eax,10
	mov _y,eax
	
	;获取窗口dc
	invoke	GetDC,hMainWin
	mov		hdc,eax
	
	;创建画笔
	invoke	CreatePen,PS_SOLID,1,0ff0000H
	mov		hPen,eax
	invoke	CreateSolidBrush,000ffffH
	mov		hBrush,eax
	invoke	SelectObject,hdc,hPen
	mov		oldPen,eax
	invoke	SelectObject,hdc,hBrush
	mov		oldBrush,eax
	
	invoke	Rectangle,hdc,x,y,_x,_y
	
	invoke	SelectObject,hdc,oldPen
	invoke	SelectObject,hdc,oldBrush
	invoke 	ReleaseDC,hMainWin,hdc
	invoke	DeleteObject,hPen
	invoke	DeleteObject,hBrush
	ret
drawdFood endp

drawFood proc uses eax esi
	local	count:DWORD
	local	x:DWORD
	local	y:DWORD
	local	_x:DWORD
	local	_y:DWORD
	local	hdc:HDC
	local	hPen:HPEN
	local	hBrush:HBRUSH
	local oldPen:HPEN
	local oldBrush:HBRUSH
	local	hScr:HBRUSH

	;获取窗口dc
	invoke	GetDC,hMainWin
	mov		hdc,eax
	
	;创建画笔
	invoke	CreatePen,PS_SOLID,1,0ff0000H
	mov		hPen,eax
	invoke	CreateSolidBrush,000ffffH
	mov		hBrush,eax
	invoke	SelectObject,hdc,hPen
	mov		oldPen,eax
	invoke	SelectObject,hdc,hBrush
	mov		oldBrush,eax

	mov esi,0				;遍历食物数组
	mov count,0
	.while TRUE
		.break .if count >=100
		.if sFood[esi].axes==1;有食物

		mov ax,sFood[esi].posX
		mov x,eax
		add eax,10
		mov _x,eax
		mov ax,sFood[esi].posY
		mov y,eax
		add eax,10
		mov _y,eax
	
		invoke	Rectangle,hdc,x,y,_x,_y
		.endif 
		add esi,sLen
		add count,1
	.endw
		invoke	SelectObject,hdc,oldPen
		invoke	SelectObject,hdc,oldBrush
		invoke 	ReleaseDC,hMainWin,hdc
		invoke	DeleteObject,hPen
		invoke	DeleteObject,hBrush

		invoke drawdFood ;画出那个动态的食物
		ret
drawFood endp  ;似乎没问题了


Dead_addFood proc uses esi eax ebx , pos_X:WORD, pos_Y:WORD
	local count:WORD
	mov count,0
	mov esi,0							;初始化
	.while TRUE							;遍历食物仓库，找到空处存入食物
		.break .if (count>=100||sFood[esi].axes==0)
		add esi,sLen
		add count,1
	.endw
	.if count<100
		mov ax,pos_X
		mov sFood[esi].posX,ax
		mov bx,pos_Y
		mov sFood[esi].posY,bx
		mov sFood[esi].axes,1	;占用食物
	.endif
	ret

Dead_addFood endp


random proc value:DWORD 
	;随机范围为0~value
	getR:
		invoke	GetTickCount
		xor	edx,edx
		mov	ecx,value
		div	ecx
		mov	eax,edx
	.if eax<1
		jmp getR
	.endif
	
	ret
random endp

changeRandom proc
	local ft:DWORD
	
	invoke random,10
	mov	ft,eax
	invoke random,38
	mov	bl,10
	mul	bl
	.if ft>5
		mov randX,ax
	.elseif ft<6
		mov randY,ax
	.endif
	
	ret
changeRandom endp

addDFood proc  ;这里处理动态的食物
	local next:BYTE
	mov next,1
r1:	
	mov next,1
	mov esi,0
	.while TRUE
		.break .if next==0
		mov ax,sList1[esi].posX
		mov bx,sList1[esi].posY
		.if randX==ax && randY==bx
			invoke changeRandom
			jmp r1
		.endif
		mov al,sList1[esi].next
		mov next,al
		add esi,sLen
	.endw
	
	;判断不与蛇二重叠
	mov next,1
	mov esi,0
	.while TRUE
		.break .if next==0
		mov ax,sList2[esi].posX
		mov bx,sList2[esi].posY
		.if randX==ax && randY==bx
			invoke changeRandom
			jmp r1
		.endif
		mov al,sList2[esi].next
		mov next,al
		add esi,sLen
	.endw

	mov ax,randX
	mov dFood.posX,ax
	mov bx,randY
	mov dFood.posY,ax
	
	ret
addDFood endp

InitFood proc
		local count:WORD
		mov esi,0
		mov count,0
		.while TRUE
			.break .if count>=100
		mov sFood[esi].axes,0
		add count,1
		add esi,sLen
		.endw
		ret
InitFood endp

InitSnake1 proc
	mov bx,80
	mov esi,0
	init1:	
		mov sList1[esi].posX,bx
		mov sList1[esi].posY,30
		mov sList1[esi].next,1
		mov sList1[esi].axes,4
		sub ebx,10
		add esi,sLen
	.if bx>30
		jmp init1
	.endif
	sub esi,sLen
	mov sList1[esi].next,0
	
	mov sNum1,5
	mov sAdd1,0
	mov speed1,300
	ret
InitSnake1 endp

InitSnake2 proc
	mov bx,200
	mov esi,0
	init2:	
		mov sList2[esi].posX,bx
		mov sList2[esi].posY,100
		mov sList2[esi].next,1
		mov sList2[esi].axes,4 ;原本是4
		sub ebx,10
		add esi,sLen
	.if bx>150
		jmp init2
	.endif
	sub esi,sLen
	mov sList2[esi].next,0
	
	mov sNum2,5
	mov sAdd2,0
	mov speed2,300
	ret
InitSnake2 endp

drawSnake	proc uses esi
	local next:BYTE
	local	x:DWORD
	local	y:DWORD
	local	_x:DWORD
	local	_y:DWORD
	local	hdc:HDC
	local	hPen:HPEN
	local	hBrush:HBRUSH
	local oldPen:HPEN
	local oldBrush:HBRUSH
	local	hScr:HBRUSH
	
	;获取窗口dc
	invoke	GetDC,hMainWin
	mov		hdc,eax
	;创建画笔
	invoke	CreatePen,PS_SOLID,1,0ff0000H ;这似乎是边框？
	mov		hPen,eax
	invoke	SelectObject,hdc,hPen
	mov		oldPen,eax
	;绘制背景框
	invoke	Rectangle,hdc,10,10,400,400
	;创建画刷
	invoke	CreateSolidBrush,00000ffH;这是像素
	mov		hBrush,eax
	invoke	SelectObject,hdc,hBrush
	mov		oldBrush,eax
	
	mov next,1
	mov esi,0
	mov eax,0
	
	;绘画蛇身
	.while TRUE
		.break .if	next==0
		mov		ax,sList1[esi].posX
		mov		x,eax
		add		ax,10
		mov		_x,eax
		mov		ax,sList1[esi].posY
		mov		y,eax
		add		ax,10
		mov		_y,eax
		mov		al,sList1[esi].next
		mov		next,al
		add		esi,sLen
		invoke	Rectangle,hdc,x,y,_x,_y
	.endw

	;创建画刷
	invoke	CreateSolidBrush,000ff00H;这是像素
	mov		hBrush,eax
	invoke	SelectObject,hdc,hBrush
	mov		oldBrush,eax

	mov next,1
	mov esi,0
	mov eax,0
	
	;绘画蛇身
	.while TRUE
		.break .if	next==0
		mov		ax,sList2[esi].posX
		mov		x,eax
		add		ax,10
		mov		_x,eax
		mov		ax,sList2[esi].posY
		mov		y,eax
		add		ax,10
		mov		_y,eax
		mov		al,sList2[esi].next
		mov		next,al
		add		esi,sLen
		invoke	Rectangle,hdc,x,y,_x,_y
	.endw

	;释放memory
	invoke	SelectObject,hdc,oldPen
	invoke	SelectObject,hdc,oldBrush
	invoke 	ReleaseDC,hMainWin,hdc
	invoke	DeleteObject,hPen
	invoke	DeleteObject,hBrush
	ret
drawSnake	endp



addSnake1 proc uses esi
	local x:WORD
	local y:WORD
	local axi:BYTE
	
	mov bl,sNum1
	sub bl,1
	mov al,sLen
	mul bl
	mov esi,eax
	;获取方向
	mov al,sList1[esi].axes
	mov axi,al
	;计算新添加节点的x,y
	mov ax,sList1[esi].posX
	.if	axi==3
		add ax,10
	.elseif axi==4
		sub ax,10
	.endif
	mov x,ax
	mov ax,sList1[esi].posY
	.if	axi==1
		add ax,10
	.elseif axi==2
		sub ax,10
	.endif
	mov y,ax
	
	mov sList1[esi].next,1
	add esi,sLen
	;添加新的节点
	mov ax,x
	mov sList1[esi].posX,ax
	mov ax,y
	mov sList1[esi].posY,ax
	mov al,axi
	mov sList1[esi].axes,al
	mov sList1[esi].next,0
	
	add sNum1,1
	;speed
	invoke changeSpeed1,1
	ret
addSnake1	endp

addSnake2 proc uses esi
	local x:WORD
	local y:WORD
	local axi:BYTE
	
	mov bl,sNum2
	sub bl,1
	mov al,sLen
	mul bl
	mov esi,eax
	;获取方向
	mov al,sList2[esi].axes
	mov axi,al
	;计算x,y
	mov ax,sList2[esi].posX
	.if	axi==3
		add ax,10
	.elseif axi==4
		sub ax,10
	.endif
	mov x,ax
	mov ax,sList2[esi].posY
	.if	axi==1
		add ax,10
	.elseif axi==2
		sub ax,10
	.endif
	mov y,ax
	
	mov sList2[esi].next,1
	add esi,sLen
	;添加新的节点
	mov ax,x
	mov sList2[esi].posX,ax
	mov ax,y
	mov sList2[esi].posY,ax
	mov al,axi
	mov sList2[esi].axes,al
	mov sList2[esi].next,0
	
	add sNum2,1
	;speed
	invoke changeSpeed2,1
	ret
addSnake2	endp


testCollide proc uses esi
	local sx:WORD
	local sy:WORD
	local next:BYTE
	local count:WORD

snake1judge:
	mov next,1
	mov esi,0
	
	mov ax,sList1[esi].posX
	mov sx,ax
	mov ax,sList1[esi].posY
	mov sy,ax
	add esi,sLen
	
	.if sx<10 || sx>390 || sy<10 || sy>390 
		jmp existP
	.endif

	mov ax,dFood.posX
	mov bx,dFood.posY
	.if sx==ax && sy==bx
		invoke addDFood
		add	score,10
		mov sAdd1,1
	.endif

	mov esi,0						;判断是否吃静态食物
	mov count,0

	.while TRUE
		.break .if(count>=100)
	mov ax,sFood[esi].posX
	mov bx,sFood[esi].posY
	.if sx==ax && sy==bx   ;静态食物吃了就被吃了
		mov sFood[esi].axes,0	;清0
		add	score,10
		mov sAdd1,1
		.break
	.endif

	add count,1
	add esi,sLen
	.endw

	mov esi,sLen  ;这里原本是sLen，留下一个位置					
	mov next,1
	.while TRUE				;判断头尾相接自杀
		.break .if next==0
		mov ax,sList1[esi].posX
		mov bx,sList1[esi].posY
		.if sx==ax && sy==bx
			jmp Snake1Dead
		.endif
		
		mov al,sList1[esi].next
		mov next,al
		add esi,sLen
	.endw
						;重新循环判断是否被蛇2击杀
	mov next,1
	mov esi,0
	.while TRUE				
		.break .if next==0
		mov ax,sList2[esi].posX
		mov bx,sList2[esi].posY
		.if sx==ax && sy==bx
			jmp Snake1Dead
		.endif
		
		mov al,sList2[esi].next
		mov next,al
		add esi,sLen
	.endw
	jmp snake2judge

Snake1Dead:
			mov esi,sLen						
			mov next,1
	.while TRUE					;死亡生成食物
		.break .if next==0
		mov ax,sList1[esi].posX
		mov bx,sList1[esi].posY
		invoke Dead_addFood, ax,bx
		
		mov al,sList1[esi].next
		mov next,al
		mov sList1[esi].next,0	;清楚节点
		add esi,sLen
	.endw

	invoke KillTimer,hMainWin,ID_TIMER2
	;invoke moveSnake1
	invoke InitSnake1
	invoke	SetTimer,hMainWin,ID_TIMER2,speed1,NULL
	

snake2judge:
	mov next,1
	mov esi,0
	
	mov ax,sList2[esi].posX
	mov sx,ax
	mov ax,sList2[esi].posY
	mov sy,ax
	add esi,sLen
	
	.if sx<10 || sx>390 || sy<10 || sy>390 
		jmp existP
	.endif
	
	mov ax,dFood.posX
	mov bx,dFood.posY
	.if sx==ax && sy==bx
		invoke addDFood
		add	score,10
		mov sAdd2,1
	.endif

	mov esi,0						;判断是否吃静态食物
	mov count,0
	.while TRUE
		.break .if(count>=100)
	mov ax,sFood[esi].posX
	mov bx,sFood[esi].posY
	.if sx==ax && sy==bx
		
		mov sFood[esi].axes,0	;清0
		add	score,10
		mov sAdd2,1
		.break
	.endif
	add count,1
	add esi,sLen
	.endw

	mov esi,sLen
	.while TRUE				;判断头尾相接自杀
		.break .if next==0
		mov ax,sList2[esi].posX
		mov bx,sList2[esi].posY
		.if sx==ax && sy==bx
			jmp Snake2Dead
		.endif
		
		mov al,sList2[esi].next
		mov next,al
		add esi,sLen
	.endw
						;重新循环判断是否被蛇1击杀
	mov next,1
	mov esi,0
	.while TRUE				
		.break .if next==0
		mov ax,sList1[esi].posX
		mov bx,sList1[esi].posY
		.if sx==ax && sy==bx
			jmp Snake2Dead
		.endif
		
		mov al,sList1[esi].next
		mov next,al
		add esi,sLen
	.endw
	ret					;第二个判断完return

Snake2Dead:
		mov esi,sLen						
		mov next,1
	.while TRUE					;死亡生成食物
		.break .if next==0
		mov ax,sList2[esi].posX
		mov bx,sList2[esi].posY
		invoke Dead_addFood, ax,bx
		
		mov al,sList2[esi].next
		mov next,al
		mov sList2[esi].next,0	;清楚节点
		add esi,sLen
	.endw

	invoke KillTimer,hMainWin,ID_TIMER3
	;invoke moveSnake2
	invoke InitSnake2
	invoke	SetTimer,hMainWin,ID_TIMER3,speed2,NULL
	
		ret				

existP:
		invoke KillTimer,hMainWin,ID_TIMER2
		invoke KillTimer,hMainWin,ID_TIMER3
		invoke KillTimer,hMainWin,ID_TIMER4

		invoke MessageBox,NULL,offset goGame,offset winCaption,MB_YESNO
		.if	eax==IDYES
			invoke	startGame
			invoke	SetTimer,hMainWin,ID_TIMER2,speed1,NULL
			invoke	SetTimer,hMainWin,ID_TIMER3,speed2,NULL
			invoke	SetTimer,hMainWin,ID_TIMER4,speedfood,NULL
		.else
			invoke	ExitProcess,NULL
		.endif
		ret

testCollide endp


MoveFood proc uses eax

		local sx:WORD
		local sy:WORD

		mov al,dFood.axes    ;将食物的位置进行移动
		.if 		al==4
			add dFood.posX,10
		.elseif 	al==3
			sub dFood.posX,10
		.elseif 	al==2
			add dFood.posY,10
		.elseif 	al==1
			sub dFood.posY,10
		.endif
		
		mov ax,dFood.posX
		mov sx,ax
		mov ax,dFood.posY
		mov sy,ax

		.if sx<20 
		mov  dFood.axes,4
		mov dFood.posX,20
		.elseif sx>380
		mov dFood.axes,3
		mov dFood.posX,380
		.endif 

		.if sy<20 
		mov  dFood.axes,2
		mov dFood.posY,20
		.elseif sy>380
		mov dFood.axes,1
		mov dFood.posY,380
		.endif 
		ret
MoveFood endp

changeFoodAxes proc uses eax ebx
	
	local sx:WORD
	local sy:WORD
	mov ax,dFood.posX
	mov sx,ax
	mov ax,dFood.posY
	mov sy,ax
	.if sx>50 && sx<350 && sy>50 && sy<350 
		mov AL,axes1
		add  AL,axes2
		mov BL,4
		DIV BL
		INC AH
		mov dFood.axes,AH
	.endif
	ret

changeFoodAxes endp

moveSnake1 proc uses esi
	local next:BYTE
	local oldAxes:BYTE
	
	mov next,1
	mov esi,0
	
	mov al,sList1[esi].axes
	mov oldAxes,al
	mov al,axes1
	mov sList1[esi].axes,al
	
	.while TRUE
		.break .if	next==0
		.if esi>0
			mov ah,sList1[esi].axes
			mov al,oldAxes
			mov sList1[esi].axes,al
			mov oldAxes,ah
		.endif
		
		mov al,sList1[esi].axes
		.if 		al==4
			add sList1[esi].posX,10
		.elseif 	al==3
			sub sList1[esi].posX,10
		.elseif 	al==2
			add sList1[esi].posY,10
		.elseif 	al==1
			sub sList1[esi].posY,10
		.endif
		
		mov al,sList1[esi].next
		mov next,al
		add esi,sLen
		
	.endw
	.if sAdd1==1
		invoke addSnake1
		mov sAdd1,0
	.endif
	
	invoke testCollide
	xor eax,eax
	
	ret
moveSnake1 endp	

moveSnake2 proc uses esi
	local next:BYTE
	local oldAxes:BYTE
	
	mov next,1
	mov esi,0
	
	mov al,sList2[esi].axes
	mov oldAxes,al
	mov al,axes2
	mov sList2[esi].axes,al
	
	.while TRUE
		.break .if	next==0
		.if esi>0
			mov ah,sList2[esi].axes
			mov al,oldAxes
			mov sList2[esi].axes,al
			mov oldAxes,ah
		.endif
		
		mov al,sList2[esi].axes
		.if 		al==4
			add sList2[esi].posX,10
		.elseif 	al==3
			sub sList2[esi].posX,10
		.elseif 	al==2
			add sList2[esi].posY,10
		.elseif 	al==1
			sub sList2[esi].posY,10
		.endif
		
		mov al,sList2[esi].next
		mov next,al
		add esi,sLen
		
	.endw
	.if sAdd2==1
		invoke addSnake2
		mov sAdd2,0
	.endif
	
	invoke testCollide
	xor eax,eax
	
	ret
moveSnake2 endp	

changeAxes1 proc value:BYTE
	mov	al,sList1[0].axes
	.if	value==1 && al!=2 || value==2 && al!=1 || value==3 && al!=4 || value==4 && al!=3
		mov al,value
		mov axes1,al
	.endif
	ret
changeAxes1 endp

changeAxes2 proc value:BYTE
	mov	al,sList2[0].axes
	.if	value==1 && al!=2 || value==2 && al!=1 || value==3 && al!=4 || value==4 && al!=3
		mov al,value
		mov axes2,al
	.endif
	ret
changeAxes2 endp

changeSpeed1 proc typ:DWORD
	
	.if typ==1
		.if	speed1>30
			sub	speed1,30
			add	level,1
		.endif
	.elseif typ==0
		.if	speed1<500
			add	speed1,30
			sub	level,1
		.endif
	.endif 
	invoke	KillTimer,hMainWin,ID_TIMER2
	invoke	SetTimer,hMainWin,ID_TIMER2,speed1,NULL
	
	ret
changeSpeed1 endp

changeSpeed2 proc typ:DWORD
	
	.if typ==1
		.if	speed2>30
			sub	speed2,30
			add	level,1
		.endif
	.elseif typ==0
		.if	speed2<500
			add	speed2,30
			sub	level,1
		.endif
	.endif 
	invoke	KillTimer,hMainWin,ID_TIMER3
	invoke	SetTimer,hMainWin,ID_TIMER3,speed2,NULL
	
	ret
changeSpeed2 endp

startGame proc
	mov	level,0
	mov	speed1,300
	mov	speed2,300
	
	invoke 	InvalidateRect,hMainWin,NULL,TRUE
	invoke 	changeAxes1,4
	invoke  changeAxes2,4
	invoke	changeRandom
	invoke  InitFood
	invoke	InitSnake1
	invoke	InitSnake2

	mov dFood.axes,3
	invoke	addDFood
	ret
startGame endp

WinProc	proc hWnd:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
	local curRect:RECT
	
	.if	uMsg==WM_CREATE
		invoke	SetTimer,hWnd,ID_TIMER1,50,NULL
		invoke	SetTimer,hWnd,ID_TIMER2,speed1,NULL
		invoke	SetTimer,hWnd,ID_TIMER3,speed2,NULL
		invoke	SetTimer,hWnd,ID_TIMER4,speedfood,NULL

		invoke	startGame
		
	.elseif	uMsg==WM_KEYDOWN
		
		.if wParam==VK_LEFT
			invoke changeAxes1,3
		.elseif wParam==VK_RIGHT
		   invoke changeAxes1,4
		.elseif wParam==VK_UP
		   invoke changeAxes1,1
		.elseif wParam==VK_DOWN
		   invoke changeAxes1,2
		.elseif wParam==VK_SPACE
			mov sAdd1,1
		;.elseif wParam==VK_ADD
		;	invoke changeSpeed,1
		;.elseif wParam==VK_SUBTRACT
		;	invoke changeSpeed,0
		.endif

		.if wParam==VK_A
			invoke changeAxes2,3
		.elseif wParam==VK_D
		   invoke changeAxes2,4
		.elseif wParam==VK_W
		   invoke changeAxes2,1
		.elseif wParam==VK_S
		   invoke changeAxes2,2
		.elseif wParam==VK_G
		   mov sAdd2,1

		.endif

	.elseif  uMsg==WM_TIMER
		.if		wParam==ID_TIMER1
			invoke	drawSnake
			invoke	drawInfo
			invoke	drawFood  ;使用drawFood调用drawdFood
			invoke	changeRandom
			
		.elseif 	wParam==ID_TIMER2
			;invoke 	InvalidateRect,hMainWin,NULL,TRUE;擦除背景
			invoke 	moveSnake1
			
			
		.elseif 	wParam==ID_TIMER3
			invoke  moveSnake2

		.elseif 	wParam==ID_TIMER4
			invoke changeFoodAxes
			invoke MoveFood

		.endif
		
	.elseif	uMsg==WM_CLOSE
		invoke KillTimer,hWnd,ID_TIMER1
		invoke KillTimer,hWnd,ID_TIMER2
		invoke DestroyWindow,hWnd
		invoke PostQuitMessage,NULL
			
	.else
		invoke DefWindowProc,hWnd,uMsg,wParam,lParam
	.endif
	ret
WinProc	endp

WinMain proc hInst:DWORD,hPrevInst:DWORD,CmdLine:DWORD,CmdShow:DWORD
	local	_wc:WNDCLASSEX
	local	uMsg:MSG
	
	invoke	RtlZeroMemory,addr _wc,sizeof _wc
	mov		_wc.cbSize,sizeof WNDCLASSEX
	mov		_wc.style,CS_HREDRAW or CS_VREDRAW or CS_BYTEALIGNWINDOW
	mov		_wc.lpfnWndProc,offset	WinProc
	push		hInstance
	pop		_wc.hInstance
	mov		_wc.hbrBackground,COLOR_APPWORKSPACE
	mov		_wc.lpszClassName,offset myClassName
	invoke	LoadCursor,NULL,IDC_ARROW
	mov		_wc.hCursor,eax
	invoke	RegisterClassEx,addr _wc
	
	invoke	CreateWindowEx,0,offset myClassName,offset winCaption,WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,CW_USEDEFAULT,510,442,0,0,hInstance,0
	mov		hMainWin,eax
	
	invoke	ShowWindow,hMainWin,SW_SHOWNORMAL
	invoke	UpdateWindow,hMainWin
	
	.while	hMainWin
		invoke	GetMessage,addr uMsg,0,0,0
		.break .if eax==0
		invoke	TranslateMessage,addr uMsg
		invoke	DispatchMessage,addr uMsg
	.endw
	ret
WinMain endp

end start