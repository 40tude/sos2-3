CC      = gcc
CFLAGS  = -Wall -nostdlib -nostdinc -ffreestanding -m32 -fno-asynchronous-unwind-tables
LDFLAGS = --warn-common -melf_i386 # --no-warn-rwx-segments
# --no-warn-rwx-segments : https://github.com/raspberrypi/pico-sdk/issues/1029

PWD     := $(shell pwd)

ASM_SOURCE_FILES := $(shell find bootstrap -name *.asm)
ASM_OBJECT_FILES := $(patsubst bootstrap/%.asm, build/%.o, $(ASM_SOURCE_FILES))

SOS_C_SOURCE_FILES := $(shell find sos -name *.c)
SOS_C_OBJECT_FILES := $(patsubst sos/%.c, build/%.o, $(SOS_C_SOURCE_FILES))

DRIVERS_C_SOURCE_FILES := $(shell find drivers -name *.c)
DRIVERS_C_OBJECT_FILES := $(patsubst drivers/%.c, build/%.o, $(DRIVERS_C_SOURCE_FILES))

OBJECT_FILES := $(DRIVERS_C_OBJECT_FILES) $(SOS_C_OBJECT_FILES) ${ASM_OBJECT_FILES}
#$(info $$OBJECT_FILES : ${OBJECT_FILES})

SOS_BIN = target/iso/boot/sos2.bin
SOS_MULTIBOOT_ISO = dist/sos2.iso

sos2 : $(SOS_MULTIBOOT_ISO)

$(SOS_MULTIBOOT_ISO): $(SOS_BIN)
	grub-mkrescue -d /usr/lib/grub/i386-pc -o dist/sos2.iso target/iso

$(SOS_BIN) : $(OBJECT_FILES)
	mkdir -p dist
	$(LD) $(LDFLAGS) -T ./target/sos2.ld -o $(SOS_BIN) $^

$(ASM_OBJECT_FILES): build/%.o : bootstrap/%.asm
	mkdir -p $(dir $@) && \
	nasm -f elf32 $(patsubst build/%.o, bootstrap/%.asm, $@) -o $@

$(DRIVERS_C_OBJECT_FILES): build/%.o : drivers/%.c
	mkdir -p $(dir $@) && \
	$(CC) -I$(PWD) -c $(CFLAGS)  $(patsubst  build/%.o, drivers/%.c, $@) -o $@

$(SOS_C_OBJECT_FILES): build/%.o : sos/%.c
	mkdir -p $(dir $@) && \
	$(CC) -I$(PWD) -c $(CFLAGS)  $(patsubst  build/%.o, sos/%.c, $@) -o $@

.PHONY: clean
clean:
	$(RM) -rf dist
	$(RM) $(SOS_BIN)
	$(RM) build/*.o build/*~
