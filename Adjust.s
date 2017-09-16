	
	AREA	MotionBlur, CODE, READONLY
	PRESERVE8
	IMPORT	main
	IMPORT	getPicAddr
	IMPORT	putPic
	IMPORT	getPicWidth
	IMPORT	getPicHeight
	EXPORT	start

start


  	BL	getPicAddr				;load the start address of the image in R4
	MOV	R4, R0					;r4=pic adr.

	BL	getPicHeight			;load the height of the image (rows) in R5
	MOV	R5, R0					;r5=height

	BL	getPicWidth				;load the width of the image (columns) in R6
	MOV	R6, R0					;r6= width


	MUL R7,R5,R6 				;size of the image
	
	LDR R8,=0					;pixel count =0


nextPixel

	 LDR R0,=0					;red value
	 LDR R1,=0					;green value
	 LDR R2,=0					;blue value
	 LDR R3,=0					;pixel value


	CMP R8,R7						;while pixelCount<pixel size
	BHS finish
	
	LDR R9,=0						;pixel value=0

	LDR R9,[R4,R8,LSL#2]			;R9=pixel value

	MOV R3,R9						;R3=PIXEL VALUE----dont change



	BL getRed						;get back r0-red
	MOV R2,R0						;R2=red value
	BL update						
	MOV R0,R2						;r0 is red value

	BL getGreen						;get back r1-green
	MOV R2,R1						;R2=green value
	BL update
	MOV R1,R2						

	BL getBlue						;get back r2-blue
	MOV R2,R2
	BL update
	;MOV R2,R2

	BL recombineColors   			;ro-recombined colors


	STR R0,[R4,R8,LSL#2]

;store pixel value


	ADD R8,R8,#1

	B nextPixel


 ;------------------------------------------------------------------------------------------------------------------------------------
 ;update pixel subroutine
 ;updates the given pixel value
 ;parameters passed 				R2-value to be updated
 ;parameters returned				R2-updated value

update

		 
	STMFD sp!,{R4-R12,lr}

	   MOV R4,R2				;R4=value to be updated.

	   LDR R5,=30				;brightness=30
		LDR R6,=20			;contrast=20
		LDR R7,=0				;updated value
		LDR R8,=0
			

	   MUL R7,R4,R6				;updated value = RED * contrast

	   MOV R8,R7,LSR#4			; (updated value = updated value * contrast)/16

	   ADD R8,R8,R5				;updated value + brightness	

	   CMP R8,#255
	   BLS done
	   MOV R8,#255
done
	  MOV R2,R8					;return the updated value


	LDMFD sp!,{R4-R12,pc}
																															 
;----------------------------------------------------------------------------------------------------------------------------------------------
;extracts the red value fromt the given pixel value
;getRed subroutine
;parameters passed  		R3=pixel value
;parameters returned 		R0-red value
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
;parameters passed  		R3=pixel value
;parameters returned 		R1-green value
getGreen
	STMFD sp!,{R4-R12,lr}
	
	MOV R5,#0				;green value -0
	MOV R4,#0				;restart registers.
	MOV R4,R3				;R4=pixel value

	BIC R5,R4,#0xFFFF00FF	;R5 = red value in its postion
	MOV R5,R5,LSR#8			;shift red value by 16 bits to the right to do some calculations
	MOV R1,R5				;pass parametere red value in position of least significant bit.
	
	LDMFD sp!,{R4-R12,pc}

;----------------------------------------------------------------------------------------------------------------------------------------------------

;extracts the blue value fromt the given pixel value
;getBlue subroutine
;parameters passed  		R3=pixel value
;parameters returned 		R2-blue value
getBlue

	STMFD sp!,{R4-R12,lr}

	MOV R5,#0				;green value -0
	MOV R4,#0				;restart registers
	MOV R4,R3				;R4=pixel value
	BIC R5,R4,#0xFFFFFF00	;R5 = red value in its postion
	MOV R2,R5				;pass parametere red value in position of least significant bit.
	
	LDMFD sp!,{R4-R12,pc}
;-------------------------------------------------------------------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------------------------------------------------

;recombine funcion
;recombines the average colors 
;parameters passed			r0=updated red 
;parameters passed			r1-updated green
;parametrs passed			r2-updated blue

;parameters returned		r0-updated pixel value

recombineColors		
	
	STMFD sp!,{R4-R12,lr}
			
	MOV R7,#0
	
	MOV R4,R0			;R4-red
	MOV R5,R1			;R5-green
	MOV R6,R2			;R6-blue
	
;move red into its correct position.MSB
	
	MOV R4,R4,LSL#16	
	
;move green into its correct pos.
	
	MOV R5,R5,LSL#8
	
;blue value already in its correct pos.	   r6


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
