# nimkernel_ext
a fork from https://github.com/dom96/nimkernel with some extensions

mk: I added some additional stuff: 
- various examples how nim symbols are consumed within gnu inline assembly
- qemu debug console support 
- basic gdt/idt/pic init 
- keyboard interrupt handler 
- PIT (periodic interrupt timer) handler

Remark: to get it compiled with 0.19.4/0.19.9, you need to patch indexerrors.nim as described here:
https://github.com/nim-lang/Nim/issues/10978

TODO: PCI hw detection, tasking and usermode (ring3)
I used the gnu cross toolchain i686-elf for compilation on windows.

Limitations: if you like string support you need to go further and setup your own
Standard C Library; for instance https://wiki.osdev.org/Porting_Newlib 

