# Author: Nicholas Keen
# Assignment: 8
# Date: Dec 15, 2015

	.text
	.global n2e
	.equ STDOUT, 1

# procedure n2e -- convert a 32-bit value into English words
# parameters:
#	r0 - the value to convert (unsigned integer)
#	r1 - the address of a character buffer to put the result
# returns nothing
# assumes the character buffer in r1 is sufficiently large to hold
# the resulting words. Result will be null terminated upon return.
n2e:
	push {r4, r5, lr}
	mov r4, r0	@ save r0, 'n'
	mov r5, r1	@ save r1
	cmp r4, #0	@ check for zero
	beq 0f		@ prints zero
	bal 5f
10:
	mov r0, r4
	mov r1, r5
	cmp r4, #99
	ble 1f		@ less than 100
	ldr r2, =999
	cmp r4, r2
	ble 2f		@ at least 100
	ldr r2, =999999
	cmp r4, r2
	ble 3f		@ at least 1000
	ldr r2, =999999999
	cmp r4, r2
	ble 4f		@ at least 1000000
0:
	mov r0, #STDOUT
	adr r1, w0
	bl println
	pop {r4, r5, pc}

5:
	ldr r1, =1000000000
	bl qr			@ divide
	cmp r0, #0		@ ensure at least one billion
	beq 10b
	mov r6, r0		@ q
	mov r7, r1		@ r
	mov r1, r5
	bl one
	mov r0, r5
	bl loop
	mov r5, r0
	ldr r1, =wb		@ load billions
	str r1, [r5]		@ store billion into buffer
	cmp r7, #0		@ check for r
	beq 9f
	mov r0, r5
	bl loop
	mov r0, r7		@ prepare for next case
4:
	ldr r1, =1000000
	bl qr			@ divide
	cmp r0, #0		@ ensure at least one million
	beq 2f
	mov r6, r0		@ q
	mov r7, r1		@ r
	bl tmbs
	ldr r1, =wm		@ load millions
	str r1, [r5]		@ store million into buffer
	cmp r7, #0		@ check for r
	beq 9f
	mov r0, r5
	bl loop
	mov r0, r7		@ prepare for next case
3:
	ldr r1, =1000
	bl qr			@ divide
	cmp r0, #0		@ ensure at least one thousand
	beq 2f
	mov r6, r0		@ q
	mov r7, r1		@ r
	bl tmbs
	ldr r1, =wt		@ load thousand
	str r1, [r5]		@ store thousand into buffer
	cmp r7, #0		@ check for r
	beq 9f
	mov r0, r5
	bl loop
	mov r0, r7		@ prepare for next case
2:
	cmp r0, #99
	ble 1f
	mov r1, #100
	bl qr			@ divide
	cmp r0, #0		@ check for zero
	beq 1f			@ there are no hundreds
	mov r6, r0		@ q
	mov r7, r1		@ r
	mov r1, r5
	bl one
	mov r0, r5		@ prints hundreds
	bl loop
	ldr r0, =w100		@ load hundred
	str r0, [r5]		@ store into buffer
	cmp r7, #0		@ check for r
	beq 9f
	mov r0, r5
	bl loop
	mov r0, r7		@ prepare for next case
1:
	mov r3, r1
	bl udiv10
	cmp r0, #1		@ check for 1
	ble small		@ n <= 19
	mov r6, r0		@ save q
	mov r7, r1		@ save r
	cmp r7, #0		@ check for zero
	addne r6, r6, #8	@ offset into table
	mov r0, r6
	mov r1, r5		@ prints n > 20
	bl ten
	mov r5, r0
	beq 9f
	mov r0, r5
	bl loop			@ call loop
	mov r0, r7
	mov r1, r5
	bl one
	bal 9f			@ branch to print
small:
	cmp r4, #19
	movgt r4, r7		@ prints 1 >= n < 20
	mov r0, r4
	mov r1, r5
	bl one
	mov r5, r0
9:
	mov r0, r5
	bl loop
	mov r0, #STDOUT
	bl newline
	pop {r4, r5, pc}	@ exits n2e

