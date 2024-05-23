.org $080D
.segment "STARTUP"
.segment "INIT"
.segment "ONCE"
.segment "CODE"

   jmp start

; zero page variables
ZP = $30
LD = $22
AR = $25
XR = $26
YR = $27
SR = $28

; character variables
backspace = $14
escape = $1B

;KERNAL subroutines
CHRIN = $FFCF
CHROUT = $FFD2

.macro lds
    lda SR
    pha 
    plp 
.endmacro

.macro sts 
    php 
    pla 
    sta SR
.endmacro 

start:
    stz $23             ;zero out the value for setting the nibble skip
    stz $24             ;zero out the value for nibble skip
    lda #$0D            ;enter
    jsr CHROUT          ;new line
    ldx #0              ;zero out the index
input:  
    jsr CHRIN           ;input from keyboard
    cmp #$0D            ;check for enter
    bne cont            ;not enter
    jmp check           ;enter pressed, input has ended, time to check
cont:
    cmp #backspace      ;has backspace been inputed?
    bne next            ;no
    cpx #0              
    beq input           ;yes, but nothing had been written yet
    dex                 ;backspace, decrement the index
next: 
    cmp #$20            ;is it a valid character?
    bmi input           ;no, go back
    cmp #'z'+1          ;is it a letter, symbol or a number?
    bpl input           ;no, go back
    sta ZP,x            ;store the character          
    inx                 ;increment the index
    bra input           ;check for more characters
incy:                   ;some functions are here because 65c02 is able to branch backwards 
    cmp #'y'            
    bne err3            ;see later code comments to figure out how this code works it's simular
    lds 
    ldy YR
    iny 
    sty YR
    sts 
    jmp start 
inca:
    cmp #'c'
    bne incy 
    lds 
    lda AR
    inc 
    sta AR
    sts 
    jmp start
as:
    cmp #'l'
    bne err3
    lds
    lda AR
    asl 
    sta AR
    sts
    jmp start
ty:
    cmp #'a'
    bne err3
    lda YR
    sta AR
    jmp start
ta:
    cmp #'x'
    bne taty
    lda AR
    sta XR
    jmp start
err3:
    jmp err         ;jump to error handler
tx:
    cmp #'a'
    bne err3
    lda XR
    sta AR
    jmp start 
taty:
    cmp #'y'
    bne err3
    lda AR
    sta YR
    jmp start
i:
    cpy #'n'
    bne err3
    cmp #'x'
    bne inca
    lds 
    ldx XR
    inx 
    stx XR
    sts 
    jmp start
an:
    cpy #'d'
    beq ad
    cpy #'s'
    beq as
    cpy #'n'
    bne err3
    cmp #'d'
    bne err3
    ldx #$2D
    ldy #$29
    jmp load
ad:
    cmp #'c'
    bne err3
    ldx #$6d
    ldy #$69
    jmp load
t:
    cpy #'a'
    beq ta
    cpy #'x'
    beq tx
    cpy #'y'
    beq ty
    jmp err
e:
    cpy #'o'        
    bne err3
    cmp #'r'
    bne err3 
    ldx #$4D
    ldy #$49
    jmp load
o:
    cpy #'r'
    bne err3
    cmp #'a'
    bne err3
    ldx #$0D
    ldy #$09
    jmp load
check:              ;what has been stored in memory?
    stz ZP,x        ;terminate the string
    ldx ZP
    ldy ZP+1        ;load three first symbols into registers (1-x, 2-y, 3-a)
    lda ZP+2        ;every implimented instruction consists of three letters
    cpx #'o'        ;check for first letter
    beq o
    cpx #'e'
    beq e
    cpx #'i'
    beq i
    cpx #'l'
    beq l
    cpx #'j'
    beq j
    cpx #'a'
    beq an
    cpx #'s'
    beq s
    cpx #'c'
    beq c
    cpx #'r'
    beq r
    cpx #'t'
    beq t
    cpx #'q'
    bne err2        ;invalid symbol, give an error
    rts             ;q has been written, quit the program
c:                  ;c is the first letter, check if "clc" instruction has been written
    cpy #'l'
    bne err2        ;error out
    cmp #'c'
    bne err2
    lda SR          ;load the status register
    and #%11111110  ;and mask to clear the carry flag (last bit) and leave other flags unchanged
    sta SR          ;store the modified status register
    jmp start       ;go back to input
