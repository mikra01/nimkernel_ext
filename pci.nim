# Copyright (c) 2019 Michael Krauter
# MIT license
#
# pci hw detection (brute force method)
#
# further information : wiki.osdev.org/PCI
#
# memory layout( source https://wiki.qemu.org/Documentation/Platforms/PC )
# 0x00000 .. 0xA0000      DOS Memory Area       RAM
# 0xA0000 .. 0xC0000      Video Memory          Device Memory
# 0xC0000 .. 0xE0000      ISA Extension ROM     ROM
# 0xE0000 .. 0xF0000      BIOS Extension ROM    ROM
# 0xF0000 .. 0x100000     BIOS Area             ROM


