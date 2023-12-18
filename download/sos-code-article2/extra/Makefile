OBJCOPY=objcopy

all: sos_qemu.img

-include ../.mkvars

# The image is the simple concatenation of the boot sector and the kernel
# It may be use in bochs or on a real floppy, but NOT in qemu (see below)
sos_bsect.img: bsect.bin sos.bin
	cat $^ > $@
	@echo "[31mYou can use the $@ image in bochs or on a real floppy (NOT qemu)[m"

# For qemu, the trick is to tell it we have *more* than 1440 sectors (720kB).
# Rtherwise the qemu disk geometry will be configured to be that of a 720kB
# floppy, while our boot sector assumes it to be 1.44MB
sos_qemu.img: sos_bsect.img
	# Padding with 0s after the bsect/kernel image
	cat $< /dev/zero | dd of=$@ bs=1k count=1440
	@echo "[31mYou can use the $@ image in qemu, bochs, or on a real floppy[m"

# we extract the boot sector from the main ELF binary
bsect.bin: sos_bsect.elf
	$(OBJCOPY) -v -O binary -j .bootsect $< $@

# we extract the kernel code from the main ELF binary
sos.bin: sos_bsect.elf
	$(OBJCOPY) -v -O binary -R .bootsect $< $@

# The main ELF binary contains the boot sector and the kernel code
# linked together (hence we deal with a SINGLE image that we split
# above) because they share some symbol definitions
sos_bsect.elf: bootsect.o compile_kernel
	$(LD) --warn-common -T ./sos_bsect.lds -o $@ \
		bootsect.o $(wildcard ../hwcore/*.o ../drivers/*.o ../sos/*.o)

compile_kernel:
	$(MAKE) -C ..

clean:
	$(RM) *.img *.elf *.bin *~ *.o *.out
