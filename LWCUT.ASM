CSEG	segment
	assume	cs:CSEG,ds:CSEG
	org	100h
Start:
	jmp	Install
New21:
	cmp	ax,3034h
	jnz	Not_Req
	cmp	bx,5178h
	jnz	Not_Req
	mov	ax,5501h
	push	cs
	pop	es
	iret
Not_Req:
	cmp	ah,3Ch
	jnz	Ex21
	cmp	dx,01B4Eh
	jnz	Ex21
	push	ds
	push	dx
	push	cs
	pop	ds
	mov	dx,offset FName
	pushf
	call	dword ptr ds:old21o
	pop	dx
	call	IncCutNo
	pop	ds
	iret
Ex21:
        db      0EAh
old21o	dw	0
old21s	dw	0

FName	db	'lwcut.'
CutNoSu	db	'0'
CutNoHi	db	'0'
CutNoLo	db	'0'
EFName	db	0

IncCutNo:
	push	ax
	mov	al,CutNoLo
	mov	ah,CutNoHi
	call	PICutNo
	mov	CutNoHi,ah
	mov	CutNoLo,al
	pop	ax
	ret

PICutNo:
	cmp	al,'9'
	jnz	NotCutLo9
	mov	al,'A'
	ret
NotCutLo9:
	cmp	al,'Z'
	jnz	NotCutLoZ
	mov	al,'0'
	cmp	ah,'Z'
	jnz	NotCutHiZ
	mov	ah,'0'
	inc	byte ptr ds:CutNoSu
	ret
NotCutHiZ:
	cmp	ah,'9'
	jnz	NotCutHi9
	mov	ah,'A'
	ret
NotCutHi9:
	inc	ah
	ret
NotCutLoZ:
	inc	al
	ret
EndResident:
i21Addr	dw	21h*4,0

Install:
	mov	es,word ptr ds:[2Ch]
	mov	ah,49h
	int	21h

	mov	ah,30h
	int	21h
	cmp	al,3
	ja	OkDos
	jnz	WrongDos
	cmp	ah,20
	jnb	OkDos

WrongDos:
	lea	dx,DosVer
	jmp	PrintExit

OkDos:
	lea	dx,Msg
	mov	ah,9
	int	21h

	call	WLine

	mov	ax,3034h
	mov	bx,5178h
	int	21h
	cmp	ax,5501h
	jnz	NotInst
	cmp	byte ptr ds:[82h],'U'
	jnz	NotUnInst

	xor	ax,ax
	mov	ds,ax
	mov	bx,21h*4
	cmp	word ptr ds:[bx],offset New21
	jnz	Sor
	mov	ax,es
	cmp	word ptr ds:[bx+2],ax
	jnz	Sor
	
	mov	ax,word ptr es:old21o
	mov	word ptr ds:[bx],ax
	mov	ax,word ptr es:old21s
	mov	word ptr ds:[bx+2],ax

	mov	ah,49h
	int	21h	
	
	lea	dx,UnSuc
	jmp	short PrintExit_

Sor:
	lea	dx,CantUni
	jmp	short PrintExit_
NotUnInst:
	lea	dx,Alrea
PrintExit_:
	jmp	PrintExit
	
NotInst:
	cli
	lds	bx,dword ptr ds:i21Addr
	mov	ax,word ptr ds:[bx]
	mov	cs:old21o,ax
	mov	ax,word ptr ds:[bx+2]
	mov	cs:old21s,ax
	mov	ds:[bx],offset New21
	mov	ds:[bx+2],cs
	sti
	push	cs
	pop	ds
	lea	dx,InstMsg
	mov	ah,9
	int	21h
	call	WLine
	lea	dx,EndResident
	int	27h

PrintExit:
	push	cs
	pop	ds
	mov	ah,9
	int	21h
	call	WLine
Exit:
	mov	ax,4C00h
	int	21h

WLine:
	mov	cx,75
Wline_:
	mov	ah,2
	mov	dl,'-'
	int	21h
	loop	WLine_
	mov	dl,13
	mov	al,2
	int	21h
	mov	dl,10
	mov	al,2
	int	21h
	ret

Msg	db	7 dup('-'),' *** RS Graphics Utilities *** ',9 dup('-'),' Kishinev, RSsoftware ',6 dup('-'),10,13
	db	'LinkWayPaint Cut Advanced Utility  v1.0  Copyright (C) 1993 by MasyutinMax~',10,13,'$'
DosVer	db	'Incorrect DOS version.  This program requires DOS 3.20 or later.',10,13,'$'
Alrea	db	'Already installed.  Use  ~LWCUT U~  to uninstall it from memory.',10,13,'$'
CantUni	db	'Surry, but it is impossible to release LWCut from memory, because the',10,13
	db	'interrupt vector  21h, used by LWcut points to other program.',10,13
	db	'Release it from memory and try again.',10,13
	db	'If this program is non-releaseble, you ought to reset your computer.',10,13,'$'
UnSuc	db 	'LWcut uninstalled successfuly.',10,13,'$'
InstMsg	db	'Installed.',10,13,'$'
CSEG	ends
	end	Start