import nake
import os

const
  CC = "i686-elf-gcc"
  asmC = "i686-elf-as"

task "clean", "Removes build files.":
  removeFile("boot.o")
  removeFile("main.bin")
  removeDir("nimcache")
  echo "Done."

task "build", "Builds the operating system.":
  echo "Compiling..."
  # if --d:release not present we get the error: system module needs: addInt
  direShell "nim c --d:release --verbosity:3 --nimcache:nimcache --os:standalone --gc:none --gcc.exe:$1 main.nim" % CC
  
  direShell asmC, "boot.s -o boot.o"
  
  echo "Linking..."
  
  direShell CC, "-T linker.ld -o main.bin -ffreestanding -O2 -nostdlib boot.o nimcache/main.c.o nimcache/stdlib_system.c.o nimcache/ioutils.c.o  nimcache/keyboard.c.o  nimcache/idt.c.o nimcache/gdt.c.o nimcache/convutils.c.o nimcache/debugcon.c.o nimcache/pit.c.o nimcache/circularbuffer.c.o nimcache/rsdp.c.o nimcache/pci.c.o "
  # direShell can not handle multiline strings
  echo "Done."
  
task "run", "Runs the operating system using QEMU.":
  if not existsFile("main.bin"): runTask("build")
  # added: opens the debug-console for monitoring the boot-process -nic user,model=virtio-net-pci 
  direShell "qemu-system-i386 -kernel main.bin -chardev stdio,id=seabios -device isa-debugcon,iobase=0x402,chardev=seabios -machine type=pc-q35-2.8 " #-nic user,model=virtio-net-pci -device intel-iommu "
