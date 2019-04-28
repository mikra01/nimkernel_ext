# Copyright (c) 2019 Michael Krauter
# MIT license
#
# global descriptor table (IA spec)
# for further reading please look at: 
# https://wiki.osdev.org/GDT

const Code_Ring0*  = 0x08.uint16 
## byte offset to first entry
const Data_Ring0*  = 0x10.uint16
## byte offset to 2nd entry

type
  GDTEntry {.packed.} = object
    limitLowbits : uint16
    baseLow16b   : uint16
    baseMid    : byte
    access : byte
    granularity : byte
    baseHighByte : byte

  GDTPointer {.packed.} = object
    limit : uint16
    base : uint32

  GDTTable {.packed.} = array[3,GDTEntry]
  # three entries - simple flat memory model

var gdtTab* : GDTTable
var gdtPtr* : GDTPointer
# globals

proc initGDTEntry*( entryId : int, baseAddr : uint32, limit : uint32, 
                    access : byte, granularity : byte) =
  gdtTab[entryId].baseLow16b = cast[uint16](baseAddr and 0xFFFF)
  gdtTab[entryId].baseMid = cast[byte]( ( baseAddr shr 16 ) and 0xFF )
  gdtTab[entryId].baseHighByte = cast[byte]( ( baseAddr shr 24 ) and 0xFF )
  gdtTab[entryId].limitLowbits = cast[uint16](limit and 0xFFFF)
  gdtTab[entryId].granularity = cast[uint8]((limit shr 16) and 0x0F)
  gdtTab[entryId].granularity = gdtTab[entryId].granularity or 
                                  cast[uint8](( granularity and 0xF0 ))
  gdtTab[entryId].access = access
      

proc initialiseGDT*() =
  gdtPtr.limit = sizeOf(GDTTable) - 1
  gdtPtr.base = cast[uint32](gdtTab.addr)
  initGDTEntry(0,0,0,0,0) # first entry must be zeroed
  initGDTEntry(1,0,0x00ffffff,0b10011010'u8,0b11001111'u8) # ring 0 codesegment base = 0
  initGDTEntry(2,0,0x00ffffff,0b10010010'u8,0b11001111'u8) # ring 0 datasegment base = 0 
  # 32bit data and code, 4kb granularity, limit 4GiB
  asm """
    lgdt %0;
    # to activate the new gdt load all segment regs
    mov %1, %%ax;  # 0x10 offset of gdt data segment (offset 3rd entry)
    mov %%ax, %%ds;
    mov %%ax, %%es;
    mov %%ax, %%fs;
    mov %%ax, %%gs;
    mov %%ax, %%ss;
    ljmp %2, $farjmp;  # 0x8 offset of code segment - far jump (offset 2nd gdt-entry)
   farjmp: nop;
    : /* returnlist empty */
    : "m"(`gdtPtr`),"i"(`DATA_Ring0`),"i"(`CODE_Ring0`)      
    : "ax"
   """   