		include lvo/graphics_lib.i
		include graphics/text.i

DBGTXT	MACRO
	bra.s	.s\@
.t\@:	dc.b	\1,0
	align	2
.s\@:	movem.l	a0-a6/d0-d7,-(a7)
	lea.l	.t\@,a0
	move.l	bitmap_ptr(pc),a1
	jsr	debug_text(pc)
	movem.l	(a7)+,a0-a6/d0-d7
	ENDM

DBGFMT	MACRO
	bra.s	.s\@
.t\@:	dc.b	\1,0
	align	2
.s\@:	
	ifge \#-6
	fail to many args, extend the macro
	endif
	ifge \#-5
	move.l	\5,-(sp)
	endif
	ifge \#-4
	move.l	\4,-(sp)
	endif
	ifge \#-3
	move.l	\3,-(sp)
	endif
	ifge \#-2
	move.l	\2,-(sp)
	endif
	pea	.t\@
	jsr	debug_fmt(pc)
	lea.l	(\#)*4(sp),sp
	ENDM

DEBUGLINES	equ	3
DEBUGBITMAPSZ	equ	640/8*DEBUGLINES*8

topaz_font:	dc.l	0
graphicsbase:	dc.l	0
debug_bitmap:	dc.l	0
topaz_name:	dc.b 'topaz.font',0
graphics_libname: dc.b 'graphics.library',0

init:
		if DBGENABLE
		lea.l	graphics_libname(pc),a1
		move.l	#33,d0
		jsr	_LVOOpenLibrary(a6)
		lea.l	graphicsbase(pc),a0
		move.l	d0,(a0)

		move.l	#DEBUGBITMAPSZ,d0
		jsr	alloc_chip
		lea.l	debug_bitmap(pc),a1
		move.l	a0,(a1)
		move.l	a0,d0

		move.l	debug_bitmap(pc),d0
		lea.l	debug_bplpt(pc),a0
		move.w	d0,6(a0)
		swap	d0
		move.w	d0,2(a0)

		lea.l	-8(sp),sp
		move.l	sp,a0
		lea.l	topaz_name(pc),a1
		move.l	a1,(a0)	; name pointer
		move.l	#$00080001,4(a0)	; height=8, flags=FPF_ROMFONT
		move.l	graphicsbase(pc),a6
		jsr	_LVOOpenFont(a6)
		lea.l	8(sp),sp
		tst.l	d0
		beq	error
		lea.l	topaz_font(pc),a0
		move.l	d0,(a0)

		endif	; DBGENABLE


		if	DBGENABLE
debug_fmt:
		movem.l	d0-d7/a0-a6,-(sp) 	; 15 longwords = 60 bytes
		move.l	64(sp),a0		; format string ptr
		lea.l	68(sp),a1		; data stream
		lea.l	.putchr(pc),a2		; putchr proc

		lea.l	-256(sp),sp
		move.l	sp,a3

		move.l	$4.w,a6
		jsr	_LVORawDoFmt(a6)

		move.l	sp,a0
		move.l	debug_bitmap(pc),a1
		jsr	debug_text

		lea.l	256(sp),sp
		movem.l	(sp)+,d0-d7/a0-a6
		rts
.putchr:
		move.b	d0,(a3)+
		rts

debug_text:
		movem.l	d0-d7/a0-a6,-(a7)
		move.l	topaz_font(pc),a2
		move.l	tf_CharData(a2),a3
		clr.l	d0
		move.w	tf_Modulo(a2),d2
		ext.l	d2
.chr:
		move.b	(a0)+,d0
		tst.b	d0
		beq	.done

		sub.b	tf_LoChar(a2),d0
		cmp.b	#$7f,d0
		ble.s	.copy
		bra.s	.next

.copy:		move.l	d0,d1
		moveq.l	#0,d4
		move.w	tf_YSize(a2),d3
		subq.l	#1,d3
.line:		move.b (a3,d1.w),(a1,d4.w)
		add.l	d2,d1
		add.w	#640/8,d4
		dbra	d3,.line
.next:
		lea.l	1(a1),a1
		bra.s	.chr
.done:
		movem.l	(a7)+,d0-d7/a0-a6
		rts
		endif	; DBGENABLE

		if DBGENABLE
debug_coplist:
		dc.w	$f401,$ff00
		dc.w	ddfstrt,$003c
		dc.w	ddfstop,$00d4
		dc.w	diwstop,$2cc1
		dc.w	color+$00,$112
		dc.w	color+$02,$fff
debug_bplpt:
		dc.w	bplpt+0,$0	; patched
		dc.w	bplpt+2,$0	; patched
		dc.w	bplcon0,BCON0F_HIRES|BCON0F_BPU0|BCON0F_COLOR
		endif

