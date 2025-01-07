; Program dodatkowy Architektura Komputerow line drawer
; Autor: Jeremi Lipiec 200838

; Program na podstawie podanych 3-wymiarowych punktów oraz podanych krawedzi buduje 3-wymarowy obiekt.
; Natepnie wykonuje rzut prosty na ekran calego obiektu i pokazuje go na ekranie.
; Po nacisnieciu dowolnego przycisku program wykonuje 360 rotacji obiektu po 3 osiach (x, y i z) o sprecyzowany kat.

org 100h
	
main: ; screen 320x200
	finit

	call cls
	call displayStartScreen
	call loadFigure

	mov ax, 13h ; set draw mode
	int 10h

	call clearBg
	call drawRotatedWireFrame

	mov ah, 9 ; write start info
	mov dx, infoSt
	int 21h

	mov ah, 1 ; wait for user to start rotating
	int 21h

	call clearBg

	.enless:
	call animateShape
	;jmp .enless

	mov ah, 9 ; write end info
	mov dx, infoEn
	int 21h

	mov ah, 1
	int 21h
	
end:
	; reset screen colors
	mov [txtCol], byte 0h
	mov [tbgCol], byte 7h

	mov	ax, 4C00h
	int	21h

; == SETTINGS ==

centerX dd 160.0 ; screen center x
centerY	dd 100.0 ; screen center y
centerZ dd 0.0   ; screen center z

bgColor	db 20 ; color of the background
pxColor db 28 ; color of the drawn pixels

rotSpdX	dd 1.0 ; degrees per rotation iteration on x axis
rotSpdY	dd 1.0 ; degrees per rotation iteration on y axis
rotSpdZ	dd 1.0 ; degrees per rotation iteration on z axis

focusL	dd 250.0 ; focus length of the camera

; == WIREFRAME VERTICES AND EDGES ==
; all vertices are relative to origin center (0, 0, 0) Y IS FLIPPED!

; == custom mesh ==
vertsC_cus	dw 8 ; count of vertices
edgesC_cus	dw 12 ; count of edges

verts_cus	dd  50.0,  50.0, 50.0
			dd  50.0, -50.0, 50.0
			dd -50.0, -50.0, 50.0
			dd -50.0,  50.0, 50.0
			dd  0.0,  50.0,  30.0
			dd  50.0, -50.0, -50.0
			dd -50.0, -50.0, -50.0
			dd -50.0,  50.0, -50.0

edges_cus	dw 0, 1 ; line between verts id 0 and id 1
			dw 1, 2
			dw 2, 3
			dw 3, 0
			dw 4, 5
			dw 5, 6
			dw 6, 7
			dw 7, 4
			dw 0, 4
			dw 1, 5
			dw 2, 6
			dw 3, 7

; for use in functions

vertsC	dw 0
edgesC	dw 0
verts	times 150 dd 0.0 ; limit 50 verts
edges	times 100 dw 0 ; limit 50 edges

rotAmp	dw 360

rotX	dd 0.0
rotY	dd 0.0
rotZ	dd 0.0

line	dd 0.0, 0.0, 0.0, 0.0

vertsR	times 25 dd 0.0
vertsP	times 25 dd 0.0

vertId	dw 0
edgeId	dw 0

vertX	dd 0.0
vertY	dd 0.0
vertZ	dd 0.0

vertRX	dd 0.0
vertRY	dd 0.0
vertRZ	dd 0.0

tempRX	dd	0
tempRY	dd	0
tempRZ	dd	0

vertPX	dd 0.0
vertPY	dd 0.0

focX	dd 0
focY	dd 0
focZ	dd 0

num180	dd 180.0
sinres	dd 0.0
cosres	dd 0.0
trgres1	dd 0.0
trgres2	dd 0.0

_x1		dw 0
_y1		dw 0
_x2		dw 0
_y2		dw 0

_dx		dw 0
_dy		dw 0

_dxa	dw 0
_dya	dw 0

_px		dw 0
_py		dw 0

; ekran na 80 znakow

selFig	dw 0
txtCol	db 00ah
tbgCol	db 010h

infoSt	db "  Kliknij dowolny klawisz aby obrocic   $"
infoEn	db "   Kliknij dowolny klawisz aby wyjsc    $"

info0	db 58, "===== Witaj w programie do renderowania obiektow 3D! ====="
info1	db 30, "Wybierz figure do zaladowania:"
info2	db 30, "(Bledny wybor laduje szescian)"
iopt1	db 43, "[1] Szescian                               "
iopt2	db 43, "[2] Ostroslup prawidlowy czworokatny       "
iopt3	db 43, "[3] Ostroslup prawidlowy trojkatny         "
iopt4	db 43, "[4] Graniastoslup prawidlowy szesciokatny  "
iopt5	db 43, "[5] Serce                                  "
iopt6	db 43, "[6] Niestandardowa                         "
info3	db 7,  "Wybor: "

animateShape:
	pusha
	pushf

	mov cx, [rotAmp]
	.for:
		call incAngX
		call incAngY
		call incAngZ

		call clearBg
		call drawRotatedWireFrame
		call sleep
	loop .for

	popf
	popa
ret

