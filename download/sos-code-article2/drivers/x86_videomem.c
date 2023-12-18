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
#include <sos/klibc.h>
#include <hwcore/ioports.h>

#include "x86_videomem.h"

/* The text video memory starts at address 0xB8000. Odd bytes are the
   ASCII value of the character, even bytes are attribute for the
   preceding character. */
#define VIDEO   0xb8000


/* Console screen size */
#define LINES   25
#define COLUMNS 80


/** The structure of a character element in the video memory. @see
    http://webster.cs.ucr.edu/AoA DOS edition chapter 23 */
typedef struct {
  unsigned char character;
  unsigned char attribute;
} __attribute__ ((packed)) x86_video_mem[LINES*COLUMNS];



/** The base pointer for the video memory */
static volatile x86_video_mem *video = (volatile x86_video_mem*)VIDEO;

sos_ret_t sos_x86_videomem_setup(void)
{
  /*
   * Hide cursor. @see Ralf Brown's interrupt (and port) list
   * http://www-2.cs.cmu.edu/~ralf/files.html
   */
#define CRT_REG_INDEX 0x3d4
#define CRT_REG_DATA  0x3d5

  /* CRT index port => ask for access to register 0xa ("cursor
     start") */
  outb(0x0a, CRT_REG_INDEX);

  /* (RBIL Tables 708 & 654) CRT Register 0xa => bit 5 = cursor OFF */
  outb(1 << 5, CRT_REG_DATA);

  return SOS_OK;
}


sos_ret_t sos_x86_videomem_cls(unsigned char attribute)
{
  /* Clears the screen */
  int i;
  for(i = 0 ; i < LINES*COLUMNS ; i++)
    {
      (*video)[i].character = 0;
      (*video)[i].attribute = attribute;
    }

  return SOS_OK;  
}


sos_ret_t sos_x86_videomem_putstring(unsigned char row, unsigned char col,
				     unsigned char attribute,
				     const char *str)
{
  unsigned video_offs = row*COLUMNS + col;

  if (video_offs >= LINES*COLUMNS)
    return -SOS_EINVAL;
  
  for ( ; str && *str && (video_offs < LINES*COLUMNS) ; str++, video_offs++)
    {
      (*video)[video_offs].character = (unsigned char)*str;
      (*video)[video_offs].attribute = attribute;
    }

  return SOS_OK;
}


sos_ret_t sos_x86_videomem_putchar(unsigned char row, unsigned char col,
				   unsigned char attribute,
				   unsigned char c)
{
  unsigned video_offs = row*COLUMNS + col;

  if (video_offs >= LINES*COLUMNS)
    return -SOS_EINVAL;
  
  (*video)[video_offs].character = c;
  (*video)[video_offs].attribute = attribute;

  return SOS_OK;
}


sos_ret_t sos_x86_videomem_printf(unsigned char row, unsigned char col,
				  unsigned char attribute,
				  const char *format, /* args */...)
{
  char buff[256];
  va_list ap;
  
  va_start(ap, format);
  vsnprintf(buff, sizeof(buff), format, ap);
  va_end(ap);
  
  return sos_x86_videomem_putstring(row, col, attribute, buff);
}