r:
    cpy #'o'        ;r is the first letter, check for "ror" and "rol" instructions
    bne err2        ;only implied address mode implemented rn
    cmp #'r'
    bne rotl        ;branch when this is not "ror", check for "rol"
    lds             ;load and apply status register (this is a macro)
    lda AR          ;load A register
    ror             ;rotate A register right
    sta AR          ;store A register for other instructions
    sts             ;store the status register (also a macro) 
    jmp start       ;go back for input
l:
    cpy #'d'        ;l is the first letter, check for "lda", "ldx", "ldy" and "lsr" instructions
    bne ls          ;branch when is "lsr" or invalid
    cmp #'a'        
    bne loadx       ;branch when not "lda"
    ldy #$A9        ;load the immediate address mode opcode for "lda" to Y
    ldx #$AD        ;load the absolute address mode opcode for "lda" to X
    jmp load        ;jump to assembler
j:
    cpy #'s'        ;j is the first letter, check for "jsr" instruction
    bne err2
    cmp #'r'
    bne err2
    ldx #$20        ;load "jsr" opcode to X
    ldy #0          ;no immediate opcodes for "jsr", 0 is the magic value for that
    jmp load        ;jump to assembler
err2:
    jmp err         ;jump to error handler
s:                  ;s is the first letter, check for "sec", "sbc", "sta", "stx" and "sty" instructions
    cpy #'e'        
    beq se          ;branch when its "se*"
    cpy #'b'
    beq sb          ;branch when its "sb*"
    cpy #'t'
    bne err2        ;not branch when its "st*"
    cmp #'x'  
    beq storx       ;branch when its "stx"
    cmp #'y'
    beq story       ;branch when its "sty"
    cmp #'z'
    beq st0         ;branch when its "stz"
    cmp #'a'
    bne err2        ;not branch when its "sta"
    ldx #$8D        ;load absolute opcode
    ldy #0          ;load magic value
    jmp load        ;jump to assembler
sb:
    cmp #'c'
    bne err2        ;not branch when its "sbc"
    ldx #$ED        ;load absolute opcode
    ldy #$E9        ;load immediate opcode
    jmp load        ;jump to assembler
se:
    cmp #'c'        
    bne err2        ;not branch when its "sec"
    lda $28         ;load status register
    ora #$1         ;set last bit to 1 or leave last bit at 1, bits in this register are mapped like NV--DIZC
    sta $28         ;store status register
    jmp start       ;return for next input
rotl:               ;implied mode only for now
    cmp #'l'        
    bne err2        ;not branch when its "rol"
    lds             ;load and apply status register
    lda AR          ;load A register
    rol             ;rotate left
    sta AR          ;store A register
    sts             ;store potentially modified status register
    jmp start       ;return for next input
loadx:
    cmp #'x'        
    bne loady       ;not branch when its "ldx"
    ldy #$A2        ;load immediate and absolute opcodes
    ldx #$AE
    jmp load        ;jump to assembler
storx:
    ldx #$8E        ;load absolute opcode and magic number
    ldy #0
    jmp load        ;jump to assembler
ls:
    cpy #'s'
    bne err2
    cmp #'r'
    bne err2        ;not branch when its "lsr"
    lds             ;load and apply the status register
    lda AR          ;load A register
    lsr             ;bit shift to the left
    sta AR          ;store A register
    sts             ;store potentially changed status register
    jmp start       ;jump to assembler
story:
    ldx #$8C        ;load absolute opcode and magic number
    ldy #0
    jmp load        ;jump to assembler
st0:
    ldx #$9C        ;load absolute opcode and magic number
    ldy #0
    jmp load        ;jump to assembler
loady:
    cmp #'y'
    bne err         ;not branch when its "ldy"
    ldy #$A0        ;load immediate and absolute opcodes
    ldx #$AC
    jmp load        ;jump to assembler
andr:
    cmp #$24       
    bne err         ;not branch when the "$" is detected
    stx ZP          ;store absolute opcode to 1st byte of the code
    ldx #2          ;load the offset for reading the arguments for reading the last 2 nibbles of the argument
    ldy #0          ;load the offset for writing the binary code
    bra ldmath      ;branch to decoding the text
cng:
    sta $24         ;might not need to branch but whatever
    bra ldmath      ;go back to main code