displayStartScreen:
	pusha
	pushf

	call cls

	mov ax, info0 ; string
	push word 4 ; line number
	push ax
	call writeCentered

	mov [txtCol], byte 00bh
	mov ax, info1
	push word 10
	push ax
	call writeCentered

	mov ax, info2
	push word 11
	push ax
	call writeCentered

	mov ax, iopt1
	push word 13
	push ax
	call writeCentered

	mov ax, iopt2
	push word 14
	push ax
	call writeCentered

	mov ax, iopt3
	push word 15
	push ax
	call writeCentered

	mov ax, iopt4
	push word 16
	push ax
	call writeCentered

	mov ax, iopt5
	push word 17
	push ax
	call writeCentered

	mov ax, iopt6
	push word 18
	push ax
	call writeCentered

	mov ax, info3
	push word 21
	push ax
	call writeCentered

	mov ah, 1 ; selected
	int 21h
	xor ah, ah
	sub al, 48
	mov [selFig], ax

	call checkInpFig

	popf
	popa
ret

checkInpFig:
	pusha
	pushf

	mov ax, [selFig]
	cmp ax, 1
	jl .err

	cmp ax, 6
	jg .err

	jmp .return

	.err:
		mov [selFig], word 1
	.return:

	popf
	popa
ret

writeCentered: ; writes centered text from stack
	pusha
	pushf

	mov bp, sp ; row number [bp + 22]
	
	; get string length into cx

	mov bx, [bp + 20]
	mov cx, [bx]
	xor ch, ch

	; set cursor position

	mov ax, [bp + 22] ; row
	mov dh, al ;Cursor position row

	mov bx, 80
	sub bx, cx
	shr bx, 1
	mov ah, bl

	mov dl, ah ;Cursor position column

	; write string
	mov bx, [bp + 20]
	mov si, 1
	.for:
		xor ax, ax

		mov al, dh ; push position row
		push ax
		mov al, dl ; push position column
		push ax

		mov ax, [bx + si] ; push leter
		xor ah, ah
		push ax 

		call writeLetter
		inc dl
		inc si
	loop .for

	mov cx, [bp + 18] ; cx = ret
    mov [bp + 22], cx ; push ret

	popf
	popa
	add sp, 4
ret

writeLetter:
	pusha
	pushf
	; row    [bp + 24]
	; column [bp + 22]
	; letter [bp + 20]
	mov bp, sp

	; set cursor position, ah2 / int10h
	xor bh, bh ;page number
	mov ax, [bp + 22] ; column
	mov dl, al
	mov ax, [bp + 24] ; row
	mov dh, al

	mov ah, 02h
	int 10h

	; write char and attrb, ah9 / int10h
	xor bh, bh ;page number
	mov bl, [txtCol] ; color
	add bl, [tbgCol] ; add background color
	mov cx, 1 ; write 1 time
	mov dx, [bp + 20] 
	mov al, dl

	mov ah, 09h
	int 10h

	mov cx, [bp + 18] ; cx = ret
    mov [bp + 24], cx ; push ret
	popf
	popa
	add sp, 6
ret

loadFigure:
	pusha
	pushf

	mov ax, [selFig]

	cmp ax, 1
	jne .cont1
		call loadCube
	.cont1:

	cmp ax, 2
	jne .cont2
		call loadPyra
	.cont2:

	cmp ax, 3
	jne .cont3
		call loadTriPyra
	.cont3:

	cmp ax, 4
	jne .cont4
		call loadGrPS
	.cont4:

	cmp ax, 5
	jne .cont5
		call loadHrt
	.cont5:

	cmp ax, 6
	jne .cont6
		call LoadCus
	.cont6:

	popf
	popa
ret

loadCube:
	pusha
	pushf

	mov ax, [vertsC_cub]
	mov [vertsC], ax

	mov ax, [edgesC_cub]
	mov [edgesC], ax

	; copy vertices
	mov cx, [vertsC]
	add cx, [vertsC]
	add cx, [vertsC]
	xor si, si
	.forv:
		mov eax, [verts_cub + si]
		mov [verts + si], eax
		add si, 4
	loop .forv

	; copy edges
	mov cx, [edgesC]
	add cx, [edgesC]
	xor si, si
	.fore:
		mov ax, [edges_cub + si]
		mov [edges + si], ax
		add si, 2
	loop .fore

	popf
	popa
ret

loadPyra:
	pusha
	pushf

	mov ax, [vertsC_pyr]
	mov [vertsC], ax

	mov ax, [edgesC_pyr]
	mov [edgesC], ax

	; copy vertices
	mov cx, [vertsC]
	add cx, [vertsC]
	add cx, [vertsC]
	xor si, si
	.forv:
		mov eax, [verts_pyr + si]
		mov [verts + si], eax
		add si, 4
	loop .forv

	; copy edges
	mov cx, [edgesC]
	add cx, [edgesC]
	xor si, si
	.fore:
		mov ax, [edges_pyr + si]
		mov [edges + si], ax
		add si, 2
	loop .fore

	popf
	popa
ret

loadTriPyra:
	pusha
	pushf

	mov ax, [vertsC_pyrt]
	mov [vertsC], ax

	mov ax, [edgesC_pyrt]
	mov [edgesC], ax

	; copy vertices
	mov cx, [vertsC]
	add cx, [vertsC]
	add cx, [vertsC]
	xor si, si
	.forv:
		mov eax, [verts_pyrt + si]
		mov [verts + si], eax
		add si, 4
	loop .forv

	; copy edges
	mov cx, [edgesC]
	add cx, [edgesC]
	xor si, si
	.fore:
		mov ax, [edges_pyrt + si]
		mov [edges + si], ax
		add si, 2
	loop .fore

	popf
	popa
