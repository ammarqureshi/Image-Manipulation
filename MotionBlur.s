BLUR EFFECT	
	
	AREA	MotionBlur, CODE, READONLY
	PRESERVE8
	IMPORT	main
	IMPORT	getPicAddr
	IMPORT	putPic
	IMPORT	getPicWidth
	IMPORT	getPicHeight
	EXPORT	start

start
	;r4 =pic adress
	BL	getPicAddr			; load the start address of the image in R4
	MOV	R4, R0				;MODIFY ARRAY
	LDR R12,=0xA1800000		;ORIGINAL ARRAY	;declaring space for copy

;R5 = no of rows
	BL	getPicHeight		; load the height of the image (rows) in R5
	MOV	R5, R0

;R6 = no of columns
	BL	getPicWidth			; load the width of the image (columns) in R6
	MOV	R6, R0

;store all the pixel values in a copy array.
	STMFD sp!,{R4-R9,R11}		  	;restore registers
	LDR R9,=0					;R4=index

nextPixel
	MUL R7,R5,R6				;number of pixels in the image or the size of the image			

	CMP R9,R7
	
	BHS endPixel
	LDR	R11,[R4,R9,LSL#2]		;load values
	STR	R11,[R12,R9,LSL#2]		;store values into copy array.
	ADD R9,R9,#1				;index++
	B nextPixel
endPixel	

	LDMFD sp!,{R4-R9,R11}		;pop registers back			need R12 as copy array

	LDR R11,=2				;radius=2
;setting the row size and column size
	SUB R5,R5,R11		;row size = row size - radius
	SUB R6,R6,R11		;col size = col size - radius

;starting row and column	
	MOV R7,R11			;R7=ROW=radius
	MOV R8,R11			;R8-COLUMN=radius

;restarting the parameters
;R0,R1,R2 are updated.	
	MOV R0,#0			;total red
	MOV R1,#0			;total green
	MOV R2,#0			;total blue			
	MOV R3,#0	
			
;for(row=radius ;row<row_size-radius;row++)
rowloop	
	CMP R7,R5			;compare row with row size
	BHS finish			;if equal end
	

;for(col=radius;col<col size-radius;col++)
;changes accordingly with the radius.	
colLoop
	CMP R8,R6				;compare column with column size
	BHS	nextRow

;restart the parameters again
	MOV R0,#0			;total red
	MOV R1,#0			;total green
	MOV R2,#0			;total blue			
	MOV R3,#0	

;move them as parameters
	MOV R0,R7				;R0=ROW
	MOV R1,R8				;R1=COLUMN
	MOV R2,R12				;R2=copy array
	MOV R3,R11				;R3=radius

	BL totalPixel		   ;totalPixel(row,column,original array,radius)
;GET TOTAL RED,TOTAL GREEN,TOTAL BLUE FROM TOTALPIXEL SUBROUTINE//no need to change as already in correct param.

;parameters to getAverage R0,R1,R2 which are the total individual color values.
;and R3=radius
	BL getAverage			;totalPixel(total red,total green,total blue)			
	
	BL recombineColors
			
;store the result passed on from recombineColors into R4 the original array

	STR R0,[R4,R9,LSL#2]	;store the average value to target pixel into the modified array

	ADD R8,R8,#1			;COLUMN++
	
	B colLoop				;next column

nextRow
	ADD R7,R7,#1			;row++
	LDR R8,=0				;restart column back to 0 for next row.
	B rowloop				;next column
;----------------------------------------------------------------------------------------		
;totalPixel subroutine
;totalPixel(row,column,original array,radius)
;parameters passed	-			R0-row			R1-column			R2-copy array 	R3-radius 
;paremters returned	-  			R0-total red	R1-total green		R2-total blue
totalPixel

	STMFD sp!,{R4-R12,lr}
	
	MOV R4,#0				;total red
	MOV R5,#0				;total green
	MOV R6,#0				;total blue
	MOV R7,R0  				;R7-ROW
	MOV R8,R1				;R8-COLUMN
	MOV R9,R2				;R9-COPY ARRAY
	MOV R10,R3				;R10-RADIUS	
	MOV R11,#0				;count=0			

loop1
	CMP R11,R10						;while(count<radius)
	BHS endloop1 

	SUB R7,R7,#1					;row--
	SUB R8,R8,#1					;column--	
	ADD R11,R11,#1					;count++
	B loop1
endloop1	
;here I have obtained the  leftmost row and column in R7 and R8 now I am at top left of diagonal required	

;while loop while (count < (radius*2+1))

	LDR R11,=0						;count=0
	
	MOV R12,R12,LSL#1				;radius*2
	ADD R12,R12,#1					;+1
	
;r11= no of rows
	BL	getPicHeight				; load the height of the image (rows) in R5
	MOV	R11, R0						;R11-row size
		
whileloop	
	CMP R11,R12						;while (COUNT<((RADIUS*2)+1))
	BHS endwh
	STMFD sp!,{R7,R8,R9,R11,R12}
	
	MOV R12,#0						;index-0
	MUL R12,R7,R11					;index = row * row size
	ADD R12,R12,R8					;index- row *row size + column
	LDR R11,[R9,R12,LSL#2]			;R10 unused original array
	MOV R3,R11						;pass picel value
	
	LDMFD sp!,{R7,R8,R9,R11,R12}				;store registers again to add in to total the color values.
	
;R3-PIXEL VALUE AS PARAMETERS 
	BL getRed
	ADD R4,R4,R0					;total red value = total red value + red value
	
	BL getGreen
	ADD R5,R5,R0					;total green value = total green value + green value
	
	BL getBlue	
	ADD R6,R6,R0					;total blue value = total blue value + blue value
										                                                         
	ADD R7,R7,#1					;row++
	ADD R8,R8,#1					;col++
	ADD R11,R11,#1					;counter++
	B whileloop						;branch to next pixel
endwh	

;total color values

	MOV R0,R4				;total red
	MOV R1,R5				;total green
	MOV R2,R6				;total blue

	LDMFD sp!,{R4-R12,pc}			;restore registers
;-------------------------------------------------------------------------------------------------------
;extracts the red value fromt the given pixel value
;getRed subroutine
;parameters passed  				R3=pixel value
;parameters returned 				R0-red value
getRed

	STMFD sp!,{R4-R12,lr}
	
	MOV R5,#0				;red value -0
	MOV R4,#0				;restart registers
	MOV R4,R3				;R4=pixel value
	BIC R5,R4,#0xFF00FFFF	;R5 = red value in its postion
	MOV R5,R5,LSR#16		;shift red value by 16 bits to the right to do some calculations
	MOV R0,R5				;pass parametere red value in correct position
	
	LDMFD sp!,{R4-R12,pc}
;------------------------------------------------------------------------------

;extracts the green value fromt the given pixel value
;getGreen subroutine
;parameters passed  R3=pixel value
;parameters returned R1-green value
getGreen
	STMFD sp!,{R4-R12,lr}
	
	MOV R5,#0				;green value -0
	MOV R4,#0				;restart registers.
	MOV R4,R3				;R4=pixel value
	BIC R5,R4,#0xFFFF00FF	;R5 = red value in its postion
	MOV R5,R5,LSR#8			;shift red value by 16 bits to the right to do some calculations
	MOV R1,R5				;pass parametere red value in position of least significant bit.
	
	LDMFD sp!,{R4-R12,pc}

;-----------------------------------------------------------------------------------------------

;extracts the blue value fromt the given pixel value
;getBlue subroutine
;parameters passed  R3=pixel value
;parameters returned R2-blue value
getBlue

	STMFD sp!,{R4-R12,lr}

	MOV R5,#0				;green value -0
	MOV R4,#0				;restart registers
	MOV R4,R3				;R4=pixel value
	BIC R5,R4,#0xFFFFFF00	;R5 = red value in its postion
	MOV R2,R5				;pass parametere red value in position of least significant bit.
	
	LDMFD sp!,{R4-R12,pc}

;=================================================================================

;getAverage subroutine
;averages the total value of red,green and blue
;paramters passed 		r0=total red value	r1=total green value	r2=total blue value		r3-radius
;parameters returned	r0=average red value	r1=average green value	r2=average blue value
getAverage

	STMFD sp!,{R4-R12,lr}

	MOV R5,R0			;R5=RED VALUE
	MOV R6,R1			;R6-GREEN VALUE
	MOV R7,R2			;R7-BLUE VALUE


	MOV R0,R5			;R0-total red value
	BL divide
	MOV R5,R0			;R5-average red value
	
	MOV R0,R6			;R0-total green value
	BL divide
	MOV R6,R0			;R6-average green value
	
	MOV R0,R7			;R0-total blue value
	BL divide
	MOV R7,R0			;R7- average blue value

		
;MOVE BACK AS PARMETERS 

	MOV R0,R5  			;RED 
	MOV R1,R6			;GREEN
	MOV R2,R7			;BLUE
	
	LDMFD sp!,{R4-R12,pc}
	
	
;--------------------------------------------------------------------------------------
;divide subroutine
;divides 
;parameters passed			R0-total individual color value		r3-radius
;parametrs returned			R0-average color value

divide
	STMFD sp!,{R4-R12,lr}
		
	LDR R4,=0			;quotient=0	
	MOV R9,#2
	MOV R5,R1			;R5=remainder  which is the red value
	MOV R6,R3			;R6=radius 
	
;R7=divisor		if radius=2 divisor=5	
	MUL R7,R6,R9		;radius*2
	ADD R7,R7,#1		;radius*2+1		//including the middle one
divide
	CMP R5,R7			;compare remainder with divisor
	BLT endDivision
	
	SUB R5,R5,R7		;remainder-remainder-divisor(radius*2+1)
	ADD R4,R4,#1		;quotient++
	
	B dvide
	
endDivision	

	MOV R0,R4			;R0-quotient sending back

	LDMFD sp!,{R4-R12,pc}
;--------------------------------------------------------------------------------------------

;recombine funcion
;recombines the average colors 
;parameters passed		r0=average red 
;parameters passed		r1-average green
;parametrs passed		r2-average blue

;parameters returned	r0-average pixel value

recombineColors		
	
	STMFD sp!,{R4-R12,lr}
;restart registers	
		
	MOV R7,#0
	
	MOV R4,R0			;R4-red
	MOV R5,R1			;R5-green
	MOV R6,R2			;R6-blue
	
;move red into its correct position.MSB most significant byte
	
	MOV R4,R4,LSL#16	
	
;move green into its correct pos. NMSN next most significant byte
	
	MOV R5,R5,LSL#8
	
;blue value already in its correct pos.	 which is in R6.


	ORR R7,R4,R5		;ORing red and green
	ORR R7,R7,R6		;ORing red and green and blue

;R0-recombined value
	MOV R0,R7			;pass the recombined RGB pixel value to main.

	LDMFD sp!,{R4-R12,pc}

;-------------------------------------------------------------------------------------------------
finish	
	BL	putPic				; re-display the updated image
stop	B	stop
	END