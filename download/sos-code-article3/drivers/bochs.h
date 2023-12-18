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
#ifndef _SOS_BOCHS_H_
#define _SOS_BOCHS_H_

/**
 * @file bochs.h
 *
 * If you compiled Bochs with the --enable-e9-hack, then any character
 * printed to the 0xE9 I/O port is printed to the xterm that is
 * running Bochs. This may appear to be a detail, but in fact, this
 * functionnality is *VERY* precious for debugging purposes. This
 * """driver""" handles this feature.
 */

#include <sos/errno.h>
#include <sos/types.h>

sos_ret_t sos_bochs_setup(void);

sos_ret_t sos_bochs_putstring(const char* str);

/** Print the least signficant 32 (nbytes == 4), 24 (nbytes == 3), 16
    (nbytes == 2) or 8 (nbytes == 1) bits of val in hexadecimal. */
sos_ret_t sos_bochs_puthex(unsigned val, int nbytes);

/** hexdump-style pretty printing */
sos_ret_t sos_bochs_hexdump(const void* addr, int nbytes);

/**
 * Print the formatted string. Very restricted version of printf(3):
 * 1/ can print max 255 chars, 2/ supports only %d/%i, %c, %s, %x
 * without any support for flag charachters (eg %08x).
 */
sos_ret_t sos_bochs_printf(const char *format, /* args */...)
     __attribute__ ((format (printf, 1, 2)));

#endif
