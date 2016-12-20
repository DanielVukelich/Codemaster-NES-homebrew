;/  RAM data

;/  Zero Page Stuff

.enum $0000

nametableaddr_low: .dsb 1
nametableaddr_high: .dsb 1

cEOR_low: .dsb 1
cEOR_high: .dsb 1

vCodePegs: .dsb 4
vCodeVals: .dsb 4
vTCodeVals: .dsb 4
vGuessResults: .dsb 4

vMiscZP: .dsb 1

;\

;/	RAM Variables
.org $0400

P1Flags: .dsb 8
P1: .dsb 8
P2Flags: .dsb 8
P2: .dsb 8

vCodeSelCounter: .dsb 1
vPressStartOff: .dsb 1

vApplicationsLeft: .dsb 1
vGuessAppTemp: .dsb 1

vMultiplyBy: .dsb 1
vTempMult: .dsb 1

vIsLoseLoaded: .dsb 1

ppuaddr_low: .dsb 1
ppuaddr_high: .dsb 1
tileswitch_low: .dsb 1
tileswitch_high: .dsb 1
newtile: .dsb 1

vControllerRAMTemp: .dsb 1

vGameState: .dsb 1	;. 0 is Menu, 1 is game, 2 is Applying Guess, 3 is win, 4 is lose, 5 is 2p Code Selection, 6 is Difficulty Selection
vTwoPlayer: .dsb 1

vSeed: .dsb 1
vEOR: .dsb 1

vAudioState: .dsb 1

vArrowSelRow: .dsb 1
vArrowSelCol: .dsb 1
vArrowSelSide: .dsb 1

vUpdateCodeFlag: .dsb 1
vCodesToGen: .dsb 1

vWait: .dsb 1
vQuietWait: .dsb 2

horizval: .dsb 1
vertval: .dsb 1
overloopC: .dsb 1
increaseX: .dsb 1
increaseOAMADDR: .dsb 1

vAllowDupePeg: .dsb 1

.ende
;\

;/  Aliases
sprite = $0200
number_offset = #$1B  ;.  The tile that shows '1' is tile #$1B
;\

;\

;/  Initializations

.base $C000

RESET:	;/
	sei
	cld
-   lda $2002  ;. Wait for two Vblanks.  We can read them from  the $2002 register
	bpl -
-	lda $2002
	bpl -

	;. Now we clear the RAM
		lda #$00
		ldx #$00
@ramloop:
		sta $0000 , x
    	sta $0100 , x
		sta $0200 , x
		sta $0300 , x
		sta $0400 , x
		sta $0500 , x
		sta $0600 , x
		sta $0700 , x
		inx
		bne @ramloop

	;. Reset the stack pointer
	ldx #$FF
	txs

	jsr vblank_wait

	;. Disable all graphics
	lda #$00
	sta $2000
	sta $2001

	jsr initialize_vars
	jsr initialize_graphics
	jsr initialize_sound

	;. Set basic PPU registers.  Load background from $0000,
	;. sprites from $0000, and the name table from $2400.
	jsr vblank_wait
        lda #%10000001 ;. Bit 4 being sets the background to bank 2, 0 for bank 1
        sta $2000
        lda #%00011110 ;. Show the background & the sprites
        sta $2001

	cli

loop: jmp loop
;. Keep calm and wait for the NMI :)
;\

initialize_sound: 	;/
;. *TODO: Initialize sound
	lda #$00
	ldx #$00
	;.jsr $9F30
rts
;\

initialize_vars:	;/

	lda #$1d
	sta vEOR
	lda #<EOR_Vals
	sta cEOR_low
	lda #>EOR_Vals
	sta cEOR_high

	lda #$FF
	sta vApplicationsLeft

	lda #$0F
	sta $4015
	sta vAudioState

rts
;\

initialize_graphics:	;/
	jsr initialize_palette
	jsr initialize_sprites
	jsr initialize_nametables
	rts
;\

initialize_palette:	;/
	lda $2002 ;. Reset the latch
	lda #$3F
	sta $2006 ;. Set the palette ram, high byte first
	lda #$10
	sta $2006
	ldx #$00
-	lda palette,x
	sta $2007
	inx
	cpx #$20
	bne -
rts
;\

initialize_sprites:	;/

	;. Initialize the "Player Option" sprite

	lda #$9D ;. The 'Y' of the sprite
	sta sprite
	lda #$21 ;. The sprite's Tile Number
	sta sprite + 1
	lda #%00000000 ;. Palette 0
	sta sprite + 2
	lda #$58 ;. the 'X' of the sprite
	sta sprite + 3
rts
;\

