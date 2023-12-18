CC=gcc
CFLAGS  = -Wall -nostdlib -nostdinc -ffreestanding -DKERNEL_SOS
LDFLAGS = --warn-common
OBJECTS = bootstrap/multiboot.o					\
          hwcore/idt.o hwcore/gdt.o				\
	  hwcore/exception.o hwcore/exception_wrappers.o	\
	  hwcore/irq.o hwcore/irq_wrappers.o hwcore/i8259.o	\
	  hwcore/i8254.o drivers/x86_videomem.o drivers/bochs.o	\
	  sos/klibc.o sos/main.o

KERNEL_OBJ   = sos.elf
MULTIBOOT_IMAGE = fd.img
PWD := $(shell pwd)

# Main target
all: $(MULTIBOOT_IMAGE)

$(MULTIBOOT_IMAGE): $(KERNEL_OBJ)
	./support/build_image.sh $@ $<

$(KERNEL_OBJ): $(OBJECTS) ./support/sos.lds
	$(LD) $(LDFLAGS) -T ./support/sos.lds -o $@ $(OBJECTS)
	-nm -C $@ | cut -d ' ' -f 1,3 > sos.map

-include .mkvars

# Create objects from C source code
%.o: %.c
	$(CC) -I$(PWD) -c $< $(CFLAGS) -o $@

# Create objects from assembler (.S) source code
%.o: %.S
	$(CC) -I$(PWD) -c $< $(CFLAGS) -DASM_SOURCE=1 -o $@

# Clean directory
clean:
	$(RM) *.img *.o mtoolsrc *~ menu.txt *.img *.elf *.bin *.map
	$(RM) *.log *.out bochs*
	$(RM) bootstrap/*.o bootstrap/*~
	$(RM) drivers/*.o drivers/*~
	$(RM) hwcore/*.o hwcore/*~
	$(RM) sos/*.o sos/*~
	$(RM) support/*~
	$(RM) extra/*~
