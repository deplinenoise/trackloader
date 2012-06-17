; vim: syntax=asm68k ts=8 sw=8

; track demo bootstrapper
;
; loaded into fastmem & called from bootblock

		include main.i
		include hardware/custom.i
		include hardware/dmabits.i
		include hardware/intbits.i

BCON0F_HIRES	equ	1<<15
BCON0F_BPU2	equ	1<<14
BCON0F_BPU1	equ	1<<13
BCON0F_BPU0	equ	1<<12
BCON0F_HAM	equ	1<<11
BCON0F_DPF	equ	1<<10
BCON0F_COLOR	equ	1<<9
BCON0F_GAUD	equ	1<<8
BCON0F_UHRES	equ	1<<7
BCON0F_SHRES	equ	1<<6
BCON0F_BYPASS	equ	1<<5
BCON0F_BPU3	equ	1<<4
BCON0F_LPEN	equ	1<<3
BCON0F_LACE	equ	1<<2
BCON0F_ERSY	equ	1<<1
BCON0F_ECSENA	equ	1<<0

CUSTOM		EQU	$dff000

BPLSIZE		EQU	320*256/8
IMGSIZE		EQU	5*BPLSIZE
PALSIZE		EQU	512

IMGSECTORS	EQU	(IMGSIZE+PALSIZE)/512

start:		lea.l	start(pc),a4
		move.l	a0,env-start(a4)
		move.l	a0,a3

		lea.l	CUSTOM,a5

		move.l	#IMGSIZE+PALSIZE,d0
		move.l	boot_AllocChip(a3),a2
		jsr	(a2)
		move.l	a0,bitmap-start(a4)

		lea.l	sync(pc),a1
		move.w	#3,d0
		move.w	#IMGSECTORS,d1
		move.l	boot_LoadFunc(a3),a2
		jsr	(a2)

.wait:		tst.w	(a1)
		beq.s	.wait
	
		move.l	#1024,d0
		move.l	boot_AllocChip(a3),a2
		jsr	(a2)
		move.l	a0,coplist-start(a4)

		move.w	#bplcon0,(a0)+	; 2
		move.w	#BCON0F_COLOR|BCON0F_BPU0|BCON0F_BPU2,(a0)+	; 2
		move.w	#ddfstrt,(a0)+
		move.w	#$38,(a0)+
		move.w	#ddfstop,(a0)+
		move.w	#$d0,(a0)+
		move.w	#diwstrt,(a0)+
		move.w	#$2c81,(a0)+
		move.w	#diwstop,(a0)+
		move.w	#$2cc1,(a0)+
		move.w	#bpl1mod,(a0)+
		move.w	#0,(a0)+
		move.w	#bpl2mod,(a0)+
		move.w	#0,(a0)+

		move.l	bitmap-start(a4),d0
		move.w	#bplpt,d2
		moveq	#4,d7
.bpl:		swap	d0
		move.w	d2,(a0)+					; 8 * 5 = 40
		move.w	d0,(a0)+
		addq.w	#2,d2
		swap	d0
		move.w	d2,(a0)+
		move.w	d0,(a0)+
		addq.w	#2,d2
		add.l	#BPLSIZE,d0
		dbra	d7,.bpl

		move.l	bitmap,a1
		add.l	#IMGSIZE,a1
		;move.w	#0,(a1)
		;move.w	#$fff,2(a1)
		move.w	#$180,d1		; color0
		move.w	#31,d7
.pal:		move.w	d1,(a0)+					; 32 * 4 = 128
		move.w	(a1)+,d0
		;eor.w	d7,d0
		move.w	d0,(a0)+
		addq.w	#2,d1
		dbra	d7,.pal

		move.l	#$fffffffe,(a0)+				; 4

		move.w	#DMAF_SETCLR|DMAF_COPPER|DMAF_RASTER,dmacon(a5)

		move.l	coplist,cop1lc(a5)
		;clr.w	copjmp1(a5)

.loop:		bra.s	.loop

; --

coplist:	dc.l	0
env:		dc.l	0
bitmap:		dc.l	0
sync:		dc.w	0
palette:	dc.l	0