# procedure tmb -- handles the thousands, millions and billions
# parameters:
#	r0 - quotient
#	r1 - remainder
# returns nothing
tmbs:
	push {r5, r6, r8, lr}
	cmp r0, #99
	ble 8f
	mov r1, #100
	bl qr
	mov r8, r1
	mov r1, r5
	bl one			@ print the number of hundreds
	mov r5, r0
	mov r0, r5
	bl loop
	ldr r0, =w100		@ print hundred
	str r0, [r5]
	cmp r8, #0
	beq 7f
	mov r0, r5
	bl loop
	mov r6, r8
	mov r0, r8
8:
	bl udiv10
	mov r8, r1
	cmp r0, #1
	movle r8, r6
	ble 6f
# twenty or higher
	cmp r1, #0
	addne r0, r0, #8	@ offset
	mov r1, r5		@ print the tens
	bl ten
	mov r5, r0
	beq 7f
	mov r0, r5
	bl loop
6:
	mov r0, r8
	mov r1, r5		@ print the ones
	bl one
	mov r5, r0
7:
	mov r0, r5
	bl loop
	pop {r5, r6, r8, pc}

# procedure ten -- deals with 20 - 99
# parameters:
#	r0 - quotient
#	r1 - buffer address
# returns:
#	r0 - buffer address
ten:
	ldr r3, =tens		@ load the ones table
	mov r0, r0, LSL #2	@ q * 4
	ldr r2, [r3, r0]	@ offset tens table by 4q
	str r2, [r1]		@ store string into buffer
	mov r0, r1
	mov pc, lr

# procedure one -- deals with 1 - 19
# parameters:
#	r0 - 'n'
#	r1 - buffer address
# returns:
#	r0 - buffer address
one:
	ldr r3, =ones		@ load ones table
	mov r0, r0, LSL #2	@ n * 4
	ldr r2, [r3, r0]	@ go into table
	str r2, [r1]		@ store into buffer
	mov r0, r1
	mov pc, lr

# procedure loop -- prints out everything in a buffer
# parameters:
#	r0 - the buffer address
# returns:
#	r0 - the buffer after having printed contents
loop:
	push {r5, lr}
	mov r5, r0		@ save register
prnt:
	mov r0, #STDOUT		@ prepares to print buffer
	ldr r1, [r5], #4	@ grab string from buffer
	bl print
	ldr r3, [r5]		@ grab buffer contents
	cmp r3, #0		@ compare to 0
	bne prnt		@ if not, go back for more
	mov r0, r5		@ return condition
	pop {r5, pc}


# tables
ones:	.word w0
	.word w1
	.word w2
	.word w3
	.word w4
	.word w5
	.word w6
	.word w7
	.word w8
	.word w9
	.word w10
	.word w11
	.word w12
	.word w13
	.word w14
	.word w15
	.word w16
	.word w17
	.word w18
	.word w19
tens:	.word w0
	.word w10
	.word w20
	.word w30
	.word w40
	.word w50
	.word w60
	.word w70
	.word w80
	.word w90
	.word w20a
	.word w30a
	.word w40a
	.word w50a
	.word w60a
	.word w70a
	.word w80a
	.word w90a
hundred:.word w100
tmb:	.word wt
	.word wm
	.word wb

# Strings
w0:	.asciz "zero"
w1:	.asciz "one "
w2:	.asciz "two "
w3:	.asciz "three "
w4:	.asciz "four "
w5:	.asciz "five "
w6:	.asciz "six "
w7:	.asciz "seven "
w8:	.asciz "eight "
w9:	.asciz "nine "
w10:	.asciz "ten "
w11:	.asciz "eleven "
w12:	.asciz "twelve "
w13:	.asciz "thirteen "
w14:	.asciz "fourteen "
w15:	.asciz "fifteen "
w16:	.asciz "sixteen "
w17:	.asciz "seventeen "
w18:	.asciz "eighteen "
w19:	.asciz "nineteen "
w20:	.asciz "twenty "
w30:	.asciz "thirty "
w40:	.asciz "fourty "
w50:	.asciz "fifty "
w60:	.asciz "sixty "
w70:	.asciz "seventy "
w80:	.asciz "eighty "
w90:	.asciz "ninety "
w20a:	.asciz "twenty-"
w30a:	.asciz "thirty-"
w40a:	.asciz "fourty-"
w50a:	.asciz "fifty-"
w60a:	.asciz "sixty-"
w70a:	.asciz "seventy-"
w80a:	.asciz "eighty-"
w90a:	.asciz "ninety-"
w100:	.asciz "hundred "
wt:	.asciz "thousand "
wm:	.asciz "million "
wb:	.asciz "billion "
