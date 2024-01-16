CODE	segment
	assume 	cs:CODE,ds:CODE,es:CODE
	org 100h
START:	

Pressed:
        jmp	INSTALL
int9_0:
        call    RealInt9
        db      0EAh
old9o_0 dw      0
old9s_0 dw      0
	
int9_1:
        call    RealInt9
        db      0EAh
old9o_1 dw      0
old9s_1 dw      0


RealInt9:
	cli
	pushf
        push    ax
	push	bx
	push	ds
	push	cs
	pop	ds

	lea	bx,pressed
	in	al,60h
	cmp	al,32	; "D"
	jnz	NotD
	cmp	byte ptr ds:[bx],1
	jnz	NotD
	cmp	byte ptr ds:[bx+2],1
	jnz	NotD

ComputerReset:
	db	0EAh
	dw	0FFF0h,0F000h

NotD:
	cmp	al,56	; Alt
	jnz	NotAlt
	mov	byte ptr ds:[bx+2],1
	jmp	short CL_EXIT

NotAlt:
	cmp	al,55	; PrtSrc
	jz	BREAK
	cmp	al,29	; CTRL
	jnz	CLEAR
	mov	byte ptr ds:[bx],1
	jmp	short CL_EXIT
BREAK:			
	cmp	byte ptr ds:[bx],1
	jnz	CL_EXIT
;
	mov	word ptr ds:[bx],100h
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr ds:[8*4]
	mov	word ptr cs:old08o,ax
	mov	ax,word ptr ds:[8*4+2]
	mov	word ptr cs:old08s,ax
	
	lea	ax,Int08
	mov	word ptr ds:[8*4],ax
	mov	word ptr ds:[8*4+2],cs
	jmp	short CL_EXIT

;
	
CLEAR:	
	mov	word ptr ds:[bx],0
	mov	byte ptr ds:[bx+2],0

CL_EXIT:
	pop	ds
	pop	bx
	pop     ax
	popf
        ret

FourPanel_WRITE_FILE:

	mov	word ptr cs:FourPanel_WORDS,cx
	mov	ax,0A000h
	mov	ds,ax

FourPanel_LOOP:
	push	ds
	push	cs
	pop	ds

	mov	ah,3Ch 		;	FourPanel begin;
	lea	dx,fname
	xor	cx,cx
	int	21h             ; Создаем файл
	mov	bx,ax
	mov	cx,offset FourPanel_LOADER_END-offset FourPanel_FBeg
	lea	dx,FourPanel_FBeg
	mov	ah,40h
	int	21h            ; Пишем в файл загрузчик
	pop	ds


        mov     dx,3CEh    ;  │
        mov     al,5       ;  │
        out     dx,al      ;  │ Установим режим чтения
        inc     dx         ;  │
        mov     al,0       ;  │
        out     dx,al      ;  │
        dec	dx         ;  │
        mov     al,4       ;  │ Установим нужную битовую карту
        out     dx,al      ;  │
        inc     dx         ;  │
        mov     al,cs:PANEL_NUM ;<───── Карта
        out     dx,al      ;  │

        mov     ah,40h
        mov     cx,word ptr cs:FourPanel_WORDS
        shl     cx,1
	cwd
	int	21h

       	lov	ah,3Eh
	int	21h		;	FourPanel end;

        cmp     cs:Cut_no,'3'
	jz      EXIT_FourPanel_LOOP
	inc	cs:Cut_no
	shl	cs:FourPanel_LOADER_PANEL_NUM,1
	inc	cs:PANEL_NUM
        jmp     short FourPanel_LOOP

EXIT_FourPanel_LOOP:
        jmp	EXIT_PROCESSING

SinglePanel_WRITE_FILE:
	mov	ah,3Ch 		;	begin
	lea	dx,fname
	xor	cx,cx
	int	21h
	mov	bx,ax
	mov	cx,offset SinglePanel_data-offset SinglePanel_FBeg
	lea	dx,SinglePanel_FBeg
	mov	ah,40h
	mov     word ptr ADDRESS,si
	mov	word ptr SinglePanel_WORDS,di
	int	21h
	shl	di,1
	mov	ax,si		
	mov	ds,ax
	mov	cx,di
	mov	ah,40h
	cwd
	int	21h
	mov	ah,3Eh
	int	21h		;	 end;
	jmp	EXIT_PROCESSING
SinglePanel_FBeg:
	cli	;│ Настроим 
	cld     ;│  флаги

	push	cs	;│				│  Настроим
	pop	ds	;│				│ сегментные
	db	0B8h	;│ Это команда mov ax,____	│  регистры
ADDRESS dw	0	;│ Это резерв для '____'	│   ES  DS
	mov	es,ax	;│				│

	db	0B9h	;│<── Это команда mov cx,____	│ Помещаем в CX