ret

loadGrPS:
	pusha
	pushf

	mov ax, [vertsC_grps]
	mov [vertsC], ax

	mov ax, [edgesC_grps]
	mov [edgesC], ax

	; copy vertices
	mov cx, [vertsC]
	add cx, [vertsC]
	add cx, [vertsC]
	xor si, si
	.forv:
		mov eax, [verts_grps + si]
		mov [verts + si], eax
		add si, 4
	loop .forv

	; copy edges
	mov cx, [edgesC]
	add cx, [edgesC]
	xor si, si
	.fore:
		mov ax, [edges_grps + si]
		mov [edges + si], ax
		add si, 2
	loop .fore

	popf
	popa
ret

loadHrt:
	pusha
	pushf

	mov ax, [vertsC_hrt]
	mov [vertsC], ax

	mov ax, [edgesC_hrt]
	mov [edgesC], ax

	; copy vertices
	mov cx, [vertsC]
	add cx, [vertsC]
	add cx, [vertsC]
	xor si, si
	.forv:
		mov eax, [verts_hrt + si]
		mov [verts + si], eax
		add si, 4
	loop .forv

	; copy edges
	mov cx, [edgesC]
	add cx, [edgesC]
	xor si, si
	.fore:
		mov ax, [edges_hrt + si]
		mov [edges + si], ax
		add si, 2
	loop .fore

	popf
	popa
ret

LoadCus:
	pusha
	pushf

	mov ax, [vertsC_cus]
	mov [vertsC], ax

	mov ax, [edgesC_cus]
	mov [edgesC], ax

	; copy vertices
	mov cx, [vertsC]
	add cx, [vertsC]
	add cx, [vertsC]
	xor si, si
	.forv:
		mov eax, [verts_cus + si]
		mov [verts + si], eax
		add si, 4
	loop .forv

	; copy edges
	mov cx, [edgesC]
	add cx, [edgesC]
	xor si, si
	.fore:
		mov ax, [edges_cus + si]
		mov [edges + si], ax
		add si, 2
	loop .fore

	popf
	popa
ret

clearBg: ; clear background with set color
	pusha
	pushf

    mov ax, 0600h
    mov bh, [bgColor]
    mov cx, 0000h
    mov dx, 184fh
    int 10h

	popf
	popa
ret

sleep:
	pusha
	pushf

	mov cx, 25000
	.for:
		nop
	loop .for

	popf
	popa
ret

resetShape: ; reset angle and redraw shape
	pusha
	pushf

	call clearBg

	fldz
	fldz
	fldz
	fstp dword [rotX]
	fstp dword [rotY]	
	fstp dword [rotZ]

	call drawRotatedWireFrame

	popf
	popa
ret

incAngX:
	pusha
	pushf

	fld dword [rotX]
	fld dword [rotSpdX]
	faddp
	fstp dword [rotX]

	popf
	popa
ret

incAngY:
	pusha
	pushf

	fld dword [rotY]
	fld dword [rotSpdY]
	faddp
	fstp dword [rotY]

	popf
	popa
ret

incAngZ:
	pusha
	pushf

	fld dword [rotZ]
	fld dword [rotSpdZ]
	faddp
	fstp dword [rotZ]

	popf
	popa
ret

getVert: ; gets vertex from id and stores into vertX, vertY and vertZ
	pusha
	pushf

	mov ax, [vertId]
	mov bx, 12
	mul bx

	mov si, ax	

	mov eax, [verts + si] ; vert x
	mov [vertX], eax
	mov eax, [verts + si + 4] ; vert y
	mov [vertY], eax
	mov eax, [verts + si + 8] ; vert z
	mov [vertZ], eax

	popf
	popa
ret

getPVert: ; gets vertp from id and stores into projX and projY
	pusha
	pushf

	mov ax, [vertId]
	mov bx, 8
	mul bx

	mov si, ax	

	mov [vertPX], eax; projected vert x
	mov eax, [vertsP + si]

	mov [vertPY], eax; projected vert x
	mov eax, [vertsP + si+ 4]

	popf
	popa
ret

setPVert: ; saves from projX and projY to vertp by id 
	pusha
	pushf

	mov ax, [vertId]
	mov bx, 8
	mul bx

	mov si, ax	

	mov eax, [vertPX]; projected vert x
	mov [vertsP + si], eax

	mov eax, [vertPY]; projected vert y
	mov [vertsP + si + 4], eax

	popf
	popa
ret

drawProjectedVert: ; raws selected vert by id 
	pusha
	pushf
	mov bp, sp
	sub sp, 2

	call getPVert

	fld dword [vertPY] ; vert y
	fistp word [bp + 2]
	push word [bp + 2]

	fld dword [vertPX] ; vert x
	fistp word [bp + 2]
	push word [bp + 2]

	call setpixel

	add sp, 2
	popf
	popa
ret

