.section .mytest,"ax",@progbits

.global my_test_asm

__SP_H__ = 0x3e
__SP_L__ = 0x3d

; my_test_asm:
my_test_asm:
	push r28	 ;
	push r29	 ;
	in r28,__SP_L__	 ;
	in r29,__SP_H__	 ;
.L__stack_usage = 2
	rcall SP_EraseApplicationPage_2
	rcall SP_WaitForSPM_2

; turn on the led
	ldi r24,0	 ;  _1
	ldi r25,lo8(6)	 ;  _1,
	ldi r18,lo8(32)	 ;  tmp43,
	movw r30,r24	 ; , _1
	std Z+5,r18	 ;  _1->OUTSET, tmp43
	nop
	nop
	pop r29	 ;
	pop r28	 ;
	ret


	; push r28	 ;
	; push r29	 ;
	; in r28,__SP_L__	 ;
	; in r29,__SP_H__	 ;
; /* prologue: function */
; /* frame size = 0 */
; /* stack size = 2 */
; .L__stack_usage = 2
	; ldi r24,0	 ;  _1
	; ldi r25,lo8(6)	 ;  _1,
	; ldi r18,lo8(32)	 ;  tmp43,
	; movw r30,r24	 ; , _1
	; std Z+5,r18	 ;  _1->OUTSET, tmp43
	; nop
; /* epilogue start */
	; pop r29	 ;
	; pop r28	 ;
	; ret

#include <avr/io.h>
;#include "Flash_Defines.h"

/* Define the size of the flash page if not defined in the header files. */
#ifndef APP_SECTION_PAGE_SIZE
	#error  APP_SECTION_PAGE_SIZE must be defined if not defined in header files.
	//#define APP_SECTION_PAGE_SIZE 512
#endif /*APP_SECTION_PAGE_SIZE*/

/* Defines not yet included in header file. */
#define NVM_CMD_NO_OPERATION_gc (0x00<<0)	// Noop/Ordinary LPM
#define NVM_CMD_READ_USER_SIG_ROW_gc (0x01<<0)	// Read user signature row
#define NVM_CMD_READ_CALIB_ROW_gc (0x02<<0)	// Read calibration row
#define NVM_CMD_READ_EEPROM_gc (0x06<<0)	// Read EEPROM
#define NVM_CMD_READ_FUSES_gc (0x07<<0)	// Read fuse byte
#define NVM_CMD_WRITE_LOCK_BITS_gc (0x08<<0)	// Write lock bits
#define NVM_CMD_ERASE_USER_SIG_ROW_gc (0x18<<0)	// Erase user signature row
#define NVM_CMD_WRITE_USER_SIG_ROW_gc (0x1A<<0)	// Write user signature row
#define NVM_CMD_ERASE_APP_gc (0x20<<0)	// Erase Application Section
#define NVM_CMD_ERASE_APP_PAGE_gc (0x22<<0)	// Erase Application Section page
#define NVM_CMD_LOAD_FLASH_BUFFER_gc (0x23<<0)	// Load Flash page buffer
#define NVM_CMD_WRITE_APP_PAGE_gc (0x24<<0)	// Write Application Section page
#define NVM_CMD_ERASE_WRITE_APP_PAGE_gc (0x25<<0)	// Erase-and-write Application Section page
#define NVM_CMD_ERASE_FLASH_BUFFER_gc (0x26<<0)	// Erase/flush Flash page buffer
#define NVM_CMD_ERASE_BOOT_PAGE_gc (0x2A<<0)	// Erase Boot Section page
#define NVM_CMD_WRITE_BOOT_PAGE_gc (0x2C<<0)	// Write Boot Section page
#define NVM_CMD_ERASE_WRITE_BOOT_PAGE_gc (0x2D<<0)	// Erase-and-write Boot Section page
#define NVM_CMD_ERASE_EEPROM_gc (0x30<<0)	// Erase EEPROM
#define NVM_CMD_ERASE_EEPROM_PAGE_gc (0x32<<0)	// Erase EEPROM page
#define NVM_CMD_LOAD_EEPROM_BUFFER_gc (0x33<<0)	// Load EEPROM page buffer
#define NVM_CMD_WRITE_EEPROM_PAGE_gc (0x34<<0)	// Write EEPROM page
#define NVM_CMD_ERASE_WRITE_EEPROM_PAGE_gc (0x35<<0)	// Erase-and-write EEPROM page
#define NVM_CMD_ERASE_EEPROM_BUFFER_gc (0x36<<0)	// Erase/flush EEPROM page buffer
#define NVM_CMD_APP_CRC_gc (0x38<<0)	// Generate Application section CRC
#define NVM_CMD_BOOT_CRC_gc (0x39<<0)	// Generate Boot Section CRC
#define NVM_CMD_FLASH_RANGE_CRC_gc (0x3A<<0)	// Generate Flash Range CRC
#define CCP_SPM_gc (0x9D<<0)	// SPM Instruction Protection
#define CCP_IOREG_gc (0xD8<<0)	// IO Register Protection


