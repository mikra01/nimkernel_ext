# nimkernel_ext
a fork from https://github.com/dom96/nimkernel with some extensions

mk: I added some additional stuff: 
- various examples how nim symbols are consumed within gnu inline assembly
- qemu debug console support 
- basic gdt/idt/pic init 
- keyboard interrupt handler 
- PIT (periodic interrupt timer) handler
- very basic ACPI_Tables lookup

Remark: unfortunately it does not compile with the latest nim compiler version (0.20) - I recommend
to compile with 0.19.6 (tested) 

TODO: PCI hw detection(ACPI_Table, PCI/e lookup almost done), nic driver (e1000) , tasking and usermode (ring3)

Limitations: if you like string support you need to go further and setup your own
Standard C Library; for instance https://wiki.osdev.org/Porting_Newlib 

Dependencies: just nim 0.19.06, nake and qemu required. I used the gnu cross toolchain i686-elf for compilation on windows.