drawEdge: ; draws selected edge by id between verts
	pusha
	pushf

	mov di, [edgeId]
	shl di, 2

	; get start vertex
	mov ax, [edges + di] ; get start vertex id
	shl ax, 3

	mov si, ax

	mov eax, [vertsP + si] ; start vert x
	mov [line], eax

	mov eax, [vertsP + si + 4] ; start vert y
	mov [line + 4], eax

	; get end vertex
	mov ax, [edges + di + 2] ; get end vertex id
	shl ax, 3

	mov si, ax

	mov eax, [vertsP + si] ; end vert x
	mov [line + 8], eax

	mov eax, [vertsP + si + 4] ; end vert y
	mov [line + 12], eax

	call drawline

	popf
	popa
ret

drawAllEdges: ; draw all edges to projected vertices
	pusha
	pushf

	mov cx, [edgesC]
	xor ax, ax
	.for2:
		mov [edgeId], ax
		call drawEdge
		inc ax
	loop .for2

	popf
	popa
ret

drawRotatedWireFrame: ; draw wireframe rotated by specified angle around specified axis
	pusha
	pushf

	; for all verts, rotate vert, project and draw
	mov cx, [vertsC]
	xor ax, ax
	.for:
		mov [vertId], ax

		call loadVertToRotate
		call rotVtX
		call rotVtY
		call rotVtZ

		call projRotatedVert
		call drawProjectedVert
		inc ax
	loop .for

	; draw all edges between projected verts
	call drawAllEdges	

	popf
	popa
ret

loadVertToRotate:
	pusha
	pushf

	call getVert
	mov eax, [vertX]
	mov [vertRX], eax
	mov eax, [vertY]
	mov [vertRY], eax
	mov eax, [vertZ]
	mov [vertRZ], eax

	popf
	popa
ret

rotVtX: ; rotate vertex selected by id around x axis by set amount of degrees
	pusha
 	pushf
 	mov bp, sp

	call cSinCosX ; calculate sin and cos for current rotation

	; calculate new y
	fld dword [vertRY] ; st0 = pY
	fld dword [cosres] ; st1 = cos(a)
	fmulp ; st0 = pY * cos(a)
	fstp dword [trgres2] ; save pY * cos(a)

	fld dword [vertRZ] ; st0 = pZ
	fld dword [sinres] ; st1 = sin(a)
	fmulp ; st0 = pZ * sin(a)
	fstp dword [trgres1] ; save pZ * sin(a)

	fld dword [trgres2] ; pY * cos(a)
	fld dword [trgres1] ; pZ * sin(a)
	fsubp ; st0 - st1, pY * cos(a) - pZ * sin(a) = new y

	fstp dword [tempRY] ; save new y to var

	; calculate new z
	fld dword [vertRY] ; st0 = pY
	fld dword [sinres] ; st1 = sin(a)
	fmulp ; st0 = pY * sin(a)
	fstp dword [trgres2] ; save pY * sin(a)

	fld dword [vertRZ] ; st0 = pZ
	fld dword [cosres] ; st1 = cos(a)
	fmulp ; st0 = pZ * cos(a)
	fstp dword [trgres1] ; save pZ * cos(a)

	fld dword [trgres1] ; pZ * cos(a)
	fld dword [trgres2] ; pY * sin(a)
	faddp ; st0 + st1, pZ * cos(a) + pY * sin(a) = new z

	fstp dword [tempRZ] ; save new z to var

	; save to rotated verts
	mov eax, [tempRY]
	mov [vertRY], eax

	mov eax, [tempRZ]
	mov [vertRZ], eax

 	popf
 	popa
ret

rotVtY: ; rotate vertex selected by id around y axis by set amount of degrees ; doesnt work
	pusha
 	pushf
 	mov bp, sp

	call cSinCosY ; calculate sin and cos for current rotation

	; calculate new x
	fld dword [vertRZ] ; st0 = pZ
	fld dword [sinres] ; st1 = sin(a)
	fmulp ; st0 = pZ * sin(a)
	fstp dword [trgres2] ; save pZ * sin(a)

	fld dword [vertRX] ; st0 = pX
	fld dword [cosres] ; st1 = cos(a)
	fmulp ; st0 = pX * cos(a)
	fstp dword [trgres1] ; save pX * cos(a)

	fld dword [trgres1] ; pX * cos(a)
	fld dword [trgres2] ; pZ * sin(a)
	faddp ; st0 + st1, pX * cos(a) + pZ * sin(a) = new x

	fstp dword [tempRX] ; save new x to var

	; calculate new z
	fld dword [vertRZ] ; st0 = pZ
	fld dword [cosres] ; st1 = cos(a)
	fmulp ; st0 = pZ * cos(a)
	fstp dword [trgres2] ; save pZ * cos(a)

	fld dword [vertRX] ; st0 = pX
	fld dword [sinres] ; st1 = sin(a)
	fmulp ; st0 = pX * sin(a)
	fstp dword [trgres1] ; save pX * sin(a)

	fld dword [trgres2] ; pZ * cos(a)
	fld dword [trgres1] ; pX * sin(a)
	fsubp ; st0 - st1, pZ * cos(a) - pX * sin(a) = new z

	fstp dword [tempRZ] ; save new y to var

	; save to rotated verts
	mov eax, [tempRX]
	mov [vertRX], eax

	mov eax, [tempRZ]
	mov [vertRZ], eax

 	popf
 	popa
ret

