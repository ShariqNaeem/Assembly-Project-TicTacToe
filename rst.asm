.model small
.stack 200h

.data

matrix db 9 dup(0)
player db 0
win db 0
temp db 0
rematch db "*Would you like a rematch? (y->yes , (any key)->no)$*"
welcome db "***TIC_TAC_TOE***$"
format db "---|---|---$"
Location db "Enter your move by location(1-9)$"
turntoX db "Player 1 (X) turn$"
turntoO db "Player 2 (O) turn$"
mTie db "A tie between the two players!$"
mWin db "The player who won was player $"
full db "ERROR!, this place is taken$"
other db "ERROR!, input is not a digit$"

.code
main proc

newline macro
mov ah,2
mov dl,10
int 21h

mov dl,13
int 21h
endm

SOUND MACRO
local pause1,pause2

mov al,182   ;prepare the speaker for the
out 43h,al   ;note.
mov ax,2000  ;freq no. (in Deci)
             ;for middle c
out 42h,al   ;output low byte
mov al,ah    ;output high byte
out 42h,al
in al,61h    ;turn on note(get value from port 61h)

or al,00000011b  ;set bit 1 and 0
out 61h,al       ;send new value
mov bx,25        ;pause for duration of note
   
pause1:
mov cx,80000 

pause2:
dec cx 

jne pause2
dec bx
jne pause1
in al,61h  ;turn off note(get value from port 61h)

and al,11111100b ;reset bit 1 and 0
out 61h,al       ;send new value

endm


mov ax,@data
mov ds, ax
mov es, ax
	
newGame:

call initiateGrid
mov player,10b         ;10b = 2decimal
mov win, 0
mov cx, 9

push cx
sound
pop cx

Fillmatrix:

call clearScreen
mov dx,OFFSET welcome
		
call printString

newline

mov dx,OFFSET location
call printString

newline

call printGrid

mov al, player

cmp al, 1
je p2turn
;//////////////// previous player was 2////////////////////
			
shr player, 1                   ; 0010b --> 0001b;
mov dx,OFFSET turntoX
call printString

newline

jmp playerSwitch

p2turn:
                              ; previous player was 1
shl player, 1                 ; 0001b --> 0010b
mov dx,OFFSET turntoO
call printString

newline			
		
playerSwitch:
call MOVING                  ; bx will point to the right board postiton at the end of getMove
mov dl, player

cmp dl, 1
jne p2move

mov dl, 'X'
jmp contMoves
		
p2move:
mov dl, 'O'

contMoves:

mov [bx], dl

cmp cx, 5                      ; no need to check before the 5th turn
jg noWinCheck
call checkWin

cmp win, 1
je won


noWinCheck:
loop fillMatrix
;///////////////////tie, cx = 0 at this point and no player has won///////////////

conti:
call clearScreen

mov dx,OFFSET welcome
call printString

newline
newline
newline

call printGrid

mov dx,OFFSET mTie
call printString

newline

jmp playAgain
	 
won:                                 ; current player has won
call clearScreen
mov dx,OFFSET welcome
call printString

newline
newline
newline

call printGrid

mov dx,OFFSET mWin
call printString
mov dl, player

add dl, '0'
call putChar

newline	 

playAgain:
 mov dx,offset rematch               ; ask for another game
 call printString

newline

 call getChar
 cmp al, 'y'                                 ; play again if 'y' is pressed
 jne EXIT
 jmp newGame
	 
EXIT:
sound

mov ah, 4ch
int 21h
	
main endp

getChar:
mov ah, 01
int 21h
ret

putChar:
mov ah, 02
int 21h
ret

printString:
mov ah, 09
int 21h
ret


;////////////////////OverRiding the matrix//////////////

clearScreen:
mov ah, 0fh 
int 10h
mov ah, 0
int 10h
ret
	


Moving:
call getChar                      ; al = getchar()
call isValidDigit
	
cmp ah, 1
je contCheckTaken
mov dl, 0dh
	
call putChar
	
mov dx,OFFSET other
call printString

newline

jmp Moving
	



contCheckTaken:                   ; Checks this: if(grid[al] > '9'), grid[al] == 'O' or 'X'
mov bx,OFFSET matrix 	
sub al, '1'

mov ah, 0
add bx, ax
mov al, [bx]
cmp al, '9'
jng finishGetMove

mov dl, 0dh
call putChar
mov dx,OFFSET full
call printString

newline

jmp Moving
finishGetMove:

