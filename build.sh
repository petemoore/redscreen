#!/bin/bash -eu

cd "$(dirname "${0}")"
rm -rf dist
mkdir dist
aarch64-unknown-linux-gnu-as -g -o redscreen.o redscreen.s 
aarch64-unknown-linux-gnu-ld -M -o redscreen.elf redscreen.o
aarch64-unknown-linux-gnu-objcopy --set-start=0x80000 redscreen.elf -O binary dist/kernel8.img
aarch64-unknown-linux-gnu-objdump -b binary -z --adjust-vma=0x80000 -maarch64 -D dist/kernel8.img
rm redscreen.{o,elf}
wget -q -O dist/LICENCE.broadcom https://github.com/raspberrypi/firmware/blob/d5b8d8d7cce3f3eecb24c20a55cc50a48e3d5f4e/boot/LICENCE.broadcom?raw=true
wget -q -O dist/bootcode.bin https://github.com/raspberrypi/firmware/blob/d5b8d8d7cce3f3eecb24c20a55cc50a48e3d5f4e/boot/bootcode.bin?raw=true
wget -q -O dist/fixup.dat https://github.com/raspberrypi/firmware/blob/d5b8d8d7cce3f3eecb24c20a55cc50a48e3d5f4e/boot/fixup.dat?raw=true
wget -q -O dist/start.elf https://github.com/raspberrypi/firmware/blob/d5b8d8d7cce3f3eecb24c20a55cc50a48e3d5f4e/boot/start.elf?raw=true