rotVtZ: ; rotate vertex selected by id around z axis by set amount of degrees and saves to vertsR array
	pusha
 	pushf
 	mov bp, sp

	call cSinCosZ ; calculate sin and cos for current rotation

	; calculate new x
	fld dword [vertRX] ; st0 = pX
	fld dword [cosres] ; st1 = cos(a)
	fmulp ; st0 = pX * cos(a)
	fstp dword [trgres1] ; save pX * cos(a)

	fld dword [vertRY] ; st0 = pY
	fld dword [sinres] ; st1 = sin(a)
	fmulp ; st0 = pY * sin(a)
	fstp dword [trgres2] ; save pY * sin(a)

	fld dword [trgres1] ; pX * cos(a)
	fld dword [trgres2] ; pY * sin(a)
	fsubp ; st0 - st1, pX * cos(a) - pY * sin(a) = new x

	fstp dword [tempRX] ; save new x to var

	; calculate new y
	fld dword [vertRX] ; st0 = pX
	fld dword [sinres] ; st1 = sin(a)
	fmulp ; st0 = pX * sin(a)
	fstp dword [trgres1] ; save pX * sin(a)

	fld dword [vertRY] ; st0 = pY
	fld dword [cosres] ; st1 = cos(a)
	fmulp ; st0 = pY * cos(a)
	fstp dword [trgres2] ; save pY * cos(a)

	fld dword [trgres1] ; pX * sin(a)
	fld dword [trgres2] ; pY * cos(a)
	faddp ; st0 + st1, pX * cos(a) + pY * sin(a) = new y

	fstp dword [tempRY] ; save new y to var

	; save to rotated verts
	mov eax, [tempRX]
	mov [vertRX], eax

	mov eax, [tempRY]
	mov [vertRY], eax

 	popf
 	popa
ret

projRotatedVert: ; projects vertex onto 2d and saves projected values into vertsP array
	pusha
 	pushf

	fld dword [focusL]
	fld dword [vertRX]

	fmulp
	fst dword [focX] ; focX = fl * x

	fld dword [focusL]
	fld dword [vertRY]
	fmulp
	fstp dword [focY] ; focY = fl * y

	fld dword [focusL]
	fld dword [vertRZ]
	faddp
	fstp dword [focZ] ; focZ = fl + z

	; calculate projection

	fld dword [focX]
	fld dword [focZ]
	fdivp
	fld dword [centerX]
	faddp
	fstp dword [vertPX] ; projected X = fl * x / fl + z

	fld dword [focY]
	fld dword [focZ]
	fdivp
	fld dword [centerY]
	faddp
	fstp dword [vertPY] ; projected Y = fl * y / fl + z

	; save projection into array

	call setPVert

	popf
	popa
ret

cSinCosX: ; calculate sin and cos of angle x
	pusha
 	pushf

	fldpi ; st0 = pi
	fld dword [num180] ; st1 = 180
	fdivp ; st0 = pi / 180
	fld dword [rotX] ; st1 = degrees
	fmul ; st0 = pi / 180 * degrees = angle in radians
	fsincos ; st1 = sin(a), st0 = cos(a)
	fstp dword [cosres] ; store cos value
	fstp dword [sinres] ; store sin value

	popf
 	popa
ret

cSinCosY: ; calculate sin and cos of angle y
	pusha
 	pushf

	fldpi ; st0 = pi
	fld dword [num180] ; st1 = 180
	fdivp ; st0 = pi / 180
	fld dword [rotY] ; st1 = degrees
	fmul ; st0 = pi / 180 * degrees = angle in radians
	fsincos ; st1 = sin(a), st0 = cos(a)
	fstp dword [cosres] ; store cos value
	fstp dword [sinres] ; store sin value

	popf
 	popa
ret

cSinCosZ: ; calculate sin and cos of angle z
	pusha
 	pushf

	fldpi ; st0 = pi
	fld dword [num180] ; st1 = 180
	fdivp ; st0 = pi / 180
	fld dword [rotZ] ; st1 = degrees
	fmul ; st0 = pi / 180 * degrees = angle in radians
	fsincos ; st1 = sin(a), st0 = cos(a)
	fstp dword [cosres] ; store cos value
	fstp dword [sinres] ; store sin value

	popf
 	popa
ret

debugLines: ; [old] draws debug lines in all dirrections to screen edges in different colors
	pusha
	pushf

	mov [line], word 160
	mov [line + 2], word 100
	mov [line + 4], word 0
	mov [line + 6], word 0

	mov bx, 10

	mov cx, 32
	.for:
		call drawline
		add [line + 4], bx
		add [pxColor], word 1
	loop .for

	mov cx, 20
	.for2:
		call drawline
		add [line + 6], bx
		add [pxColor], word 1
	loop .for2

	mov cx, 32
	.for3:
		call drawline
		sub [line + 4], bx
		add [pxColor], word 1
	loop .for3

	mov cx, 20
	.for4:
		call drawline
		sub [line + 6], bx
		add [pxColor], word 1
	loop .for4

	mov [pxColor], word 0 ; reset color back to black

	popf
	popa
ret