SinglePanel_WORDS dw	0	;│<── Это резерв для '____'	│  кол-во слов
	xor	di,di
	mov	si,offset SinglePanel_data-offset SinglePanel_Fbeg+100h
	rep	movsw
	sti
	int	20h	
SinglePanel_data:

FourPanel_FBeg:

        cli
	cld

	push	cs
	pop	ds

	mov	ax,0A000h
	mov	es,ax

        mov     dx,3CEh  ;  ─────────────────
        mov     al,5     ; │                 │
        out     dx,al    ; │ Установим режим │
        inc     dx       ; │     записи      │
        xor     al,al    ; │                 │
        out     dx,al    ;  ─────────────────

        mov     dx,3C4h
        mov     al,2
        out     dx,al
        inc     dx
	db	0B0h		;│ Это  ─  mov al,EGA_..._PANEL_NUM
FourPanel_LOADER_PANEL_NUM db 1	;│
        out     dx,al		;│ Установим цветовую плоскость
	
	xor	di,di
	mov	si,offset FourPanel_LOADER_END-offset FourPanel_FBeg+100h
	db	0B9h	;│<── Это команда mov cx,____	│ Помещаем в CX
FourPanel_WORDS dw	0	;│<── Это резерв для '____'	│  кол-во слов

	rep	movsw

	sti
	int	20h	
FourPanel_LOADER_END:


PROCESSING:
	pushf
	cmp	byte ptr cs:pressed+1,1
	mov	byte ptr cs:pressed+1,0
	jz	PROC_CONT

	push	ax
	push	bx
	push	cx
	push	es
	push	ds

	push	cs
	pop	ds

	xor	ax,ax
	mov	es,ax

	mov	bx,word ptr es:[9*4]
	mov	cx,word ptr es:[9*4+2]

	
	mov	ax,cs
	cmp	ax,cx

	jnz	SetNew9
	cmp	bx,offset Int9_0
	jnz	SetNew9

GoodBye_:
	pop	ds
	pop	es	
	pop	cx
	pop	bx
	pop	ax
	popf
	ret

SetNew9:
	cmp	bx,offset Int9_1
	jz	GoodBye_
	mov	word ptr ds:old9o_1,bx
	mov	word ptr ds:old9s_1,cx

	mov	word ptr es:[9*4],offset Int9_1
	mov	word ptr es:[9*4+2],ds

	jmp	GoodBye_

PROC_CONT:
	call	SetNormInt8
	popf

Real_PROCESSING:
	pushf
	cli
        push    ax
        push    bx
        push    cx
        push    dx
        push    ds
	 
        push    cs
        pop     ds
	
	mov	ah,15
	int	10h

	cmp	al,4			;CGA(4)
	jnz	NOT_CGA

	mov	si,0B800h
	mov	di,1FA0h		;Пpовеpено
	jmp	SinglePanel_WRITE_FILE

NOT_CGA:
	cmp	al,11h
	jnz	NOT_MCGA_MONO

	mov	si,0A000h
	mov	di,4B00h		;Пpовеpено
	jmp	SinglePanel_WRITE_FILE
	
NOT_MCGA_MONO:
        cmp     al,10h			;EGA(16) 640*350
        jnz     NOT_EGA_10h

        mov     cx,36B8h		;Пpовеpено
        jmp	FourPanel_WRITE_FILE

NOT_EGA_10h:
	cmp	al,13h			;MCGA(256)
	jnz	NOT_MCGA_256
	mov	si,0A000h
	mov	di,7D00h		;Пpовеpено
	jmp	SinglePanel_WRITE_FILE

NOT_MCGA_256:
	cmp	al,0Dh
	jnz	NOT_EGA_0Dh
        mov     cx,0FA0h
	jmp	FourPanel_WRITE_FILE


NOT_EGA_0Dh:
	cmp	al,12h
	jnz	Not_VgaHi
	mov	cx,4B00h		;Пpовеpено
	jmp	FourPanel_WRITE_FILE	


Not_VgaHi:

EXIT_PROCESSING:
	push	cs
	pop	ds
        mov	FourPanel_LOADER_PANEL_NUM,1
	mov     Cut_no,'0'
	mov     Panel_NUM,0
        pop     ds
        pop     dx
        pop     cx
        pop     bx
        pop     ax
	popf
	ret

