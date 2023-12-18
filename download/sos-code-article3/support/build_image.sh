#!/bin/sh
# Copyright (C) 2003, David Decotigny

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
   
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA. 

# 1) What does it do ?
#
#  1) Check where Grub is installed (lookup_grub)
#  2) Assign some local variables using the shell script arguments.
#      a) Argument 1 : the destination  (either a file or a drive, like a:)
#      b) Argument 2 : the loader (i.e kernel)
#      c) Argument 3 : options passed to the loader
#      d) Argument 4 : the modules (that can be loaded optionally by Grub)
#  3) Test whether destination is a drive or a file
#  4) Create the directory structure inside the drive
#  5) Copy the loader in the drive
#  6) Generate the 'menu.txt' file used by Grub to generate the boot menu
#  7) Copy all modules
#  8) Copy the menu.txt file
#
# 2) Why is it so complex ?
#    Because it must support various Grub/mtools installations and versions
#
# In fact, this shell script is used in the KOS (kos.enix.org)
# project. This operating system consists in a loader and many many
# modules that are linked together at boot time. It is much more
# complex that a simple monolithic kernel.
#
# For your simple monolithic kernel, you only need to give argument 1
# and 2.

print_usage () {
  echo "Usage: $0 [X:|image] path/to/loader option path/to/modules..."
  echo "       where X: is a valid floppy drive on your computer"
  echo "       where image is any file name"
  exit 1
}

grub_dirs_common="/usr/local/share/grub/i386-freebsd /usr/local/share/grub/i386-pc /usr/share/grub/i386-pc /usr/lib/grub/i386-pc /usr/local/grub /usr/share/grub/i386-redhat /usr/local/src/grub-0.5.94 $HOME/share/grub/i386-pc/"
sbin_grub_path="/usr/local/sbin /usr/sbin /sbin $HOME/sbin"

PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin
export PATH

MTOOLSRC=mtoolsrc
export MTOOLSRC

# Redefined variables
FLOPPY_DRIVE=A:
IMG_FNAME=fd.img

##
## Format disk image
##
init_image () {
  echo "Initialize disk image $IMG_FILE..."
  if [ ! -f $IMG_FNAME ] ; then
    dd if=/dev/zero of=$IMG_FNAME bs=18k count=80 1>/dev/null 2>&1
  fi

  rm -f $MTOOLSRC
  echo "drive u: file=\"$IMG_FNAME\" 1.44M filter" > $MTOOLSRC

  if mformat U: ; then : ; else
    rm -f $MTOOLSRC
    echo "drive u: file=\"$IMG_FNAME\" 1.44M" > $MTOOLSRC
    if mformat U: ; then : ; else
      rm -f $MTOOLSRC
      echo "drive u: file=\"$IMG_FNAME\"" > $MTOOLSRC
      mformat U:
    fi
  fi
}


##
## Format (real) floppy disk
##
init_floppy () {
  echo "Formatting floppy..."
  mformat $FLOPPY_DRIVE || exit 1
}


lookup_grub () {
  # Look for a correct GRUBDIR
  for d in $grub_dirs_common ; do
    if [ -d $d ] ; then
      GRUBDIR=$d
      break
    fi
  done

  # Try to guess with locate
  if [ ! -d "$GRUBDIR" ] ; then
    GRUBDIR=`locate stage2 | head -1 | xargs dirname 2>/dev/null`
  fi

  # Look for a correct sbin/grub
  for d in $sbin_grub_path ; do
    if [ -x $d/grub ] ; then
      SBIN_GRUB=$d/grub
      break
    fi
  done

  if [ -d "$GRUBDIR" -a -x "$SBIN_GRUB" ] ; then 
    echo "Found correct grub installation in $GRUBDIR"
    echo "Found correct /sbin/grub at $SBIN_GRUB"
  else
    echo "Couldn't find a correct grub installation."
    exit 1
  fi
}

##
## setup_disk [drive]
## => setup disk directory structure / copy files
##
setup_disk () {
  echo "Setup destination disk..."

  mmd $1/boot
  mmd $1/boot/grub

  if [ -d $GRUBDIR/stage1 ] ; then
    mcopy $GRUBDIR/stage1/stage1 $1/boot/grub/
    mcopy $GRUBDIR/stage2/stage2 $1/boot/grub/
  else
    mcopy $GRUBDIR/stage1 $1/boot/grub/
    mcopy $GRUBDIR/stage2 $1/boot/grub/
  fi
  mmd $1/system
  mmd $1/modules

  $SBIN_GRUB --batch <<EOT 1>/dev/null 2>/dev/null || exit 1
device (fd0) $IMG_FNAME
install (fd0)/boot/grub/stage1 (fd0) (fd0)/boot/grub/stage2 p (fd0)/boot/grub/menu.txt
quit
EOT
}



#################################################
## Real start
##
#[ "$#" -lt 3 ] && print_usage

lookup_grub

dest="$1" ; shift
loader_fname="$1" ; shift
options="$1" ; shift
modules="$*"

# Init destination disk
case x$dest in
  x*:)
    drive=$dest
    IMG_FNAME=$dest
    FLOPPY_DRIVE=$dest
    init_floppy
    ;;
  x*) 
    drive=U:
    IMG_FNAME=$dest
    init_image
    ;;
esac

# Create directory structure
setup_disk $drive

# Copy the loader
mcopy -bo $loader_fname $drive/system/`basename $loader_fname`

# Generate the menu.txt file
rm -f menu.txt
cat <<EOF > menu.txt
timeout 0 
default 0
title  Simple OS
root   (fd0)
kernel /system/`basename $loader_fname` $options
EOF

# Copy the modules
for f in $modules ; do
    if [ ! -f $f ] ; then
	echo "ERROR: module $f not correctly compiled in."
	exit 1
    fi
    if ! mcopy -bo $f $drive/modules/`basename $f` ; then
	echo "ERROR: module $f could not be transferred to floppy."
	exit 1
    fi
    echo module /modules/`basename $f` >> menu.txt
done

# Transfers the menu.txt file to floppy
mcopy -bo menu.txt $drive/boot/grub/
