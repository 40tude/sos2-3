/* Copyright (C) 2004  David Decotigny
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
#include <hwcore/ioports.h>
#include <sos/klibc.h>

#include "bochs.h"

/* This is a special hack that is only useful when running the
   operating system under the Bochs emulator.  */
#define SOS_BOCHS_IOPORT 0xe9

sos_ret_t sos_bochs_setup(void)
{
  return SOS_OK;
}


#define sos_bochs_putchar(chr) \
    outb((chr), SOS_BOCHS_IOPORT)

sos_ret_t sos_bochs_putstring(const char* str)
{
  for ( ; str && (*str != '\0') ; str++)
    sos_bochs_putchar(*str);

  return SOS_OK;
}


sos_ret_t sos_bochs_puthex(unsigned val, int nbytes)
{
  unsigned c;

#define BOCHS_PRTHEX(q) \
  ({ unsigned char r; if ((q) >= 10) r='a'+(q)-10; \
     else r='0'+(q); sos_bochs_putchar(r); })

  switch (nbytes)
    {
    case 4:
      c = (val >> 24) & 0xff;
      BOCHS_PRTHEX((c >> 4)&0xf);
      BOCHS_PRTHEX(c&0xf);
    case 3:
      c = (val >> 16) & 0xff;
      BOCHS_PRTHEX((c >> 4)&0xf);
      BOCHS_PRTHEX(c&0xf);
    case 2:
      c = (val >> 8) & 0xff;
      BOCHS_PRTHEX((c >> 4)&0xf);
      BOCHS_PRTHEX(c&0xf);
    case 1:
      c = val & 0xff;
      BOCHS_PRTHEX((c >> 4)&0xf);
      BOCHS_PRTHEX(c&0xf);
    }

  return SOS_OK;
}


sos_ret_t sos_bochs_hexdump(const void* addr, int nbytes)
{
  int offs;
  for (offs = 0 ; offs < nbytes ; offs++)
    {
      const unsigned char *c;
      
      if ((offs % 16) == 0)
	{
	  sos_bochs_putstring("0x");
	  sos_bochs_puthex(offs, 4);
	}
      
      if ((offs % 8) == 0)
	sos_bochs_putstring("   ");

      c = (const unsigned char*)(addr + offs);
      sos_bochs_puthex(*c, 1);
      sos_bochs_putstring(" ");
      
      if (((offs + 1) % 16) == 0)
        sos_bochs_putstring("\n");
    }

  if (offs % 16)
    sos_bochs_putstring("\n");

  return SOS_OK;
}


sos_ret_t sos_bochs_printf(const char *format, /* args */...)
{
  char buff[256];
  va_list ap;
  
  va_start(ap, format);
  vsnprintf(buff, sizeof(buff), format, ap);
  va_end(ap);
  
  return sos_bochs_putstring(buff);
}
