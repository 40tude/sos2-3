/* Copyright (C) 2004  The SOS Team
   Copyright (C) 1999  Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
   USA. 
*/

/* Include definitions of the multiboot standard */
#include <bootstrap/multiboot.h>
#include <hwcore/idt.h>
#include <hwcore/gdt.h>
#include <hwcore/irq.h>
#include <hwcore/exception.h>
#include <hwcore/i8254.h>
#include <sos/klibc.h>
#include <sos/assert.h>
#include <drivers/x86_videomem.h>
#include <drivers/bochs.h>


/* Helper function to display each bits of a 32bits integer on the
   screen as dark or light carrets */
static void display_bits(unsigned char row, unsigned char col,
			 unsigned char attribute,
			 sos_ui32_t integer)
{
  int i;
  /* Scan each bit of the integer, MSb first */
  for (i = 31 ; i >= 0 ; i--)
    {
      /* Test if bit i of 'integer' is set */
      int bit_i = (integer & (1 << i));
      /* Ascii 219 => dark carret, Ascii 177 => light carret */
      unsigned char ascii_code = bit_i?219:177;
      sos_x86_videomem_putchar(row, col++,
			       attribute,
			       ascii_code);
    }
}


/* Clock IRQ handler */
static void clk_it(int intid)
{
  static sos_ui32_t clock_count = 0;

  display_bits(0, 48,
	       SOS_X86_VIDEO_FG_LTGREEN | SOS_X86_VIDEO_BG_BLUE,
	       clock_count);
  clock_count++;

}

/* Division by zero exception handler */
static void divide_ex(int exid)
{
  static sos_ui32_t div_count = 0;
  display_bits(0, 0,
	       SOS_X86_VIDEO_FG_LTRED | SOS_X86_VIDEO_BG_BLUE,
	       div_count);
  div_count++;
}

/* The C entry point of our operating system */
void sos_main(unsigned long magic, unsigned long addr)
{
  unsigned i;

  /* Grub sends us a structure, called multiboot_info_t with a lot of
     precious informations about the system, see the multiboot
     documentation for more information. */
  multiboot_info_t *mbi;
  mbi = (multiboot_info_t *) addr;

  /* Setup bochs and console, and clear the console */
  sos_bochs_setup();

  sos_x86_videomem_setup();
  sos_x86_videomem_cls(SOS_X86_VIDEO_BG_BLUE);

  /* Greetings from SOS */
  if (magic == MULTIBOOT_BOOTLOADER_MAGIC)
    /* Loaded with Grub */
    sos_x86_videomem_printf(1, 0,
			    SOS_X86_VIDEO_FG_YELLOW | SOS_X86_VIDEO_BG_BLUE,
			    "Welcome From GRUB to %s%c RAM is %dMB (upper mem = 0x%x kB)",
			    "SOS", ',',
			    (unsigned)(mbi->mem_upper >> 10) + 1,
			    (unsigned)mbi->mem_upper);
  else
    /* Not loaded with grub */
    sos_x86_videomem_printf(1, 0,
			    SOS_X86_VIDEO_FG_YELLOW | SOS_X86_VIDEO_BG_BLUE,
			    "Welcome to SOS");

  sos_bochs_putstring("Message in a bochs\n");

  /* Setup CPU segmentation and IRQ subsystem */
  sos_gdt_setup();
  sos_idt_setup();

  /* Setup SOS IRQs and exceptions subsystem */
  sos_exceptions_setup();
  sos_irq_setup();

  /* Configure the timer so as to raise the IRQ0 at a 100Hz rate */
  sos_i8254_set_frequency(100);


  /* Binding some HW interrupts and exceptions to software routines */
  sos_irq_set_routine(SOS_IRQ_TIMER,
			    clk_it);
  sos_exception_set_routine(SOS_EXCEPT_DIVIDE_ERROR,
			    divide_ex);
  /* Enabling the HW interrupts here, this will make the timer HW
     interrupt call our clk_it handler */
  asm volatile ("sti\n");

  /* Raise a rafale of 'division by 0' exceptions. All this code is
     not really needed (equivalent to a bare "i=1/0;"), except when
     compiling with -O3: "i=1/0;" is considered dead code with gcc
     -O3. */
  i = 10;
  while (1)
    {
      /* Stupid function call to fool gcc optimizations */
      sos_bochs_printf("i = 1 / %d...\n", i);
      i = 1 / i;
    }

  /* Will never print this since the "divide by zero" exception always
     returns to the faulting instruction (see Intel x86 doc vol 3,
     section 5.12), thus re-evaluating the "divide-by-zero" exprssion
     and raising the "divide by zero" exception again and again... */
  sos_x86_videomem_putstring(2, 0,
			     SOS_X86_VIDEO_FG_LTRED | SOS_X86_VIDEO_BG_BLUE,
			     "Invisible");

  return;
}