newline

ret
	


;///////////make grid/////////////////////
initiateGrid:
mov bx,OFFSET matrix

mov al, '1'
mov cx, 9
initNextTa:
mov [bx], al
inc al
inc bx
loop initNextTa
ret




	
isValidDigit:
mov ah, 0

cmp al, '1'
jl sofIsDigit

cmp al, '9'
jg sofIsDigit

mov ah, 1

sofIsDigit:
ret




	
printGrid:

mov bx,OFFSET matrix

call printRow

mov dx,OFFSET format
call printString

newline

call printRow

mov dx,OFFSET format
call printString

newline

call printRow
ret





printRow:
;////////First Cell////////////

mov dl, ' '
call putChar

mov dl, [bx]
call putChar

mov dl, ' '
call putChar
	
mov dl, '|'
call putChar

inc bx
	
;/////////Second Cell///////////////

mov dl, ' '
call putChar

mov dl, [bx]
call putChar

mov dl, ' '
call putChar

mov dl, '|'
call putChar

inc bx
	
;//////////Third Cell////////////////
mov dl, ' '
call putChar

mov dl, [bx]
call putChar

inc bx

newline

ret
	


checkWin:
mov si, OFFSET matrix

call checkDiagonal

cmp win, 1

je endCheckWin
call checkRows

cmp win, 1

je endCheckWin
call CheckColumns

endCheckWin:
ret
	
checkDiagonal:
;/////////////////Diagonal left to right////////////////////////
mov bx, si
mov al, [bx]
add bx, 4	          ;grid[0] ---> grid[4]
	
cmp al, [bx]
jne diagonal@Right_Left

add bx, 4	          ;grid[4] ---> grid[8]


cmp al, [bx]
jne diagonal@Right_Left

mov win, 1
ret


;/////////////////Diagonal right to left////////////////////////
diagonal@Right_Left:
mov bx, si
add bx, 2	        ;grid[0] ---> grid[2]
mov al, [bx]
add bx, 2	        ;grid[2] ---> grid[4]


cmp al, [bx]
jne endDiagonal
add bx, 2	        ;grid[4] ---> grid[6]


cmp al, [bx]
jne endDiagonal
mov win, 1
endDiagonal:
ret
;///////////////////////////////////////Check rows/////////////////////////////////////////////
checkRows:	

mov bx, si; --->grid[0]
mov al, [bx]
inc bx

		;grid[0] ---> grid[1]
cmp al, [bx]
jne secondRow
inc bx

		;grid[1] ---> grid[2]
cmp al, [bx]
jne secondRow
mov win, 1
ret
	
secondRow:
mov bx, si; --->grid[0]
add bx, 3	;grid[0] ---> grid[3]
mov al, [bx]
inc bx	;grid[3] ---> grid[4]


cmp al, [bx]
jne thirdRow
inc bx	;grid[4] ---> grid[5]


cmp al, [bx]
jne thirdRow
mov win, 1
ret
	
thirdRow:
mov bx, si; --->grid[0]
add bx, 6;grid[0] ---> grid[6]
mov al, [bx]
inc bx	;grid[6] ---> grid[7]


cmp al, [bx]
jne endRows
inc bx	;grid[7] ---> grid[8]


cmp al, [bx]
jne endRows
mov win, 1
endRows:
ret
;/////////////////////////Check columns///////////////////////////////////////
CheckColumns:
;firstColumn
mov bx, si; --->grid[0]
mov al, [bx]
add bx, 3	;grid[0] ---> grid[3]

cmp al, [bx]
jne secondColumn
add bx, 3	;grid[3] ---> grid[6]

cmp al, [bx]
jne secondColumn
mov win, 1
ret
	
secondColumn:
mov bx, si; --->grid[0]
inc bx	;grid[0] ---> grid[1]
mov al, [bx]
add bx, 3	;grid[1] ---> grid[4]

cmp al, [bx]
jne thirdColumn
add bx, 3	;grid[4] ---> grid[7]

cmp al, [bx]
jne thirdColumn
mov win, 1
ret
	
thirdColumn:
mov bx, si      ; --->grid[0]
add bx, 2	;grid[0] ---> grid[2]
mov al, [bx]
add bx, 3	;grid[2] ---> grid[5]

cmp al, [bx]
jne endColumns
add bx, 3	;grid[5] ---> grid[8]

cmp al, [bx]
jne endColumns
mov win, 1

endColumns:
ret
	
end main

