


*PROMPT USER FOR INPUT
	PEA	REQ
	DC.W	$FF09
	ADDQ.L	#4,SP
*GET USERS INPUT
	PEA	INBUF_PARAM
	DC.W	$FF0A
	ADDQ.L	#4,SP
*CONVERT TO FIXED-POINT NUMBER
	PEA	INBUF
	JSR	TONUM
*MUL BY 2.2
	MOVE.L	#22,D0
	MOVE.L	(SP),D1
	JSR	FMUL
	MOVE.L	D0,(SP)
SKIP:
*CONVERT TO STRING AGAIN
	PEA	RESBUF	
	JSR	TOSTR	
*PRINT IT
	PEA	INBUF
	DC.W	$FF09
	PEA	KG_IS
	DC.W	$FF09
	PEA	RESBUF
	DC.W	$FF09
	PEA	LB
	DC.W	$FF09
	JSR	PRNTL
*EXIT
	DC.W	$FF00
*PRINT THE CONTENTS OF BUFFER ON STACK
PRNBUF:
	JSR	PRNTL
	MOVEA.L	(SP)+,A0
	DC.W	$FF09
	ADDQ.L	#4,SP
	JSR	PRNTL
	MOVE.L	A0,-(SP)
	RTS
PRNTL:
	PEA ENDL
	DC.W	$FF09
	ADDQ.L	#4,SP
	RTS
*TAKES ADDRESS OF BUFFER ON STACK
TONUM:
	MOVEA.L	(SP)+,A0
	MOVEA.L	(SP)+,A1
	CLR.L	D0				# A1=UPDATING PTR, A2=REF TO START FOR CMP
	CLR.L	D2				# A3=PTR TO POW10 TABLE
	MOVEA.L	A1,A2				# D0=ACCUMULATOR, D2=POW10
	LEA	POWS,A3
	CLR.L	D3				# D3=INT VAL OF LAST DIGIT
	CLR.L	D4				# D4=SET IF WE HIT A DOT
TONUM_FFW:
	ADDQ	#1,A1
	CMP.B	#0,(A1)				# WHY DOESN'T PREINCR HERE ACT THE SAME?
	BNE	TONUM_FFW
TONUM_RW:
	CMPI.W	#8,D2				# ONLY HAVE UP T0 10POW4...8 BYTES - 4 WORDS
	BGT	ERR_TOOBIG
	CLR.W	D1				# FIRST GETS USED AS W IN MULU
	MOVE.B	-(A1),D1
	CMP.B	#46,D1
	BEQ	TONUM_DOT
	SUBI.B	#48,D1
	MOVE.L	D1,D3				# KEEP TRACK FOR WHEN WE HIT DOT
	MULU	(0,A3,D2),D1
	ADD.L	D1,D0
	ADDQ.W	#2,D2
	CMP.L	A1,A2
	BNE	TONUM_RW
	TST.B	D4				# DID WE HIT A DOT?
	BNE	TONUM_HASDOT
	MULU	#10,D0				# ELSE WE NEED TO SHIFT UP FOR .0
	BVS	ERR_TOOBIG
TONUM_HASDOT:
	MOVE.L	D0,-(SP)
	MOVE.L	A0,-(SP)
	RTS
TONUM_DOT:
	MOVE.L	D3,D0				# IF WE HIT A DOT, DROP EVERYTHING BUT LAST
	ADDQ.B	#1,D4
	MOVE.W	#2,D2				# RESET POWER IDX TO 10POW1
	JMP	TONUM_RW			# VAL. AS TO TRUNCATE TO 1DP.
ERR_TOOBIG:
	PEA	STOOBIG
	JSR	PRNBUF
	DC.W	$FF00
*PRINT DEBUG STRING, ENSURING D0,D1,A1 ARE PRESERVED
PDBG:
	MOVEM.L	D0-D4/A0-A3,-(SP)
	PEA	DBG
	JSR	PRNBUF
	MOVEM.L	(SP)+,D0-D4/A0-A3
	RTS
*TAKES LONG NUMBER, ADDRESS OF DEST BUFF ON STACK
TOSTR:
	MOVEA.L (SP)+,A0
	MOVEA.L (SP)+,A1
	MOVE.L	(SP)+,D0
	MOVE.L	A0,-(SP)
	MOVE.B	#0,-(SP)			#MARKER. SEE PUSH TO STACK BELOW.
TOSTR_LOOP:
	DIVU	#10,D0
	MOVE.L	D0,D1
	AND.L	#$FFFF,D0			#GET RID OF REMAINDER FOR NEXT DIVU
	SWAP	D1
	ADD.W	#48,D1
	MOVE.B	D1,-(SP)			#WE NEED TO REVERSE IT, SO PUSH TO STACK FIRST
	TST.W	D0
	BNE	TOSTR_LOOP
TOSTR_POPS:
	MOVE.B	(SP)+,(A1)+
	BNE	TOSTR_POPS			#XFER STACK TO BUF UNTIL 0 HIT
	SUBQ.L	#2,A1
	MOVE.B	(A1),D0
	MOVE.B	#46,(A1)+
	MOVE.B	D0,(A1)+
	MOVE.B	#0,(A1)				#NULL TERM
	RTS
FMUL:
	MULU	D1,D0				#FF 1DP MULTIPLY D0 AND D1, RET IN D0
	DIVU	#10,D0
	SWAP	D0
	CMPI.W	#5,D0
	BLT	FMUL_OK
	CLR.W	D0
	SWAP	D0
	ADDQ.L	#1,D0
	RTS
FMUL_OK:
	CLR.W	D0
	SWAP	D0
	RTS
	
ENDL:
	.DC.B	$0D,$0A,0
REQ:
	.DC.B	'ENTER VALUE IN KG',$0D,$0A,0
RES:
	.DC.B	'%.2f KG IN LB IS %.2F'
INBUF_PARAM:
	.DC.B	5,0
INBUF:
	.DS.B	6
RESBUF:
	.DS.B	7
TSTBUF:
	.DC.B	'500                        ',$0D,$0A,0
DBG:
	.DC.B	'HIT',$0D,$0A,0
LB:
	.DC.B	'LB',0
KG_IS:
	.DC.B	'KG IS ',0
STOOBIG:
	.DC.B	'INPUT TOO BIG!',$0D,$0A,0
	.ALIGN 2
POWS:
	.DC.W	1,10,100,1000,10000