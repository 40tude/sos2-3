; readelf -S ./build/multiboot_header.o 
section .multiboot_header
header_start:
    dd 0xe85250d6                                                   ; magic number multiboot 2
    dd 0                                                            ; 32-bit protected mode of i386 
    dd header_end - header_start                                    ; header length
    dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start)) ; checksum

    ; insert optional multiboot tags here

    ; required end tag
    dw 0    ; type
    dw 0    ; flags
    dd 8    ; size
header_end:

section .note.GNU-stack noalloc noexec nowrite progbits             ; https://wiki.gentoo.org/wiki/Hardened/GNU_stack_quickstart
                                                                    ; https://stackoverflow.com/questions/73435637/how-can-i-fix-usr-bin-ld-warning-trap-o-missing-note-gnu-stack-section-imp
                                                                    
