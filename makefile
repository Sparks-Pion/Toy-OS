AS			:= nasm
OBJCOPY		:= objcopy
QEMU		:= qemu-system-i386
BOCHS 		:= bochs
IMG			:= boot.img
SOURCE_DIR	:= src/
BUILD_DIR	:= build/
TARGET_DIR  := target/
QEMU_FLAGS 	+= -no-reboot -d in_asm

all: init boot.bin os.bin image

init:
	mkdir -p $(BUILD_DIR)
	mkdir -p $(TARGET_DIR)

boot.bin:
	# 编译引导扇区的内容 (512 byte)
	cd $(SOURCE_DIR) && $(AS) boot.asm -o ../$(BUILD_DIR)/boot.bin

os.bin:
	# 编译所编写的操作系统的内容
	cd $(SOURCE_DIR) && $(AS) os.asm -o ../$(BUILD_DIR)/os.bin

image:
	# 创建 1.44M 的软盘
	dd if=/dev/zero of=$(TARGET_DIR)/$(IMG) bs=512 count=2880
	# 写入引导扇区
	dd if=$(BUILD_DIR)/boot.bin of=$(TARGET_DIR)/$(IMG) bs=512 count=1 conv=notrunc
	# 挂载软盘
	mkdir -p /mnt/$(IMG)
	- sudo umount /mnt/$(IMG)
	sudo mount -o loop $(TARGET_DIR)/$(IMG) /mnt/$(IMG)
	# 写入 os.bin
	sudo cp $(BUILD_DIR)/os.bin /mnt/$(IMG)/os.bin
clean:
	rm -rf $(BUILD_DIR)/*
	rm -rf $(TARGET_DIR)/*
	- sudo umount /mnt/$(IMG)

bochs:
	cp $(SOURCE_DIR)/boot.bxrc $(TARGET_DIR)/boot.bxrc
	cd $(TARGET_DIR) && sudo $(BOCHS) -qf boot.bxrc

qemu:
	sudo $(QEMU) -fda $(TARGET_DIR)/$(IMG)

.PHONY:
	all