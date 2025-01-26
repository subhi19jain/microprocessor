%macro io 4
	mov rax,%1          ; Set syscall number in rax (1 for write)
	mov rdi,%2          ; Set file descriptor in rdi (1 for stdout)
	mov rsi,%3          ; Set pointer to the buffer in rsi
	mov rdx,%4          ; Set length of the buffer in rdx
	syscall             ; Make the syscall
%endmacro

section .data
	msg1 db "Write an X86/64 ALP to accept five hexadecimal numbers from user and store them in an array and display the accepted numbers.",10
	msg1len equ $-msg1  ; Calculate length of msg1
	msg2 db "Enter five 64-bit hexadecimal number: ",10
	msg2len equ $-msg2  ; Calculate length of msg2
	msg3 db "The five 64-bit hexadecimal number are: ",10
	msg3len equ $-msg3  ; Calculate length of msg3
	error db "ERROR"    ; Error message
	errorlen equ $-error; Calculate length of error message
	newline db 10       ; Newline character

section .bss
	ascii resb 17      ; Reserve 17 bytes for ASCII input
	hexnum resq 5      ; Reserve space for 5 64-bit hexadecimal numbers
	temp resb 16       ; Temporary buffer (not used in this code)

section .code
global _start         ; Entry point for the program

_start:
	io 1,1,msg1,msg1len ; Print the first message
	io 1,1,msg2,msg2len ; Print the second message

	mov rcx,5          ; Set loop counter to 5 (for 5 numbers)
	mov rsi,hexnum     ; Set rsi to point to the hexnum array

next3:
		push rsi         ; Save current pointer to hexnum
		push rcx         ; Save loop counter
		io 0,0,ascii,17  ; Read ASCII input from user
		call ascii_hex64  ; Convert ASCII to hexadecimal
		pop rcx          ; Restore loop counter
		pop rsi          ; Restore pointer to hexnum
		mov [rsi],rbx    ; Store the converted number in hexnum
		add rsi,8        ; Move to the next 64-bit slot (8 bytes)
		loop next3       ; Repeat until 5 numbers are read

	io 1,1,msg3,msg3len ; Print the third message
	
	mov rsi,hexnum     ; Set rsi to point to the hexnum array
	mov rcx,5          ; Set loop counter to 5 (for displaying numbers)

next4: 		
		push rsi         ; Save current pointer to hexnum
		push rcx         ; Save loop counter
		mov rbx,[rsi]    ; Load the current 64-bit number from hexnum
		call hex_ascii64  ; Convert hexadecimal to ASCII for display
		pop rcx          ; Restore loop counter
		pop rsi          ; Restore pointer to hexnum
		add rsi,8        ; Move to the next 64-bit slot (8 bytes)
		loop next4       ; Repeat until all numbers are displayed

	mov rax,60         ; Set syscall number for exit
	mov rdi,0          ; Set exit code to 0
	syscall             ; Make the syscall to exit

; Convert ASCII input to 64-bit hexadecimal number
ascii_hex64:
	mov rsi,ascii      ; Set rsi to point to the ASCII buffer
	mov rbx,0          ; Clear rbx to store the resulting number
	mov rcx,16         ; Set loop counter to 16 (for 16 hex digits)
	
next1: 	
		rol rbx,4       ; Rotate rbx left by 4 bits (prepare for next hex digit)
		mov al,[rsi]     ; Load the current ASCII character into al
		
		; Check if the character is a valid hex digit
		cmp al,29H      ; Compare with '0'
		jbe err          ; If less than or equal to '0', it's an error
		cmp al,40H      ; Compare with 'A'
		je err           ; If equal to 'A', it's an error
		cmp al,67H      ; Compare with 'a'
		jge err          ; If greater than 'a', it's an error
		cmp al,47H      ; Compare with 'F'
		jge check_furthur; If greater than 'F', check further
		jmp operations    ; Jump to operations if valid

check_furthur:
		cmp al,60H      ; Compare with '9'
		jbe err          ; If less than or equal to '9', it's valid

operations:
		cmp al,39H      ; Compare with '9'
		jbe sub30h      ; If less than or equal to '9', subtract 30H
		cmp al,46H      ; Compare with 'A'
		jbe sub7h       ; If less than or equal to 'A', subtract 7H
		sub al,20H      ; Convert lowercase letters to their hex values

sub7h:
		sub al,7H       ; Adjust for ASCII value of 'A'
sub30h: 
		sub al,30H      ; Adjust for ASCII value of '0'
		
		jmp skip         ; Skip to storing the result

err:
		io 1,1,error,errorlen ; Print error message
		mov rax,60      ; Set syscall number for exit
		mov rdi,0       ; Set exit code to 0
		syscall          ; Exit the program

skip:
		add bl,al       ; Add the converted value to rbx
		inc rsi         ; Move to the next character in the ASCII buffer
		dec rcx         ; Decrement the loop counter
		loop next1      ; Repeat until all characters are processed
	ret

; Convert 64-bit hexadecimal number to ASCII for display
hex_ascii64:
	mov rsi,ascii      ; Set rsi to point to the ASCII buffer
	mov rcx,16         ; Set loop counter to 16 (for 16 hex digits)
	
next2: 	
		rol rbx,4       ; Rotate rbx left by 4 bits (prepare for next hex digit)
		mov al,bl       ; Move the least significant 4 bits to al
		and al,0fh      ; Mask to get the hex digit
		cmp al,9        ; Compare with 9
		jbe add30h      ; If less than or equal to 9, add 30H
		add al,7H       ; Adjust for ASCII value of letters A-F
		
add30h: 
		add al,30H      ; Convert to ASCII by adding 30H
		mov [rsi],al    ; Store the ASCII character in the buffer
		inc rsi         ; Move to the next position in the buffer
		loop next2      ; Repeat until all digits are processed
		io 1,1,ascii,16 ; Print the ASCII representation
		io 1,1,newline,1; Print a newline
	ret
