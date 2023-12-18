/* Copyright (C) 2004, David Decotigny

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

SECTIONS
{
    /* ***********************************************
     * The bootsector is here. We link it against the remaining of the kernel
     * in order to automatically figure out its size that must be loaded
     * from file to memory (see the load_size definition below)
     */

    /* If we use one, we put the boot sector here. We don't set its
     * address to 0x7c000 (aka 0x7c00:0), since it reloads itself to
     * 0x9f000, causing the 0x7c000 address to be meaningless too. So we
     * chose to pretend that the address is 0x0, and to make a little
     * address arithmetic in bootsect.S */
    .bootsect 0x0 :
    {
      /* The code for the boot sector goes here */
      *(.bootsect);

      /* The load_size symbol contains the size of the area (in
       * sectors, aka 512 Bytes) that the boot sector should copy from
       * the disk. The bss section is not included since it uses 0
       * bytes on disk */
      load_size = .;
      LONG((__e_load - __b_load + 511) >> 9);
      /* ---> This is equivalent to ceil( (__e_load - __b_load) / 512 ) */

      /* At offsets 511 and 512, we set the boot sector signature (AA55h) */
      . = 0x1fe;
      SHORT(0xAA55);
    }
}


/* This is to avoid a cut/paste here. Please notice that a multiboot
 * section WILL be inserted, which is NOT mandatory (we could have
 * removed it without getting into trouble). Please note however that
 * the *.bin files will NOT be multiboot compatible (they are not in ELF
 * format): they are expected to be directly booted by the BIOS (or
 * by the "chainloader" command of Grub). */
INCLUDE ../support/sos.lds

/* We overload the entry set in sos.lds, just to avoid an ld warning */
ENTRY(sos_main);