load:               ;building instruction (or code) with arguments, x = absolute opcode, y = immediate opcode
    lda ZP+3        ;check for the space after the instruction input
    cmp #$20
    bne err
    lda ZP+4        ;check for first symbol of the argument
    cmp #$23        
    bne andr        ;not "#" detected, its not immediate address mode
    cpy #0          ;check for the magic number
    beq err         ;magic number detected, that means that there's no immediate address mode for the instruction.
    sty ZP          ;store immediate opcode to 1st byte of the code
    ldy #0          ;load the offset for writing the binary code
here:               ;dis is skipped for the first time running the code for absolute address mode
    ldx #0          ;load the offset for reading the arguments, read the first 2 nibbles of the argument
    lda $23         ;load the value for checking for nibble skip
    cmp #1         
    beq cng         ;value is 1, branch to change the value for nibble skip to 1
ldmath:
    lda ZP+5,x      ;load the 1st+x nibble
    cmp #$30        ;check for "0"
    bmi err         ;error out when its less than a number PETSCII code
    cmp #$3A        ;check for "9"+1
    bmi dek         ;branch to decimal decoding when it's a number PETSCII code
    jsr hex         ;jsr to hex decoding subroutine
    sta ZP+1,y      ;hex subroutine ended, store decoded value at 2nd or 3rd byte of code
    bra dig2        ;skip to decoding 2nd+x nibble
dek:
    sec 
    sbc #$30        ;35('5')-30=5
    sta ZP+1,y      ;store decoded value at 2nd or 3rd byte of code
dig2:
    lda $24         ;load the nibble skip value
    cmp #1          
    beq ender       ;skip to end if nibble skip is set
    lda ZP+6,x      ;load the 2nd+x nibble
    cmp #0          ;check for null terminator
    beq ender2      ;only 1 or 3 nibbles are entered but that's fine. skip to the handler of that
    bmi err
    cmp #$3A        ;the same as previous time
    bmi dek2        ;copy of previous decoder, just it stores decoded bytes ad 3rd or 4th byte at the end it branches to merger
    jsr hex         ;jsr to hex decoder
    sta ZP+2,y      ;store hex subroutine ended, store decoded value at 3rd or 4th byte of code
merger:
    lda ZP+1,y      ;load 2nd or 3rd byte of the code
    asl             ;shift the lower nibble to the upper nibble spot
    asl 
    asl 
    asl 
    clc 
    adc ZP+2,y      ;add this and 3rd or 4th byte of the code
    sta ZP+1,y      ;store the new 2nd or 3rd byte of the code
    iny             ;increment Y to increment where to store bytes
    cpx #1          ;check for the read offset of 1 (set by ender2 branch) or 2
    bpl here        ;if it's that then loop to the start of the assembler
    bra ender       ;skip some code and go to the end
err:                ;error handler
    lda #$0D
    jsr CHROUT
    lda #'e'
    jsr CHROUT      ;output enter and 'e'
    jmp start       ;return to the start
dek2:
    sec 
    sbc #$30    
    sta ZP+2,y
    bra merger
ender2:
    lda ZP+4        ;check for the first symbol of the argument again
    cmp #$24 
    bne ender       ;its '#', the program can skip to the end
    ldx #1          ;load read offset of 1
    ldy #0          ;load write offset of 0
    stx $23         ;set the value for setting the nibble skip
    bra ldmath      ;do the assemble routine again with these values
ender:
    lda ZP+4       
    cmp #$24        ;check for the first symbol of the argument again
    beq alt         ;branch to alternative if its "$"
    lda #$60        
    sta ZP+2        ;store "rts" opcode to last (3rd) byte of the code
ret:
    ldx XR
    ldy YR
    lds 
    lda AR          ;load A, X, Y registers and a status register
    jsr ZP          ;jsr to the code that the assembler has built
    sta AR
    stx XR
    sty YR          
    sts             ;store the registers
    jmp start       ;jump to the start
hex:                ;hex decoder
    cmp #$41        
    bmi err         ;branch if input is less than PETSCII "A"
    cmp #$47    
    bpl err         ;branch if input is more than PETSCII "F"
    sec 
    sbc #$37        ;$42-$37=$0B
    rts             ;return to writing bytes
alt:
    lda #$60
    sta ZP+3        ;store "rts" opcode to 4th byte of the code
    bra ret         ;go back to the main program