; ---
; This routine erases the page at address R25:R24:R23:R22 in the application
; section. The address can point anywhere inside the page.
;
; Input:
;     R25:R24:R23:R22 - Byte address into Flash page.
;
; Returns:
;     Nothing.
; ---

SP_EraseApplicationPage_2:
	in	r19, RAMPZ                      ; Save RAMPZ, which is restored in SP_CommonSPM.
	out	RAMPZ, r24                      ; Load RAMPZ with the MSB of the address.
	movw    r24, r22                        ; Move low bytes for ZH:ZL to R25:R24
	ldi	r20, NVM_CMD_ERASE_APP_PAGE_gc  ; Prepare NVM command in R20.
	jmp	SP_CommonSPM_2                    ; Jump to common SPM code.


; This routine wait for the SPM to finish and clears the command register.
;
; Note that this routine is blocking, and will halt any execution until the SPM
; is finished.
;
; Input:
;     Nothing.
;
; Returns:
;     Nothing.
; ---

SP_WaitForSPM_2:
	lds	r18, NVM_STATUS     ; Load the NVM Status register.
	sbrc	r18, NVM_NVMBUSY_bp ; Check if bit is cleared.
	rjmp	SP_WaitForSPM_2     ; Repeat check if bit is not cleared.
	clr	r18
	sts	NVM_CMD, r18        ; Clear up command register to NO_OPERATION.
	ret

; ---
; This routine is called by several other routines, and contains common code
; for executing an SPM command, including the return statement itself.
;
; If the operation (SPM command) requires the R1:R0 registers to be
; prepared, this must be done before jumping to this routine.
;
; Note that you must define "-Wl,--section-start=.BOOT=0x020000" for the
; linker to place this function in the boot section with the correct address.
;
; Input:
;     R1:R0    - Optional input to SPM command.
;     R25:R24  - Low bytes of Z pointer.
;     R20      - NVM Command code.
;
; Returns:
;     Nothing.
; ---

SP_CommonSPM_2:
	movw	ZL, r24          ; Load R25:R24 into Z.
	sts	NVM_CMD, r20     ; Load prepared command into NVM Command register.
	ldi	r18, CCP_SPM_gc  ; Prepare Protect SPM signature in R18
	sts	CCP, r18         ; Enable SPM operation (this disables interrupts for 4 cycles).
	spm                      ; Self-program.
	clr	r1               ; Clear R1 for GCC _zero_reg_ to function properly.
	out	RAMPZ, r19       ; Restore RAMPZ register.
	ret

.section .test_data,"a",@progbits
	.dc.b 0x00
	.dc.b 0x11
	.dc.b 0x00
	.dc.b 0x11
	.dc.b 0x00
	.dc.b 0x11
	.dc.b 0x00
	.dc.b 0x11
	.dc.b 0x00
	.dc.b 0x11
	.dc.b 0x00
	.dc.b 0x11