initialize_nametables:	;/

	lda #<TwoP_Code_Select
	sta nametableaddr_low
	lda #>TwoP_Code_Select
	sta nametableaddr_high
	lda #$28
	sta ppuaddr_high
	lda #$00
	sta ppuaddr_low
	ldy #$00
	ldx #$04
	jsr load_nametable

	lda #<titlescreen
	sta nametableaddr_low
	lda #>titlescreen
	sta nametableaddr_high
	lda #$24
	sta ppuaddr_high
	lda #$00
	sta ppuaddr_low
	ldy #$00
	ldx #$04
	jsr load_nametable

rts
;\

;\

;/  Subroutines

;/ TODO List

;. *TODO: Implement Sound (Music?)

;\

vblank_wait:	;/

@wait:
	lda $2002
	bpl @wait
rts

;\

init_code_sel_sprites:	;/
	ldx #$00
	ldy #$58
@spriteloop:
	lda #$45
	sta sprite , x
	inx
	lda #$21
	sta sprite , x
	inx
	lda #$00
	sta sprite , x
	inx
	tya
	sta sprite , x
	clc
	adc #$18
	tay
	inx
	cpx #$10
	bne @spriteloop
rts
;\

update_code_sel_sprites: 	;/

	lda #$04
	sta vMultiplyBy
	tya
	jsr multiply
	clc
	adc #$02
	tax
	lda #$02
	sta sprite , x
	ldx #$02
	jsr play_beep

rts
;\

multiply:	;/

;/	Documentation
	;. Multiplies the A register by the value stored in vMultiplyBy
;\

	sta vTempMult
	lda #$00
@multlp:
	clc
	adc vTempMult
	dec vMultiplyBy
	bne @multlp

rts
;\

play_beep:	;/

;/	Documentation
;.	The value in the x Register determines the note.
;\
	ldy vAudioState

	lda #$01
	sta $4000
	lda #%01100111
	sta $4000

	cpx #$00
	beq @los
	cpx #$01
	beq @soso
	jmp @good
@los:
	lda #$c9
	jmp @play
@soso:
	lda #$a9
	jmp @play

@good:
	lda #$89
@play:
	sta $4002
	lda #%01101000
	STA $4003

	lda #$00
	sta $4000

	sty vAudioState
	sty $4000

rts
;\

update_arrows:	;/

	ldx vArrowSelCol
	lda arrow_sprite_X , x
	ldy vArrowSelSide
	cpy #$01
	bne @transfer
		clc
		adc #$80
@transfer:
	sta sprite + 3
	sta sprite + 7

	ldx vArrowSelRow
	lda arrow_sprite_Y , x
	sta sprite
	clc
	adc #$1B
	sta sprite + 4
rts
;\

load_nametable:	;/

;/ Documentation
;.This subroutine requires two things.  nametableaddr_high and nametableaddr_low must point to the nametable and attribute table. Also
;.ppuaddr_low and ppuaddr_high point to the ppu address to start at.
;.It will transfer 256(X) + (256 - Y) bytes into the ppu.

;.For safety, disable rendering before calling this subroutine by writing #$0 to $2001
;.You can reenable rendering once this has been called
;\

	lda ppuaddr_high
	sta $2006
	lda ppuaddr_low
	sta $2006
@tp:	lda (nametableaddr_low),y  	;.The ()'s let the code know that we mean an address, so
	sta $2007				 		;.it knows to look in the next byte to find the rest of the address
	iny						  		;.we are then offsetting that address by y bytes.  We have to increment
	bne @tp							;.the high byte of the address, because we can only offset by 255 bytes
	inc nametableaddr_high
	dex
	bne @tp

rts
;\

switch_tile:	;/

;/ documentation
;.This must be called when rendering is disabled, and after the majority of the nametable has
;.been written

