# program to set up a call to main(int argc, char ** argv, char ** envp)

	.text
	.global _start, println, main
	.equ  EXIT, 1

_start:
	ldr r0, [sp]		@ argc value
	add r1, sp, #4		@ argv address
	bl main			@ call main
	mov r0, #0		@ success exit code
	mov r7, #EXIT
        svc 0			@ return to OS

# program to print the current command line parameters and environment
# variables
# modifies r0, r1, r2

	.equ WRITE, 4
	.equ STDOUT, 1
main:
	push {r4, r5, lr}	@ save registers and push return address
	add r1, #4
	ldr r0, [r1]
	bl atoi
	ldr r1, =buff
#	mov r7, #1
#	svc 0
	bl n2e
# done -- return
	pop {r4, r5, pc}		@ return to caller

# print the elements of a string array
# parameters
#   r0:   output file descriptor
#   r1:   string array pointer -- terminated with a null
# returns nothing
parray:
	push {r4, r5, lr}
	mov r4, r0		@ save r0 (fd)
	mov r5, r1		@ and r1 (string array pointer)
##0:
##      ldr r1, [r5], #4        @ get current string address, and advance
##      cmp r1, #0
##      beq 1f
##      mov r0, r4              @ pass fd in r0
##      bl println              @ write the string
##      bal 0b                  @ get more strings
##1:
##      pop {r4, r5, pc}
#       a shorter (by one instruction) loop, at the expense of one
#       initial branch
        bal 1f
0:
        mov r0, r4              @ pass fd in r0
        bl println              @ write the string
1:
        ldr r1, [r5], #4        @ get current string address, and advance
        cmp r1, #0              @ are we done?
        bne 0b                  @ no, write the string
        pop {r4, r5, pc}


# determine string length
# parameters
#   r0:   address of null-terminated string
# returns
#   r0:   length of string (excluding the null byte)
# modifies r0, r1, r2
strlen:
	@ push {lr}
	mov r1, r0		@ address of string
	mov r0, #0		@ length to return
0:
	ldrb r2, [r1], #1	@ get current char and advance
	cmp r2, #0		@ are we at the end of the string?
	addne r0, #1
	bne 0b
# return
	@ pop  {pc}
	mov pc, lr
CR:	.byte '\n
BANNER1:.asciz "\nCommand line parameters:"
BANNER2:.asciz "\nEnvironment variables:"

	.align 2
	.data
buff:	.space 40000