dcircle: ; [old] draws 'circle' made of lines
	pusha
	pushf
	mov bp, sp
	sub sp, 10

	; settings
	mov [line], word 160 ; center X
	mov [line + 2], word 100 ; center Y
	mov [bp + 4], word 90 ; radius X
	mov cx, 360 ; angle to draw

	mov [bp + 2], word 0 ; degrees
	mov [bp + 6], word 180 ; to radians
	; [bp + 8] result
	
	.for:
		fldpi
		fild word [bp + 6]
		fdivp
		fimul word [bp + 2] ; st0 = angle in radians
		fcos ; st0 = cos of angle in radians
		fld1 
		fadd ; st0 = cos(x) + 1

		fimul word [bp + 4]
		; st0 = cos(a) * radius
		fistp word [bp + 8]
		; [bp + 8] = cos(a) * radius

		mov ax, [bp + 8]
		add ax, [line]
		sub ax, [bp + 4]
		mov [line + 4], ax ; p1.x = cos(x) * radius

		fldpi
		fild word [bp + 6]
		fdivp
		fimul word [bp + 2] ; st0 = angle in radians
		fsin ; st0 = sin of angle in radians
		fld1 
		fadd ; st0 = sin(x) + 1

		fimul word [bp + 4]
		; st0 = sin(a) * radius
		fistp word [bp + 8]
		; [bp + 8] = sin(a) * radius

		mov ax, [bp + 8]
		add ax, [line + 2]
		sub ax, [bp + 4]
		mov [line + 6], ax ; p1.y = sin(x) * radius

		call drawline
		add [bp + 2], word 1
	loop .for

	add sp, 10
	popf
	popa
ret

dpCube: ; [old] draws pseudo cube
	pusha
	pushf

	mov bp, sp
	sub sp, 14

	mov [bp + 2], word 120 ; startX 1 square
	mov [bp + 4], word 80 ; startY 2 square

	mov [bp + 6], word 50 ; width
	mov [bp + 8], word 50 ; height

	mov [bp + 10], word 0 ; startX 1 square
	mov [bp + 12], word 0 ; startY 2 square

	; draw 1 square

	push word [bp + 2]
	push word [bp + 4]
	push word [bp + 6]
	push word [bp + 8]
	call dboxp

	; draw 2 square

	; get moved x for second square
	mov ax, [bp + 6]
	shr ax, 1
	add ax, [bp + 2]
	mov [bp + 10], ax

	; get moved y for second square
	mov ax, [bp + 4]
	mov cx, [bp + 8]
	shr cx, 1
	sub ax, cx
	mov [bp + 12], ax

	push word [bp + 10]
	push word [bp + 12]
	push word [bp + 6]
	push word [bp + 8]
	call dboxp

	; get line vector
	mov cx, [bp + 6] ; line width x
	shr cx, 1
	mov dx, [bp + 8] ; line height y
	shr dx, 1

	; draw edges
	mov ax, [bp + 2] ; line start x
	mov bx, [bp + 4] ; line start y

	mov [line + 0], word ax
	mov [line + 2], word bx
	add ax, cx
	mov [line + 4], word ax
	sub bx, dx
	mov [line + 6], word bx
	call drawline


	mov ax, [bp + 2] ; line start x
	mov bx, [bp + 4] ; line start y
	add bx, [bp + 8]

	mov [line + 0], word ax
	mov [line + 2], word bx
	add ax, cx
	mov [line + 4], word ax
	sub bx, dx
	mov [line + 6], word bx
	call drawline


	mov ax, [bp + 2] ; line start x
	add ax, [bp + 6]
	mov bx, [bp + 4] ; line start y

	mov [line + 0], word ax
	mov [line + 2], word bx
	add ax, cx
	mov [line + 4], word ax
	sub bx, dx
	mov [line + 6], word bx
	call drawline


	mov ax, [bp + 2] ; line start x
	add ax, [bp + 6]
	mov bx, [bp + 4] ; line start y
	add bx, [bp + 8]

	mov [line + 0], word ax
	mov [line + 2], word bx
	add ax, cx
	mov [line + 4], word ax
	sub bx, dx
	mov [line + 6], word bx
	call drawline

	add sp, 14
	popf
	popa
ret

dboxp: ; takes 4 values from stack: startX, startY, width, height and draws square, pops values
	pusha
 	pushf

 	mov bp, sp

	mov ax, [bp + 26] ; start X
	mov bx, [bp + 24] ; start Y
	mov cx, [bp + 22] ; width
	mov dx, [bp + 20] ; height

	add cx, ax
	add dx, bx

	mov [line + 0], ax
	mov [line + 2], bx
	mov [line + 4], cx
	mov [line + 6], bx
	call drawline

	mov [line + 0], cx
	mov [line + 2], bx
	mov [line + 4], cx
	mov [line + 6], dx
	call drawline

	mov [line + 0], cx
	mov [line + 2], dx
	mov [line + 4], ax
	mov [line + 6], dx
	call drawline

	mov [line + 0], ax
	mov [line + 2], dx
	mov [line + 4], ax
	mov [line + 6], bx
	call drawline

	mov ax, [bp + 18]
	mov [bp + 26], ax ; push ret

 	popf
 	popa
 	add sp, 8
ret