;.To use this subroutine, first set ppuaddr_low and ppuaddr_high to the beginning nametable
;.address you want to modify ($2000, $2400, etc.).  The have tileswitch_low and tileswitch_high
;.be the low and high bytes of the tile offset you want to change.  (E.g: To change tile #85,
;.tileswitch_high is #$00 and tileswitch_low is #$55).  Then have newtile be the vale of what
;.you want this tile to be.
;\

	lda #$00	;. Disable Rendering
	sta $2001

	lda $2006
	lda ppuaddr_low
	clc
	adc tileswitch_low
	sta ppuaddr_low
	lda ppuaddr_high
	adc tileswitch_high
	sta $2006
	lda ppuaddr_low
	sta $2006
	lda newtile
	sta $2007

	lda #%00011110	;. Re-enable Rendering
	sta $2001
rts
;\

update_code:	;/

	;/ Documentation
	;. Pass $0 to P1 + 4dateCodeFlag to cycle down through pegs, and $1 to cycle up.
	;. Call this to update the applicable guess peg based off of the values in
	;. vArrowSel etc.
	;\

	jsr vblank_wait

	ldx vArrowSelCol
	ldy vCodePegs , x
	cpy #$FF
	beq @firsttime
		lda vUpdateCodeFlag
		cmp #$00
		beq @decrement
			iny
			iny
@decrement:
		dey
		cpy #$FF
		beq @firstDec
			cpy #$08
			beq @firstInc
				jmp @endcrement

	@firsttime:
	ldy vUpdateCodeFlag
	cpy #$00
	beq @firstDec
		jmp @firstInc
@firstDec:
	ldy #$07
	jmp @endcrement
@firstInc:
	ldy #$00
@endcrement:
	sty vCodePegs , x

	lda #$80
	cpy #$00
		beq @dnupdtlp
@updtcdlp:
	clc
	adc #$6
	dey
	bne @updtcdlp
@dnupdtlp:
	sta newtile

	ldy vArrowSelRow
	iny
	lda #$01
	sta tileswitch_low
	lda #$00
	sta tileswitch_high
@rowsellp:
	lda tileswitch_low
	clc
	adc #$80
	sta tileswitch_low
	lda tileswitch_high
	adc #$00
	sta tileswitch_high
	dey
	bne @rowsellp

	cpx #$00
	beq @sidesel
@colsellp:
	lda tileswitch_low
	clc
	adc #$03
	sta tileswitch_low
	lda tileswitch_high
	adc #$00
	sta tileswitch_high
	dex
	bne @colsellp

@sidesel:
	lda vArrowSelSide
	cmp #$01
	bne @thefinalcall
		lda tileswitch_low
		clc
		adc #$10
		sta tileswitch_low
		lda tileswitch_high
		adc #$00
		sta tileswitch_high

@thefinalcall
	lda #$00	;. Disable Rendering
	sta $2001

	lda $2006
	sta $0500
	lda tileswitch_high
	clc
	adc #$28
	sta $2006
	sta tileswitch_high
	lda tileswitch_low
	sta $2006
	ldy newtile
	sty $2007
	iny
	sty $2007
	iny
	sty $2007
	iny

	clc
	adc #$20
	sta tileswitch_low
	lda tileswitch_high
	adc #$00
	sta $2006
	lda tileswitch_low
	sta $2006
	sty $2007
	iny
	sty $2007
	iny
	sty $2007
	iny


	lda #$28
	sta $2006
	sta ppuaddr_high
	lda #$00
	sta $2006
	sta ppuaddr_low

	lda #%00011110	;. Re-enable Rendering
	sta $2001
rts

;\

prng:	;/

;/ documentation
;.An 8-Bit PRNG.  Requires a seed and an EOR value (from the table found later in this code).
;.vSeed (or the A register) is the last returned number from this subroutine
;\

	lda vSeed
        beq @doEor
         asl
         beq @noEor ;. If the input was $80, skip the EOR
         bcc @noEor
@doEor:    eor vEOR
@noEor:  sta vSeed
rts
;\

set_code:	;/

;/	Documentation
;.	This sets the code for the round.  Put anything #$00  in vAllowDupePeg to force the generation of 4 unique pegs.
;.	Write #$00 - #$04 to vCodesToGen to generate that many codes (I don't see why you would want to generate less
;.  than #$04 though.
;\

	ldy vCodesToGen
	beq @eosc

	jsr prng

	lsr
	lsr
	lsr	;. We just want the high 3 bits
	lsr
	lsr

	ldx vAllowDupePeg
	bne @storeIt	;. Break if we don't care about duplicate pegs in the code

	ldx vCodesToGen
	cpx #$04
	beq @storeIt

@dupeloop:
	inx
	cmp vCodeVals - 1,x
	beq set_code
	cpx #$04
	bne @dupeloop

	@storeIt:
	sta vCodeVals - 1,y
	dec vCodesToGen

	jmp set_code

@eosc:
rts
;\

apply_guess:	;/


	lda vCodeVals
	sta vTCodeVals
	lda vCodeVals + 1
	sta vTCodeVals + 1
	lda vCodeVals + 2
	sta vTCodeVals + 2
	lda vCodeVals + 3
	sta vTCodeVals + 3

	LDA #$00
	STA vGuessResults
	STA vGuessResults + 1
	STA vGuessResults + 2
	STA vGuessResults + 3

	ldx #$00
	ldy #$03
@gslp:
	lda vCodePegs , y
	cmp vTCodeVals , y
	beq @gg
	jmp @ng
@gg:
	lda #$02
	sta vGuessResults , x
	lda #$FF
	sta vTCodeVals , y
	lda #$FE
	sta vCodePegs , y
	inx
@ng:
	dey
	cpy #$FF
	bne @gslp

	ldy #$FF

	lda vTCodeVals
	cmp vCodePegs + 1
	bne @nsv1
	jmp @sv1
@nsv1:
	lda vTCodeVals
	cmp vCodePegs + 2
	bne @nsv2
	jmp @sv2
@nsv2:
	lda vTCodeVals
	cmp vCodePegs + 3
	bne @nsv3
	jmp @sv3
@nsv3:
	lda vTCodeVals + 1
	cmp vCodePegs + 2
	bne @nsv4
	jmp @sv4
@nsv4:
	lda vTCodeVals + 1
	cmp vCodePegs + 3
	bne @nsv5
	jmp @sv5
@nsv5:
	lda vTCodeVals + 2
	cmp vCodePegs + 3
	bne @nsv6
	jmp @sv6
@nsv6:
	lda vTCodeVals + 1
	cmp vCodePegs
	bne @nsv7
	jmp @sv7
@nsv7:
	lda vTCodeVals + 2
	cmp vCodePegs
	bne @nsv8
	jmp @sv8
@nsv8:
	lda vTCodeVals + 3
	cmp vCodePegs
	bne @nsv9
	jmp @sv9
@nsv9:
	lda vTCodeVals + 3
	cmp vCodePegs + 1
	bne @nsv10
	jmp @sv10
@nsv10:
	lda vTCodeVals + 2
	cmp vCodePegs + 1
	bne @nsv11
	jmp @sv11
@nsv11:
	lda vTCodeVals + 3
	cmp vCodePegs + 2
	bne @continuemuthafucka
	jmp @sv12
@continuemuthafucka
	jmp @nsv12

@sv1:
	sty vTCodeVals
	dey
	sty vCodePegs + 1
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv1
@sv2:
	sty vTCodeVals
	dey
	sty vCodePegs + 2
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv2
@sv3:
	sty vTCodeVals
	dey
	sty vCodePegs + 3
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv3
@sv4:
	sty vTCodeVals + 1
	dey
	sty vCodePegs + 2
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv4
@sv5:
	sty vTCodeVals + 1
	dey
	sty vCodePegs + 3
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv5
@sv6:
	sty vTCodeVals + 2
	dey
	sty vCodePegs + 3
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv6
@sv7:
	sty vTCodeVals + 1
	dey
	sty vCodePegs + 0
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv7
@sv8:
	sty vTCodeVals + 2
	dey
	sty vCodePegs
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv8
@sv9:
	sty vTCodeVals + 3
	dey
	sty vCodePegs
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv9
@sv10:
	sty vTCodeVals + 3
	dey
	sty vCodePegs + 1
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv10
@sv11:
	sty vTCodeVals + 2
	dey
	sty vCodePegs + 1
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv11
@sv12:
	sty vTCodeVals + 3
	dey
	sty vCodePegs + 2
	iny
	lda #$01
	sta vGuessResults , x
	inx
	jmp @nsv12

@nsv12:
	jsr reset_guess
	lda #$02
	sta vGameState

rts

;\

load_game_sprites:	;/

;/	Documentation
	;. Call this subroutine whenever you want to load the sprites required for the
	;. game.  It has no parameters.
;\
	;/	Load the arrow sprites!
	lda #$14
	sta sprite
	lda #$22	;. Up arrow
	sta sprite + 1
	lda #%00000011 ;. Palette 4
	sta sprite + 2
	lda #$08
	sta sprite + 3
	lda #$2F
	sta sprite + 4
	lda #$22	;. Up arrow
	sta sprite + 5
	lda #%10000011 ;. Palette 4, Flip vertically
	sta sprite + 6
	lda #$08
	sta sprite + 7
	ldy #$08
	lda #$26
;\

	ldx #$2
	stx overloopC
	ldx #$00
	stx increaseOAMADDR
	stx increaseX

;/The one loop to rule the sprites

overloop:

	lda #$1D
	sta vertval
	lda #$68
	clc
	adc increaseX
	sta horizval
	lda #$8
	adc increaseOAMADDR
	tay
	ldx #$05

@tmploop:	;/
	lda vertval
	sta sprite,y
	iny
	lda #$21
	sta sprite,y
	iny
	lda #%00000011
	sta sprite,y
	iny
	lda horizval
	sta sprite,y
	iny
	lda vertval
	clc
	adc #$20
	sta vertval
	tya
	clc
	adc #$0C
	tay
	dex
	bne @tmploop

	lda #$1D
	sta vertval
	lda #$70
	clc
	adc increaseX
	sta horizval
	lda #$0C
	adc increaseOAMADDR
	tay
	ldx #$05

;\
@tmploop2:	;/
	lda vertval
	sta sprite,y
	iny
	lda #$21
	sta sprite,y
	iny
	lda #%00000011
	sta sprite,y
	iny
	lda horizval
	sta sprite,y
	iny
	lda vertval
	clc
	adc #$20
	sta vertval
	tya
	clc
	adc #$0C
	tay
	dex
	bne @tmploop2

	lda #$25
	sta vertval
	lda #$68
	clc
	adc increaseX
	sta horizval
	lda #$10
	adc increaseOAMADDR
	tay
	ldx #$05

;\
@tmploop3:	;/
	lda vertval
	sta sprite,y
	iny
	lda #$21
	sta sprite,y
	iny
	lda #%00000011
	sta sprite,y
	iny
	lda horizval
	sta sprite,y
	iny
	lda vertval
	clc
	adc #$20
	sta vertval
	tya
	clc
	adc #$0C
	tay
	dex
	bne @tmploop3

	lda #$25
	sta vertval
	lda #$70
	clc
	adc increaseX
	sta horizval
	lda #$14
	adc increaseOAMADDR
	tay
	ldx #$05

;\
@tmploop4:	;/
	lda vertval
	sta sprite,y
	iny
	lda #$21
	sta sprite,y
	iny
	lda #%00000011
	sta sprite,y
	iny
	lda horizval
	sta sprite,y
	iny
	lda vertval
	clc
	adc #$20
	sta vertval
	tya
	clc
	adc #$0C
	tay
	dex
	bne @tmploop4
;\

ldx overloopC
dex
beq @eof
stx overloopC
lda #$80
sta increaseX
lda #$50
sta increaseOAMADDR
jmp overloop
@eof:
;\

rts

;\

reset_guess:	;/
;. Set our guess pegs to #$FF so that we know they are blank
	lda #$FF
	sta vCodePegs
	sta vCodePegs + 1
	sta vCodePegs + 2
	sta vCodePegs + 3
rts
;\

flash_message:	;/
	lda #$00	;. Disable Rendering
	sta $2001

	ldx #$00
	lda #$26
	sta $2006
	lda #$6A
	sta $2006
	lda vPressStartOff
	bne @turniton


	lda #$00
	ldy #$01
@displayloop1:
	sta $2007
	inx
	cpx #$0C
	bne @displayloop1
	jmp @endflash

@turniton:
	ldy #$00
@displayloop2:
	lda press_start , x
	sta $2007
	inx
	cpx #$0C
	bne @displayloop2

@endflash:
	sty vPressStartOff
	lda #$20
	sta vQuietWait
	lda #$24
	sta $2006
	lda #$00
	sta $2006
	lda #%00011110 ;. Reenable rendering
    sta $2001
rts
;\

two_player_reset:	;/
	lda #$05
	sta vGameState
	ldx #$00
	txa
	@twoPRAMloop:
		sta $0000 , x
		sta $0200 , x
		inx
		bne @twoPRAMloop

	lda #$00	;. Disable Rendering
	sta $2000
	sta $2001
	sta vIsLoseLoaded

	lda #<TwoP_Code_Select
	sta nametableaddr_low
	lda #>TwoP_Code_Select
	sta nametableaddr_high
	lda #$28
	sta ppuaddr_high
	lda #$00
	sta ppuaddr_low
	ldy #$00
	ldx #$04
	jsr load_nametable
	jsr init_code_sel_sprites

	lda #%10010010 ;. Bit 4 being sets the background to bank 2, 0 for bank 1
	sta $2000
	lda #%00011110 ;. Show the background & the sprites
	sta $2001

rts
;\

;\

;/  Game Engine

NMI:	;/

	jsr update_sprites
	jsr handle_controllers
	jsr handle_gamestate

IRQ: rti
;\

handle_controllers:	;/

	lda #$01
	sta $4016 ;. Save the controller 1 state in the shift register
	lda #$00
	sta $4016 ;. Save the controller 2 state in the shift register

	;/ Player One
	ldy #$00
@P1Lp
	lda $4016
	and #$01
	tax
	sta vMiscZP
	lda P1Flags , y
	eor #$01
	and vMiscZP
	sta P1 , y
	txa
	sta P1Flags , y
	iny
	cpy #$08
	bne @P1Lp
	;\

	;/ Player Two
	ldy #$00
@P2Lp
	lda $4017
	and #$01
	tax
	sta vMiscZP
	lda P2Flags , y
	eor #$01
	and vMiscZP
	sta P2 , y
	txa
	sta P2Flags , y
	iny
	cpy #$08
	bne @P2Lp
	;\

rts
;\

update_sprites:	;/
	lda #<sprite ;.lda #$00
	sta $2003
	lda #>sprite
	sta $4014
rts
;\

handle_gamestate:	;/

	lda vWait
	bne @decw
	lda vGameState
	CMP #$00
	bne @continue
	jmp isMain
@decw:
	dec vWait
	jmp endInput
@continue:
	cmp #$01
	bne @cont2
	jmp isGame
@cont2:
	cmp #$02
	bne @cont3
	jmp isApplyingGuess
@cont3:
	cmp #$03
	bne @cont4
	jmp isWinner
@cont4:
	cmp #$04
	bne @cont5
	jmp isLoser
@cont5:
	cmp #$05
	bne @cont6
	jmp isCodeSel
@cont6:
	cmp #$06
	bne endInput
	jmp isSelDifficulty
endInput: rts

;\

isWinner:	;/
	lda vWait
	bne @decrease
		lda vTwoPlayer
		bne @twop
		lda #$01
		sta vGameState
		lda #$03
		ldx #$0a
	@twoPRAMloop:
		sta sprite , x
		inx
		inx
		inx
		inx
		cpx #$A6
		bne @twoPRAMloop
			jsr load_gameScreen_1
			jmp @endSub
@twop:
	jsr two_player_reset
	jmp @endSub
@decrease:
	dec vWait
@endSub:
jmp endInput
;\

isSelDifficulty:	;/

	ldx P1 + 2
	beq @readSt
	ldx vAllowDupePeg
	beq @toggleDupeOn
		dec vAllowDupePeg
		lda #$6D
		sta sprite
		jmp @kentuckyDoNothing

@toggleDupeOn:
	inc vAllowDupePeg
	lda #$7D
	sta sprite
	jmp @kentuckyDoNothing

@readSt:
	ldx P1 + 3
	beq @kentuckyDoNothing
	lda #$01
	sta vGameState
	jsr load_gameScreen_1

@kentuckyDoNothing:
jmp endInput
;\

isApplyingGuess:	;/

	ldy vApplicationsLeft
	cpy #$FF
	bne @cont
	ldy #$03
@cont:
	ldx #$04
	stx vMultiplyBy
	tya
	jsr multiply
	sta vGuessAppTemp
	ldx #$10
	stx vMultiplyBy
	lda vArrowSelRow
	jsr multiply
	clc
	adc vGuessAppTemp
	ldx vArrowSelSide
	beq @cont2
		clc
		adc #$50
@cont2
	tax
	lda vGuessResults,y
	sta $20a , x
	sta vGuessAppTemp
	dey
	sty vApplicationsLeft
	cpy #$FF
	bne @done

	lda vGuessResults + 3;.  Have you won?
	cmp #$02
	bne @nowin
		lda #$03
		sta vGameState
		jmp @done		;. You Win!

@nowin:
	lda #$00
	sta vArrowSelCol
	ldx vArrowSelRow
	inx
	lda #$01
	sta vGameState
	cpx #$05
	bne @fosho
	inc vArrowSelSide
	ldx vArrowSelSide
	cpx #$02
	bne @nolose
		lda #$04
		sta vGameState
		jmp @done

@nolose
	ldx #$00

@fosho:
	stx vArrowSelRow

@done:
	lda #$40
	sta vWait

	ldx vGuessAppTemp
	jsr play_beep

jmp endInput
;\

isLoser:	;/
	lda vIsLoseLoaded
	bne @readSt
		jsr load_lose_screen
		inc vIsLoseLoaded
@readSt:	;/
	lda P1 + 3
	beq @endRead
		lda vTwoPlayer
		bne @resetTwoP
		lda #$00
		sta vGameState
	;/ Clear the sprites and misc RAM
				lda #$00
				ldx #$00
		@ramloop:
				sta $0000 , x
				sta $0200 , x
				sta $0400 , x
				inx
				bne @ramloop
	;\

			lda #$01
			sta P1Flags + 3

			lda #$00	;. Disable Rendering
			sta $2000
			sta $2001

			jsr initialize_sound
			jsr initialize_vars
			jsr initialize_graphics

			lda #%10000001 ;. Bit 4 being sets the background to bank 2, 0 for bank 1
			sta $2000
			lda #%00011110 ;. Show the background & the sprites
			sta $2001
;\
@endRead:
	ldy vQuietWait
	bne @dontflash
	jsr flash_message
	jmp @endin
@dontflash:
	dey
	sty vQuietWait
	jmp @endin

@resetTwoP:
	jsr two_player_reset

@endin:
jmp endInput
;\

isGame:	;/

	;. Read the controller
@readA:	;/


	lda P1 + 0
	beq @readSt

	;. Either A or start will submit the code guess
		jsr @attemptSubmit

;\
@readSt:	;/
	lda P1 + 3
	beq @readUp

	@attemptSubmit:
		lda vCodePegs
		cmp #$FF
		beq @readUp
		lda vCodePegs + 1
		cmp #$FF
		beq @readUp
		lda vCodePegs + 2
		cmp #$FF
		beq @readUp
		lda vCodePegs + 3
		cmp #$FF
		beq @readUp
		jsr apply_guess
;\
@readUp:	;/
	lda P1 + 4
	beq @readDn
		lda #$01
		sta vUpdateCodeFlag
		jsr update_code
;\
@readDn:	;/
	lda P1 + 5
	beq @readLf
		lda #$00
		sta vUpdateCodeFlag
		jsr update_code
;\
@readLf:	;/
	lda P1 + 6
	beq @readRt
			ldx vArrowSelCol
			dex
			bpl @nvm
			ldx #$03

	@nvm:	stx vArrowSelCol
;\
@readRt:	;/
	lda P1 + 7
	beq @eol
			ldx vArrowSelCol
			inx
			cpx #$04
			bne @brb
				ldx #$00

	@brb:	stx vArrowSelCol
;\
@eol:
jsr update_arrows
jmp endInput
;\

isCodeSel: 	;/

	ldy vCodeSelCounter
	cpy #$04
	bne @checkInput
		ldy vQuietWait
		beq @firstime
			dec vQuietWait
			ldy vQuietWait
			beq @lastime
			jmp @endfosho
@firstime:
		ldy #$18
		sty vQuietWait
		jmp @endfosho
@lastime:
		ldy #$00
		sty vCodeSelCounter
		iny
		sty vGameState
		jsr load_gameScreen_1
		jmp @endfosho

@checkInput:
	ldx #$00
	lda P2Flags + 4
	bne @checkAB
	inx
	lda P2Flags + 7
	bne @checkAB
	inx
	lda P2Flags + 5
	bne @checkAB
	inx
	lda P2Flags + 6
	bne @checkAB
	jmp @checkNew

@checkAB:
	txa
	ldx P2 + 1
	beq @noBnew
	ora #%00000100
	jmp @storeIt
@noBnew:
	ldx P2
	beq @checkNew
@storeIt:
	sta vCodeVals , y
	jsr update_code_sel_sprites
	inc vCodeSelCounter
	jmp @endfosho

@checkNew:
	ldx #$00
	lda P2 + 4
	bne @checkABold
	inx
	lda P2 + 7
	bne @checkABold
	inx
	lda P2 + 5
	bne @checkABold
	inx
	lda P2 + 6
	bne @checkABold
	jmp @endfosho
@checkABold:
	txa
	ldx P2Flags + 1
	beq @noB
	ora #%00000100
	jmp @storeIt
@noB:
	ldx P2Flags
	beq @endfosho
	jmp @storeIt

@endfosho:
jmp endInput
;\

isMain:		;/
	;.This code only runs when we are on the main screen

	ldy vSeed 	;.Since we are on the main screen, we might as well start setting our PRNG's seed
	iny
	sty vSeed

;/	Read Select
	lda P1 + 2
	beq @seldon
		lda vTwoPlayer
		bne @twoP
			lda #$A5
			jmp @selflgdn
		@twoP:
		lda #$9D
		@selflgdn:
			sta sprite
		lda #$01
		EOR vTwoPlayer
		sta vTwoPlayer
;\
;/	Read Start
@seldon:
	lda P1 + 3
	beq @eol
		jsr exitTitle
		lda #$28
		sta $2006
		lda #$00
		sta $2006
;\
@eol:
jmp endInput
;\

exitTitle:	;/
	lda #$01
	sta vGameState
	lda vTwoPlayer
	cmp #$00
	bne @load_2p_intro
		lda #$06
		sta vGameState
		jsr load_difficulty_selection_screen
		;/ Initialize the PRNG
		jsr prng
		lsr
		lsr
		lsr
		lsr
		tay
		lda (cEOR_low),y
		sta vEOR
		;\
		jmp @exitSub
	@load_2p_intro:
		jsr load_2p_Intro_Screen
@exitSub:

	lda $2002 ;. Reset our address latch

rts
;\

load_difficulty_selection_screen:	;/


	lda #<select_difficulty
	sta nametableaddr_low
	lda #>select_difficulty
	sta nametableaddr_high

	lda #$28
	sta ppuaddr_high
	lda #$00
	sta ppuaddr_low
	sta $2001
	sta vAllowDupePeg

	ldx #$04
	ldy #$00
	jsr load_nametable

	jsr vblank_wait
	lda #%00011110 ;. Reenable rendering
    sta $2001

	lda #$6D
	sta sprite
	lda #$60
	sta sprite + 3

rts
;\

load_gameScreen_1:	;/

	jsr vblank_wait

	lda #$00 ;. Disable rendering
	sta $2001

	sta vArrowSelCol
	sta vArrowSelRow
	sta vArrowSelSide

	ldx vTwoPlayer	;.  If we have two players, the code is set, so don't generate one
	bne @doneprng

	lda #$04
	sta vCodesToGen	;. Generate 4 pegs
	jsr set_code	;. Make it so!

@doneprng:

	jsr reset_guess

	lda #<gamescreen_1
	sta nametableaddr_low
	lda #>gamescreen_1
	sta nametableaddr_high
	lda #$28
	sta ppuaddr_high
	lda #$00
	sta ppuaddr_low

	ldy #$00
	ldx #$04
	jsr load_nametable

	jsr load_game_sprites
	jsr vblank_wait
	lda #%00011110 ;. Reenable rendering
    sta $2001

	lda #%10010010 ;. Bit 4 being 1 sets the background to bank 2, Base nametable at $2800 (Mirrored @ $3200)
    sta $2000
rts
;\

load_2p_Intro_Screen:	;/

	jsr vblank_wait
	jsr init_code_sel_sprites

	lda #$05
	sta vGameState

	lda #$00
	sta vMiscZP

	lda #%10010010 ;. Bit 4 being 1 sets the background to bank 2, Base nametable at $2800 (Mirrored @ $3200)
    sta $2000

rts
;\

load_lose_screen:	;/

	jsr vblank_wait

	lda #$00	;. Disable Rendering
	sta $2001

	ldx #$00	;. Remove sprites
@ramloop:
	sta $0200 , x
	inx
	bne @ramloop

	lda #<game_over
	sta nametableaddr_low
	lda #>game_over
	sta nametableaddr_high
	lda #$00
	sta ppuaddr_low
	lda #$24
	sta ppuaddr_high
	ldy #$00
	ldx #$04

	jsr load_nametable

	;. Display what the code was
	ldx #$06
	stx vMultiplyBy
	lda vCodeVals
	jsr multiply
	clc
	adc #$80
	sta vCodeVals
	lda vCodeVals + 1
	stx vMultiplyBy
	jsr multiply
	clc
	adc #$80
	sta vCodeVals + 1
	lda vCodeVals + 2
	stx vMultiplyBy
	jsr multiply
	clc
	adc #$80
	sta vCodeVals + 2
	lda vCodeVals + 3
	stx vMultiplyBy
	jsr multiply
	clc
	adc #$80
	sta vCodeVals + 3		;. Now we have our tile offsets calculated

	lda #$25
	sta $2006
	lda #$87
	sta $2006

	ldx #$00
@outcodeloop:
	ldy #$00
@codeloop:
	lda vCodeVals , y
	sta $2007
	clc
	adc #$01
	sta $2007
	clc
	adc #$01
	sta $2007
	clc
	adc #$01
	sta vCodeVals , y
	lda #$00
	sta $2007
	sta $2007
	iny
	cpy #$04
	bne @codeloop

	lda #$25
	sta $2006
	lda #$A7
	sta $2006
	inx
	cpx #$02
	bne @outcodeloop

	lda ppuaddr_high
	sta $2006
	lda ppuaddr_low
	sta $2006

	lda #%10010001	;. Base Nametable at $2400, CHR bank 2
	sta $2000

	;.jsr vblank_wait

	lda #%00011110 ;. Reenable rendering
    sta $2001
rts
;\
;\

;/  ROM data

EOR_Vals:	;/
	.db $1d, $2b, $2d, $4d
	.db $5f, $63, $65, $69
	.db $71, $87, $8d, $a9
	.db $c3, $cf, $e7, $f5
	;\

arrow_sprite_X:	;/

	.db $10, $28, $40, $58

;\
arrow_sprite_Y:	;/

	.db $14, $34, $54, $74, $94

;\

palette:	;/

	.db $0F, $05, $10, $2D	;. Sprite palette
	.db $0F, $28, $10, $3D
	.db $0F, $29, $10, $00
	.db $0F, $2D, $3D, $09

	.db $0F, $05, $23, $09  ;. Background Palette
	.db $0F, $27, $20, $09
	.db $0F, $11, $26, $09
	.db $0F, $2D, $3D, $09
;\

;/ Music
 ;.pad $9F30
 ;.incbin "src/Music/music.nsf"
;\

;/ Samples
  ;.pad $C000
  ;.incbin "src/Music/samples.bin"
 ;\

;/ Nametables

titlescreen:
	.incbin "src/Nametable/Title_Screen.bin"


TwoP_Code_Select:
	.incbin "src/Nametable/2P_Code_Select.bin"

gamescreen_1:
	.incbin "src/Nametable/Game_Screen_1.bin"

game_over:
	.incbin "src/Nametable/Game_Over.bin"

select_difficulty:
	.incbin "src/Nametable/Select_Difficulty.bin"

	;\

;/ Misc Nametable Data

press_start:
	.db $30 , $31 , $28 , $32 , $32 , $00 , $00 , $32 , $33 , $24 , $31 , $33	;. Offset is nametable + $26A

;\

	.pad $FF60
	.db "Well, you found me.  Congratulations!  Was it worth it?  Because despite your violent"
	.db "behavior, the only thing you've managed to break so far, is my heart!"
	.dw NMI,RESET,IRQ

;\
