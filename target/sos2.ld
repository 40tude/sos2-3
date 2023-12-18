ENTRY(start)

SECTIONS {
    . = 2M;

    .zoubida :
    {
      /* ensure that the multiboot header is at the beginning */
      *(.multiboot_header)
    }

    .text : ALIGN(CONSTANT(MAXPAGESIZE)) 
    {
      /* Defines a symbol '__b_kernel to mark the start of the kernel code/data */
      __b_kernel = .;

      *(.text)
    }
    
    .data : ALIGN(CONSTANT(MAXPAGESIZE)) 
    {   
      *(.data*) 
    }

    .rodata : ALIGN(CONSTANT(MAXPAGESIZE)) 
    {   
      *(.rodata*)
    }

    .bss : ALIGN(CONSTANT(MAXPAGESIZE)) 
    {   
      *(.bss)
      /* *(COMMON) */
    }

    /* We take note of the end of the kernel */
    __e_kernel = .;

    /DISCARD/ :{
      *(.comment)
    }
}
