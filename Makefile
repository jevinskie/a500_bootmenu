#
# Makefile for bootmenu
#

CC := $(CROSS_COMPILE)gcc
LD := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy

HOST_CC := gcc
HOST_CFLAGS :=

LIBGCC := -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc

CFLAGS := -Os -Wall -Wno-return-type -Wno-main -fno-builtin -fno-stack-protector -mthumb-interwork -march=armv7-a -mthumb -ffunction-sections -Iinclude
AFLAGS := -D__ASSEMBLY__ -fno-builtin -march=armv7-a -ffunction-sections
LDFLAGS := -static $(LIBGCC) -nostdlib --gc-sections 
O ?= .

LIB_OBJS := $(O)/lib/_ashldi3.o $(O)/lib/_ashrdi3.o  $(O)/lib/_div0.o $(O)/lib/_divsi3.o $(O)/lib/_lshrdi3.o $(O)/lib/_modsi3.o  $(O)/lib/_udivsi3.o $(O)/lib/_umodsi3.o 
BL_OBJS := $(O)/bl_0_03_14.o $(O)/framebuffer.o $(O)/jpeg.o $(O)/bootmenu.o $(O)/fastboot.o 
OBJS := $(O)/start.o $(LIB_OBJS) $(BL_OBJS)

all: prep $(O)/bootloader_v8.bin $(O)/bootloader_v8.blob

$(O)/%.o : %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(O)/%.o : %.S
	$(CC) $(AFLAGS) -c $< -o $@

$(O)/bootmenu.elf: $(OBJS)
	$(LD) $(LDFLAGS) -T ld-script -o $(O)/bootmenu.elf $(OBJS)

$(O)/bootmenu.bin: $(O)/bootmenu.elf
	$(OBJCOPY) -O binary $(O)/bootmenu.elf -R .note -R .comment -R .bss -S $@

$(O)/bootloader_v8.bin: $(O)/bootmenu.bin
	cp -f bootloader.bin $@
	dd if=$(O)/bootmenu.bin of=$@ bs=1 seek=577536 conv=notrunc
	dd if=font.jpg of=$@ bs=1 seek=622592 conv=notrunc
	dd if=bootlogo.jpg of=$@ bs=1 seek=643072 conv=notrunc

$(O)/blobmaker:
	$(HOST_CC)  $(HOST_CFLAGS) blobmaker.c -o $@
	
$(O)/bootloader_v8.blob: $(O)/blobmaker $(O)/bootloader_v8.bin
	$(O)/blobmaker $(O)/bootloader_v8.bin $@
	
	
.PHONY: clean prep

prep:
	- mkdir $(O)/lib

clean:
	rm -f $(OBJS)
	- rmdir $(O)/lib
	rm -f $(O)/blobmaker
	rm -f $(O)/bootmenu.elf
	rm -f $(O)/bootmenu.bin
	rm -f $(O)/bootloader_v8.bin
	rm -f $(O)/bootloader_v8.blob
