ENTRY(start)

SECTIONS {
    . = 2M;

    .zoubida :
    {
      /* ensure that the multiboot header is at the beginning */
      *(.multiboot_header)
    }

    .text ALIGN(4096) :
    {
      *(.text)
    }
    
    .data . :
    {   
      *(.data*) 
    }

    .rodata . :
    {   
      *(.rodata*)
    }

    .bss SIZEOF(.rodata) + ADDR(.rodata) :
    {   
      *(.bss)
    }

    /DISCARD/ :{
      *(.comment)
    }
}
