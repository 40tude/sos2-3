; nasm -f elf32 hwcore/irq_wrappers.asm -o build/irq_wrappers.o

; Address of the table of handlers (defined in irq.c)
extern sos_irq_handler_array

; Address of the table of wrappers (defined below, and shared with irq.c 
global sos_irq_wrapper_array

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

%define Label(id)     sos_irq_wrapper_ %+ id

section .text

; Handlers for the IRQ of Master PIC (0...7)
%assign id 0
%rep    8 
  align 4 						                ; NOP by default
  Label(id):                          ; sos_irq_wrapper_0 ... sos_irq_wrapper_7
    push   0x0                        ; Fake error code
    push   ebp                        ; Backup the actual context
    mov    ebp,esp
    Push_All
    mov    al,0x20                    ; Send EOI to PIC. See Intel 8259 datasheet 
    out    0x20,al
    push   id                         ; Call the handler with IRQ number as argument                                      
    lea    edi, sos_irq_handler_array
    call   [edi + 4*id] 
    add    esp,0x4
    Pop_All                           ; Restore context
    add    esp, 0x4                   ; Remove fake error code
    iret
	%assign id id+1
%endrep

; Handlers for the IRQ of Slave PIC (8...15)
%assign id 8
%rep    8
  align 4 						                ; NOP by default
  Label(id):                          ; sos_irq_wrapper_8 ... sos_irq_wrapper_15
    push   0x0                        ; Fake error code
    push   ebp                        ; Backup the actual context
    mov    ebp,esp
    Push_All
    mov    al,0x20                    ; Send EOI to PIC. See Intel 8259 datasheet 
    out    0xa0,al 
    out    0x20,al
    push   id                         ; Call the handler with IRQ number as argument
    lea    edi, sos_irq_handler_array
    call   [edi + 4*id] 
    add    esp,0x4
    Pop_All                           ; Restore the context
    add    esp,0x4                    ; Remove fake error code
    iret
	%assign id id+1
%endrep

; Build sos_irq_wrapper_array, shared with irq.c 
section .rodata
align 32, db 0x0
sos_irq_wrapper_array:
%assign id 0
%rep    16              
	dd Label(id)        	              ; sos_irq_wrapper_0 ... sos_irq_wrapper_15
	%assign id id+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits             ; https://wiki.gentoo.org/wiki/Hardened/GNU_stack_quickstart
                                                                    ; https://stackoverflow.com/questions/73435637/how-can-i-fix-usr-bin-ld-warning-trap-o-missing-note-gnu-stack-section-imp