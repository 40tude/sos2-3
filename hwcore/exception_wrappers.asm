; nasm -f elf32 hwcore/exception_wrappers.asm -o build/exception_wrappers.o

; Address of the table of handlers (defined in exception.c) 
extern sos_exception_handler_array

; Address of the table of wrappers (defined below), and shared with exception.c 
global sos_exception_wrapper_array

%macro Push_All 0
	push   edi
	push   esi
	push   edx
	push   ecx
	push   ebx
	push   eax
	sub    esp,0x2
	push  ss         
	push  ds         
	push  es         
	push  fs         
	push  gs         
%endmacro

%macro Pop_All 0
	pop    gs         
	pop    fs         
	pop    es         
	pop    ds         
	pop    ss         
	add    esp,0x2
	pop    eax
	pop    ebx
	pop    ecx
	pop    edx
	pop    esi
	pop    edi
	pop    ebp
%endmacro

%define Label(id)     sos_exception_wrapper_ %+ id

section .text

; Wrappers for exceptions without error code
%macro Exception_No_Err 1
    align 4                       ; NOP by default
    Label(%1):
    push   0x0                    ; Fake error code
    push   ebp                    ; Backup the actual context
    mov    ebp,esp
    Push_All
    push %1                       ; Call the handler with exception number as argument */
    lea  edi, sos_exception_handler_array
    call   [edi + 4*%1] 
    add    esp,0x4
    Pop_All                       ; Restore context
    add    esp, 0x4               ; Remove fake error code
    iret
%endmacro

; Wrappers for exceptions with error code
%macro Exception_With_Err 1
  align 4 						            ; NOP by default
  Label(%1):
  push   ebp                      ; Backup the context 
  mov    ebp,esp
  Push_All
  push   %1                       ; Call the handler with exception number as argument
  lea    edi, sos_exception_handler_array
  call   [edi + 4*%1] 
  add    esp,0x4
  Pop_All                         ; Restore context
  add    esp,0x4                  ; Error code isn't compatible with iretd 
  iret
%endmacro

	
; Wrappers for exceptions without error code from [0 to 7]
%define SOS_EXCEPT_DIVIDE_ERROR                  0         ; No error code
;%define SOS_EXCEPT_DEBUG                         1         ; No error code
;%define SOS_EXCEPT_NMI_INTERRUPT                 2         ; No error code
;%define SOS_EXCEPT_BREAKPOINT                    3         ; No error code
;%define SOS_EXCEPT_OVERFLOW                      4         ; No error code
;%define SOS_EXCEPT_BOUND_RANGE_EXCEDEED          5         ; No error code
;%define SOS_EXCEPT_INVALID_OPCODE                6         ; No error code
;%define SOS_EXCEPT_DEVICE_NOT_AVAILABLE          7         ; No error code
%assign id SOS_EXCEPT_DIVIDE_ERROR
%rep    8 
  Exception_No_Err id
  %assign id id+1
%endrep 


; Double fault handler not supported. We must define it since we
; define an entry for it in the sos_exception_wrapper_array. 
%define SOS_EXCEPT_DOUBLE_FAULT                  8         ; Yes (Zero)
%assign id SOS_EXCEPT_DOUBLE_FAULT 
align 4 						            ; NOP by default
Label(id):
Crash:	hlt
jmp Crash                       ; Machine halting


; Wrappers for exceptions without error code
%define SOS_EXCEPT_COPROCESSOR_SEGMENT_OVERRUN   9         ; No error code
%assign id SOS_EXCEPT_COPROCESSOR_SEGMENT_OVERRUN
Exception_No_Err id


; Wrappers for exceptions with error code from [10 to 14]
%define SOS_EXCEPT_INVALID_TSS                  10         ; Yes
; %define SOS_EXCEPT_SEGMENT_NOT_PRESENT          11         ; Yes
; %define SOS_EXCEPT_STACK_SEGMENT_FAULT          12         ; Yes
; %define SOS_EXCEPT_GENERAL_PROTECTION           13         ; Yes
; %define SOS_EXCEPT_PAGE_FAULT                   14         ; Yes
%assign id SOS_EXCEPT_INVALID_TSS
%rep    5 
  Exception_With_Err id
  %assign id id+1
%endrep 


; Wrappers for exceptions without error code from [15 to 16]
%define SOS_EXCEPT_INTEL_RESERVED_1             15         ; No error code
; %define SOS_EXCEPT_FLOATING_POINT_ERROR         16         ; No error code
%assign id SOS_EXCEPT_INTEL_RESERVED_1
%rep    2
  Exception_No_Err id
  %assign id id+1
%endrep 


; Wrappers for exceptions with error code
%define SOS_EXCEPT_ALIGNEMENT_CHECK             17         ; Yes (Zero)
%assign id SOS_EXCEPT_ALIGNEMENT_CHECK
Exception_With_Err id


;Wrappers for exceptions without error code from [18 to 31]
%define SOS_EXCEPT_MACHINE_CHECK                18         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_2             19         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_3             20         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_4             21         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_5             22         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_6             23         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_7             24         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_8             25         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_9             26         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_10            27         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_11            28         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_12            29         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_13            30         ; No error code
; %define SOS_EXCEPT_INTEL_RESERVED_14            31         ; No error code
%assign id SOS_EXCEPT_MACHINE_CHECK
%rep    14
  Exception_No_Err id
  %assign id id+1
%endrep 


; Build the sos_irq_wrapper_array, shared with interrupt.c 
section .rodata
align 32, db 0x0
sos_exception_wrapper_array:
%assign id 0
%rep    32              
  dd Label(id)            ; sos_exception_wrapper_0 ... sos_exception_wrapper_31
  %assign id id+1
%endrep


section .note.GNU-stack noalloc noexec nowrite progbits     ; https://wiki.gentoo.org/wiki/Hardened/GNU_stack_quickstart
                                                            ; https://stackoverflow.com/questions/73435637/how-can-i-fix-usr-bin-ld-warning-trap-o-missing-note-gnu-stack-section-imp