drawline: ; attempt 7, porb working, YES
	pusha
	pushf

	mov bp, sp
	sub sp, 16
	push si

	; ===== cast points to ints

	xor si, si
	xor di, di

	mov cx, 4
	.for:
		fld dword [line + si]
		fistp dword [bp + 2 + di]
		add si, 4
		add di, 2
	loop .for

	; get coordinates

	mov ax, [bp + 2]
	mov [_x1], ax

	mov ax, [bp + 4]
	mov [_y1], ax

	mov ax, [bp + 6]
	mov [_x2], ax

	mov ax, [bp + 8]
	mov [_y2], ax

	; ===== get diffs

	mov ax, [_x2]
	sub ax, [_x1]
	mov [_dx], ax

	mov ax, [_y2]
	sub ax, [_y1]
	mov [_dy], ax

	; get abs of dx and dy

	fild word [_dx]
	fabs
	fistp word [_dxa]

	fild word [_dy]
	fabs
	fistp word [_dya]

	; check if iterate by x or y, if dx >= dy iterate by x, otherwise y

	mov ax, [_dxa]
	cmp ax, [_dya]
	jl .iterByY

	; ===== iterate by dx on x

	; get line length in x
	mov cx, [_dxa]

	; if dx < 0, start from x2
	mov ax, [_dx]
	cmp ax, 0
	jl .dxless
	jg .dxmore

	.dxless:
		mov si, [_x2] ; starting x
		jmp .dxend
	.dxmore:
		mov si, [_x1] ; starting x
	.dxend:

	; iterate thru x

	.forx: ; for all x in line
		mov ax, si
		sub ax, [_x1]
		mov [_py], ax ; _ddx = x - x1

		; (dy / dx) * (x - x1) + y1 => onp: x x1 - dy dx / * y1 +
		fild word [_dy]
		fild word [_dx]
		fdivp
		;st0 = dy / dx
		fild word [_py]
		fmulp
		; st0 = (dy / dx) * (x - x1)
		fiadd word [_y1]
		; st0 = (dy / dx) * (x - x1) + y1
		fistp word [_py]

		push si
		push word [_py]
		call setpixel

		inc si
	loop .forx

	jmp .fin ; finished

	; ===== iterate by dy on y
	.iterByY:

	; get line length in y
	mov cx, [_dya]

	; if dy < 0, start from y2
	mov ax, [_dy]
	cmp ax, 0
	jl .dyless
	jg .dymore

	.dyless:
		mov si, [_y2] ; starting y
		jmp .dyend
	.dymore:
		mov si, [_y1] ; starting y
	.dyend:

	; iterate thru y

	.fory: ; for all y in line
		mov ax, si
		sub ax, [_y1]
		mov [_px], ax ; _ddy = y - y1

		; (dx / dy) * (y - y1) + x1 => onp: y y1 - dx dy / * x1 +
		fild word [_dx]
		fild word [_dy]
		fdivp
		;st0 = dx / dy
		fild word [_px]
		fmulp
		; st0 = (dx / dy) * (y - y1)
		fiadd word [_x1]
		; st0 = (dx / dy) * (y - y1) + x1
		fistp word [_px]

		push word [_px]
		push si
		call setpixel

		inc si
	loop .fory

	; ------------------------------

	.fin:

	pop si
	add sp, 16
	popf
	popa
ret

setpixel: ; draws white pixel on screen in given location, location in stack 16b x, 16b y, removes argument from stack
	pusha
 	pushf

 	mov bp, sp

	mov ax, 0A000h ; start video memory
	mov es, ax

	mov di, [bp + 22]
	mov ax, [bp + 20]
	mov bx, 320

	mul bx ; ax = y * 320 

	add di, ax ; di = y * 320 + x

	mov dl, [pxColor] ; color white
	mov [es:di], dl

	mov ax, [bp + 18]
	mov [bp + 22], ax ; push ret

 	popf
 	popa
 	add sp, 4
ret

endl: ; enter
	pusha
	pushf

	mov ah, 2
	mov dl, 10
	int 21h

	popf
	popa
ret

cls: ; clears screen
	pusha
	pushf

	mov cx, 25
	.for:
		mov ax, 80
		.for2:
	
			push cx
			push ax
			push ' '
			call writeLetter

		dec ax
		cmp ax, 0
		jge .for2
	dec cx
	cmp cx, 0
	jge .for

	popf
	popa
ret

debp: ; display 16b from stack in format (8b:8b) = value\n, pops value
    pusha
    pushf

    mov bp, sp    
    mov bx, [bp + 20] ; bx = last before ret

    mov ah, 2

    mov dl, 10
    int 21h

    mov dl, '('
    int 21h

    xor dx, dx
    mov dl, bh
    push dx
    call wdp

    mov dl, ':'
    int 21h

    xor dx, dx
    mov dl, bl
    push dx
    call wdp

    mov dl, ')'
    int 21h

    mov dl, '='
    int 21h

    push bx
    call wdp

    mov cx, [bp + 18] ; cx = ret
    mov [bp + 20], cx ; push ret

    popf
    popa

    add sp, 2
ret

