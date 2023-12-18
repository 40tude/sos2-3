CC      = gcc
CFLAGS  = -Wall -nostdlib -nostdinc -ffreestanding -m32 -fno-asynchronous-unwind-tables
LDFLAGS = --warn-common -melf_i386 

PWD     := $(shell pwd)

BOOTSTRAP_ASM := $(shell find bootstrap -name *.asm)
BOOTSTRAP_OBJ := $(patsubst bootstrap/%.asm, build/%.o, $(BOOTSTRAP_ASM))

SOS_SRC := $(shell find sos -name *.c)
SOS_OBJ := $(patsubst sos/%.c, build/%.o, $(SOS_SRC))

DRIVERS_SRC := $(shell find drivers -name *.c)
DRIVERS_OBJ := $(patsubst drivers/%.c, build/%.o, $(DRIVERS_SRC))

# HWCORE_S    := $(shell find hwcore -name *.S)
# HWCORE_OBJ0 := $(patsubst hwcore/%.S, build/%.o, $(HWCORE_S))
HWCORE_ASM  := $(shell find hwcore -name *.asm)
HWCORE_OBJ1 := $(patsubst hwcore/%.asm, build/%.o, $(HWCORE_ASM))
HWCORE_SRC  := $(shell find hwcore -name *.c)
HWCORE_OBJ2 := $(patsubst hwcore/%.c, build/%.o, $(HWCORE_SRC))
#HWCORE_OBJ  := ${HWCORE_OBJ0} ${HWCORE_OBJ1} ${HWCORE_OBJ2}
HWCORE_OBJ  := ${HWCORE_OBJ1} ${HWCORE_OBJ2}
# $(info $$HWCORE_OBJ : ${HWCORE_OBJ})

OBJECT_FILES := ${BOOTSTRAP_OBJ} $(DRIVERS_OBJ) ${HWCORE_OBJ} $(SOS_OBJ)  
# $(info $$OBJECT_FILES : ${OBJECT_FILES})

SOS_BIN = target/iso/boot/sos2.bin
SOS_MULTIBOOT_ISO = dist/sos2.iso

sos2 : $(SOS_MULTIBOOT_ISO)

$(SOS_MULTIBOOT_ISO): $(SOS_BIN)
	grub-mkrescue -d /usr/lib/grub/i386-pc -o dist/sos2.iso target/iso

$(SOS_BIN) : $(OBJECT_FILES)
	mkdir -p dist
	$(LD) $(LDFLAGS) -T ./target/sos2.ld -o $(SOS_BIN) $^

$(BOOTSTRAP_OBJ): build/%.o : bootstrap/%.asm
	mkdir -p $(dir $@) && \
	nasm -f elf32 $(patsubst build/%.o, bootstrap/%.asm, $@) -o $@

$(DRIVERS_OBJ): build/%.o : drivers/%.c
	mkdir -p $(dir $@) && \
	$(CC) -I$(PWD) -c $(CFLAGS)  $(patsubst  build/%.o, drivers/%.c, $@) -o $@




$(HWCORE_OBJ0): build/%.o : hwcore/%.S
	mkdir -p $(dir $@) && \
	$(CC) -I$(PWD) -c $(CFLAGS) -DASM_SOURCE=1 $(patsubst  build/%.o, hwcore/%.S, $@) -o $@

$(HWCORE_OBJ1): build/%.o : hwcore/%.asm
	mkdir -p $(dir $@) && \
	nasm -f elf32 $(patsubst build/%.o, hwcore/%.asm, $@) -o $@

$(HWCORE_OBJ2): build/%.o : hwcore/%.c
	mkdir -p $(dir $@) && \
	$(CC) -I$(PWD) -c $(CFLAGS)  $(patsubst  build/%.o, hwcore/%.c, $@) -o $@




$(SOS_OBJ): build/%.o : sos/%.c
	mkdir -p $(dir $@) && \
	$(CC) -I$(PWD) -c $(CFLAGS)  $(patsubst  build/%.o, sos/%.c, $@) -o $@


.PHONY: clean
clean:
	$(RM) -rf dist
	$(RM) $(SOS_BIN)
	$(RM) build/*.o build/*~


