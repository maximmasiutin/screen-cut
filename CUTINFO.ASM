CSEG	segment
	assume	cs:CSEG,ds:CSEG
	org	100h
Start:
	mov	ah,30h
	int	21h
	cmp	al,2
	ja	RiVer
	int	20h

RiVer:
	cld
	push	cs
	pop	ds
	push	cs
	pop	es
	lea	dx,ABOUT
	mov	ah,9
	int	21h
	call	MyLine

	mov	si,80h
	lodsb
	or	al,al
	jnz	Next0
	lea	dx,Usage
	jmp	Exit
Next0:
	lodsb
	cmp	al,20h
	jz	Next0
	dec	si
	mov	dx,si
	mov	di,si
	mov	cx,0Fh
	mov	al,0Dh
	repnz	scasb
	dec	di
	mov	byte ptr ds:[di],0	
	mov	ax,3D00h
	int	21h
	jnc	Next1
	lea	dx,BadFn
	jmp	Exit
Next1:
	mov	bx,ax
	mov	dx,100h
	mov	si,dx
	mov	cx,15
	mov	ah,3Fh
	int	21h
	lea	di,FMask
	mov	cx,offset About-offset FMask
	rep	cmpsb
	jcxz	Next2
	lea	dx,NotCut
	jmp	Exit
Next2:
	lea	dx,OK
	mov	ah,9
	int	21h
	mov	bx,10b
	mov	si,108h
	lodsw
	lea	dx,MouseStr
	call	Print
	mov	cx,ax
	and	cx,bx
	cmp	cx,bx
	jz	Mouse
	call	WriteOff
	jmp	short AMouse
Mouse:
	call	WriteOn
AMouse:
	shr	bx,1
	lea	dx,AdvStr
	call	Print
	mov	cx,ax
	and	cx,bx
	cmp	cx,bx
	jz	Adv
	call	WriteOff
	jmp	short AAdv
Adv:
	call	WriteOn
AAdv:
	lea	dx,ScrModMsg
	mov	ah,9
	int	21h
	lodsb
	call	Hex

	lea	dx,FirstBMsg
	mov	ah,9
	int	21h
	lodsb
	add	al,3
	call	Hex
	
	jmp	ToLine		
Hex:
	mov	dl,al
	mov	cl,4
	shr	dl,cl
	call	MakeCh
	push	ax
	mov	ah,2
	int	21h
	pop	ax
	and	al,1111b
	mov	dl,al
	call	MakeCh
	mov	ah,2
	int	21h
	lea	dx,EMsg
	mov	ah,9
	int	21h
	ret

MakeCh:
	add	dl,'0'
	cmp	dl,':'
	jb	MakeChEx
	add	dl,7
MakeChEx:
	ret

Print:
	push	ax
	mov	ah,9
	int	21h
	pop	ax
	ret

RepSym	proc near
	mov	dl,al
	mov	ah,2
RepSymLp:
	int	21h
	loop	RepSymLp
	ret	
	 
RepSym endp

MyLine	proc near
	mov	al,'-'
	mov	cx,75
	call	RepSym
	lea	dx,CRLF
	mov	ah,9
	int	21h
	ret
CRLF	db	13,10,'$'
MyLine	endp

WriteOn:
	lea	dx,ON
Write:
	push	ax	
	mov	ah,9
	int	21h
	pop	ax
	ret

WriteOff:
	lea	dx,OFF
	jmp	short Write

Exit:
	mov	ah,9
	int	21h
ToLine:	call	MyLine
	int	20h

FMask	db	0E8h,0Ch,0,'$cut$'
About	db	7 dup('-'),' *** RS Graphics Utilities *** ',9 dup('-'),' Kishinev, RSsoftware ',6 dup('-'),10,13
	db	'CutInfo CUT-files Guide  Version 1.0  Copyright (C) 1992,93 by MasyutinMax~',10,13,'$'
Usage	db	13,10,'Usage:   CUTINFO <fname.ext>',13,10,'$'
BadFN	db	13,10,'File not found',13,10,'$'
NotCut	db	13,10,'This in not a CUT-file',13,10,'$'
OK	db	'Characteristics of this CUT-file:',13,10,'$'
ON	db	' - ON',10,13,'$'
OFF	db	' - OFF',10,13,'$'
MouseStr db	'  Hide mouse','$'
AdvStr	db	'  SetScreen ','$'
ScrModMsg db	'  Screen mode : $'
FirstBMsg db	'  Offset of the first byte of data area from the file',27h,'s first byte : $'
EMsg	db	'h',10,13,'$'
CSEG	ends
	end	Start