wdp: ; writes in decimal value from stack (16b), pops value
    pusha
    pushf
    
    mov bp, sp
    mov ax, [bp + 20] ; ax = value

    xor si, si
    xor di, di
    mov bx, 10
    
    ; if negative value
    cmp ax, 0
    jge .not_neg

    mov di, 1
    fild word [bp + 20]
    fabs
    fist word [bp + 20]
    mov ax, [bp + 20]

    .not_neg:
    
    .for1:
        xor dx, dx
        div bx ; dx:ax / bx = ax r dx,  0:120 / 10
        
        push dx ; reszta na stos
        
        inc si
        cmp ax, 0
    jg .for1
    
    ; if number was negative add '-'
    cmp di, 0
    je .skip_neg

    mov ah, 2
    mov dl, '-'
    int 21h

    .skip_neg:

    .for2:
        pop dx

        add dl, 48
        mov ah, 2
        int 21h

        dec si
        cmp si, 0
    jg .for2

    mov cx, [bp + 18] ; cx = ret
    mov [bp + 20], cx ; push ret

    popf
    popa
    add sp, 2
ret

; === szescian
vertsC_cub	dw 8 ; count of vertices
edgesC_cub	dw 12 ; count of edges

verts_cub	dd  50.0,  50.0, 50.0
			dd  50.0, -50.0, 50.0
			dd -50.0, -50.0, 50.0
			dd -50.0,  50.0, 50.0
			dd  50.0,  50.0, -50.0
			dd  50.0, -50.0, -50.0
			dd -50.0, -50.0, -50.0
			dd -50.0,  50.0, -50.0

edges_cub	dw 0, 1 ; line between verts id 0 and id 1
			dw 1, 2
			dw 2, 3
			dw 3, 0
			dw 4, 5
			dw 5, 6
			dw 6, 7
			dw 7, 4
			dw 0, 4
			dw 1, 5
			dw 2, 6
			dw 3, 7

; === Ostroslup prawidlowy czworokatny ; szkoda że nie
vertsC_pyr	dw 5 ; count of vertices
edgesC_pyr	dw 8 ; count of edges

verts_pyr	dd  50.0, 50.0, 50.0
			dd -50.0, 50.0, 50.0
			dd  50.0, 50.0, -50.0
			dd -50.0, 50.0, -50.0
			dd  0.0, -50.0, 0.0

edges_pyr	dw 0, 1 ; line between verts id 0 and id 1
			dw 0, 2
			dw 2, 3
			dw 1, 3
			dw 0, 4
			dw 1, 4
			dw 2, 4
			dw 3, 4

; === Ostroslup prawidlowy trojkatny
vertsC_pyrt	dw 4 ; count of vertices
edgesC_pyrt	dw 6 ; count of edges

verts_pyrt	dd   0.0,  50.0,  50.0
			dd  43.3,  50.0, -24.9
			dd -43.3,  50.0, -25.1
			dd   0.0, -50.0,   0.0

edges_pyrt	dw 0, 1 ; line between verts id 0 and id 1
			dw 0, 2
			dw 1, 2
			dw 0, 3
			dw 1, 3
			dw 2, 3

; === Graniastoslup prawidlowy szesciokatny
vertsC_grps	dw 12 ; count of vertices
edgesC_grps	dw 18 ; count of edges

verts_grps	dd   0.0,  50.0,  50.0 ; bottom
			dd	43.2,  50.0,  25.0
			dd  43.3,  50.0, -24.9
			dd	 0.0,  50.0, -50.0
			dd -43.3,  50.0, -25.1
			dd -43.3,  50.0,  24.9
			dd   0.0, -50.0,  50.0 ; top
			dd	43.2, -50.0,  25.0
			dd  43.3, -50.0, -24.9
			dd	 0.0, -50.0, -50.0
			dd -43.3, -50.0, -25.1
			dd -43.3, -50.0,  24.9

edges_grps	dw 0, 1 ; line between verts id 0 and id 1
			dw 1, 2
			dw 2, 3
			dw 3, 4
			dw 4, 5
			dw 5, 0
			dw 6, 7
			dw 7, 8
			dw 8, 9
			dw 9, 10
			dw 10, 11
			dw 11, 6
			dw 6, 0
			dw 7, 1
			dw 8, 2
			dw 9, 3
			dw 10, 4
			dw 11, 5

; === serce
vertsC_hrt	dw 12 ; count of vertices
edgesC_hrt	dw 30 ; count of edges

verts_hrt	dd   0.0,   40.0,   0.0
			dd -20.0,   30.0,   0.0
			dd -40.0,   10.0,   0.0
			dd -40.0,  -20.0,   0.0
			dd -20.0,  -40.0,   0.0
			dd   0.0,  -20.0,   0.0
			dd  20.0,  -40.0,   0.0
			dd  40.0,  -20.0,   0.0
			dd  40.0,   10.0,   0.0
			dd  20.0,   30.0,   0.0
			dd   0.0,    0.0,  20.0
			dd   0.0,    0.0, -20.0

edges_hrt	dw 0, 1
			dw 1, 2
			dw 2, 3
			dw 3, 4
			dw 4, 5
			dw 5, 6
			dw 6, 7
			dw 7, 8
			dw 8, 9
			dw 9, 0
			dw 0, 10
			dw 1, 10
			dw 2, 10
			dw 3, 10
			dw 4, 10
			dw 5, 10
			dw 6, 10
			dw 7, 10
			dw 8, 10
			dw 9, 10
			dw 0, 11
			dw 1, 11
			dw 2, 11
			dw 3, 11
			dw 4, 11
			dw 5, 11
			dw 6, 11
			dw 7, 11
			dw 8, 11
			dw 9, 11