int08:
	call	SetNormInt8
	push	ax
	push	bx
	push	si
	push	ds
	
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr cs:old08o
	mov	word ptr ds:[8*4],ax
	mov	ax,word ptr cs:old08s
	mov	word ptr ds:[8*4+2],ax

	mov	bx,sp

	mov	ds,word ptr ss:[bx+10]
	mov	si,word ptr ss:[bx+8]
	mov	al,byte ptr ss:[bx+13]
	mov	byte ptr cs:Flag,al		
	mov	byte ptr ss:[bx+13],0	
	
	mov	ax,word ptr ds:[si]
	mov	word ptr cs:LocTMP,ax
	mov	word ptr ds:[si],88CDh 		
	mov	word ptr cs:LocOff,si
	mov	word ptr cs:LocSeg,ds	
	
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr ds:[88h*4]
	mov	word ptr cs:old88o,ax
	mov	ax,word ptr ds:[88h*4+2]
	mov	word ptr cs:old88s,ax
	
	mov	word ptr ds:[88h*4],offset Int88
	mov	word ptr ds:[88h*4+2],cs

	pop	ds
	pop	si	
	pop	bx
	pop	ax
Exit08:
	db 	0EAh	
old08o	dw	0
old08s	dw	0
old88o	dw	0
old88s	dw	0
LocTMP	dw	0
LocOff	dw	0
LocSeg	dw	0
Flag	db	0

int13:
	call	PROCESSING
	db 	0EAh	
old13o	dw	0
old13s	dw	0

int16:

	pushf
	cmp	ax,7777h
	jnz	NOT_CHECKING
	cmp	cx,ax
	jnz	NOT_CHECKING	
	cmp	bx,ax
	jnz	NOT_CHECKING
	mov	al,26h
	popf	
	iret
NOT_CHECKING:
	popf
	call	PROCESSING
	db 	0EAh	
old16o	dw	0
old16s	dw	0

int21:
	call	PROCESSING
	db 	0EAh	
old21o	dw	0
old21s	dw	0


int28:

	call	PROCESSING
	db 	0EAh	
old28o	dw	0
old28s	dw	0

Int88:
	call	Real_PROCESSING

	push	ax
	push	bx
	push	ds

	mov	ax,word ptr cs:LocSeg
	mov	ds,ax
	mov	bx,word ptr cs:LocOff
	mov	ax,word ptr cs:LocTMP
	mov	word ptr ds:[bx],ax

	mov	bx,sp
	sub	word ptr ss:[bx+6],2
	mov	al,byte ptr cs:Flag
	mov	byte ptr ss:[bx+11],al	

	xor	ax,ax
	mov	ds,ax

	mov	ax,word ptr cs:old88o
	mov	word ptr ds:[88h*4],ax
	mov	ax,word ptr cs:old88s
	mov	word ptr ds:[88h*4+2],ax

	pop	ds
	pop	bx
	pop	ax	
	iret

SetNormInt8:
	push	ax
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr cs:old08o
	mov	word ptr ds:[8*4],ax
	mov	ax,word ptr cs:old08s
	mov	word ptr ds:[8*4+2],ax
	pop	ds
	pop	ax
	ret





fname	   db	'$cut$_'
Cut_no     db   '0'
Cont_fname db   '.com',0

PANEL_NUM       db 0

INSTALL:
	push	cs
	pop	ds
	lea	dx,MSG0
	mov	ah,9
	int	21h
	mov	ax,7777h
	mov	cx,ax
	mov	bx,ax
	int	16h
	cmp	al,26h
	jnz	INST
	lea	dx,MSG1
	mov	ah,9
	int	21h
	int	20h

INST:
	mov	es,word ptr ds:[2Ch]
	mov	ah,49h
	int	21h

	mov	ax,3509h
	int	21h
	mov	old9o_0,BX
	mov	old9s_0,ES
	lea	dx,int9_0
	mov	ax,2509h
	int	21h

	mov	ax,3513h
	int	21h
	mov	old13o,BX
	mov	old13s,ES
	lea	dx,int13
	mov	ax,2513h
	int	21h

	mov	ax,3516h
	int	21h
	mov	old16o,BX
	mov	old16s,ES
	lea	dx,int16
	mov	ax,2516h
	int	21h

	mov	ax,3521h
	int	21h
	mov	old21o,BX
	mov	old21s,ES
	lea	dx,int21
	mov	ax,2521h
	int	21h

	mov	ax,3528h
	int	21h
	mov	old28o,BX
	mov	old28s,ES
	lea	dx,int28
	mov	ax,2528h
	int	21h
	
	lea	dx,MSG2
	mov	ah,9
	int	21h

	lea	dx,INSTALL
	int	27h

MSG2	db	'Installed.',10,13
	db	'Screen Cut          ─ ON. Hot key <CTRL>-<PrtScr>',10,13
	db	'Advanced Screen Cut ─ ON. Hot key <CTRL>-<Alt>-<PrtScr>',10,13
	db	'Advanced Restart    ─ ON. Hot key <CTRL>-<Alt>-"D"',10,13,'$'
MSG0	db	10,13,'CTRL. Version 1.0',10,13
	db	'Copyright (C) 1992 by MasyutinMax~',10,13,10,13,'$'
MSG1	db	'This program was allready installed',10,13,'$'
CODE	ends
	end	START

