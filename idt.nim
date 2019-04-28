# Copyright (c) 2019 Michael Krauter
# MIT license
#
# following code is IA32 specific 
# initialises the interrupt decriptor table (IDT)
# for further information please look at:
# https://wiki.osdev.org/Interrupt_Descriptor_Table
#
# spurious irqs are not handled actually
# we simply assume that spurious IRQs dont happen within qemu
#
# TODO: implement TSS init (task state segement)
import ioutils, gdt

const 
  Gate32_IRQ = 0x8E.byte
  Gate32_Trap = 0x8F.byte
  Gate32_Task = 0x85.byte
  PIC_CTRL_PORT_MASTER* = 0x20.uint32
  PIC_DATA_PORT_MASTER* = 0x21.uint32
  PIC_CTRL_PORT_SLAVE* = 0xA0.uint32
  PIC_DATA_PORT_SLAVE* = 0xA1.uint32
  IRQBASE_MASTERPIC* = 0x20.uint8
  IRQBASE_SLAVEPIC* = 0x28.uint8

  PIT_ISR_NUM = IRQBASE_MASTERPIC  # irq 0
  KEYBOARD_ISR_NUM = IRQBASE_MASTERPIC + 1 # irq 1
  PS2MOUSE_ISR_NUM = IRQBASE_SLAVEPIC + 4  # irq12
  
type
  IDTEntry {.packed.} = object
    offsetLowbits : uint16
    selector : uint16
    zerofield : byte
    flags : byte
    offsetHighbits : uint16

  IDTPointer* {.packed.} = object
    limit : uint16
    base : uint32

  IDTTable* {.packed.} = array[256,IDTEntry]

# module globals
var idttab* : IDTTable
var idtptr* : IDTPointer

proc noOpHandler*() {.asmNoStackFrame.} =
 asm """
    iret;
  """ # could be defined within boot.s
  
proc keyboard_handler_int() {.importc.}  # defined in boot.s
proc mouse_handler_int() {.importc.}  # defined in boot.s
proc pit_handler_int() {.importc.}  
  
proc initIDTEntry*(isrNum : uint8, baseAddr : uint32, selector : uint16, gateFlags : byte) =
  ## adds a gate to the IDT (interrupt descriptor table)
  idttab[isrNum].offsetLowbits = cast[uint16](baseAddr and 0xFFFF.uint16)
  idttab[isrNum].selector = selector
  idttab[isrNum].zerofield = 0x00
  idttab[isrNum].flags = gateFlags
  idttab[isrNum].offsetHighbits = cast[uint16]( ( baseAddr shr 16 ) and 0xFFFF.uint16 )
  
proc initialiseAndLoadIDT*() =
  idtptr.limit =  sizeOf( IDTTable ) - 1
  idtptr.base = cast[uint32](idttab.addr)  
  let noopBase = cast[uint32](cast[pointer](noOpHandler))
  
  for i in 0 .. idttab.len-1:
    # let all irqs point to our noOp instruction
    initIDTEntry(i.uint8,noopBase, gdt.CODE_Ring0, GATE32_IRQ ) # gdt code segment
 
  initIDTEntry(KEYBOARD_ISR_NUM,cast[uint32](cast[pointer](keyboard_handler_int)), gdt.CODE_Ring0, GATE32_IRQ)  
  # init keyboard_irq 
  initIDTEntry(PS2MOUSE_ISR_NUM,cast[uint32](cast[pointer](mouse_handler_int)), gdt.CODE_Ring0, GATE32_IRQ)  
  # mouse not implemented
  initIDTEntry(PIT_ISR_NUM,cast[uint32](cast[pointer](pit_handler_int)), gdt.CODE_Ring0, GATE32_IRQ)  
  # pit irq 
 
  asm """      
    lidt %0;
    nop;
    : /*returnlist empty */
    : "m"(`idtptr`)       
    : /* empty clobbers */
   """ # load idtptr
    
proc initialisePIC*() = 
  # intel 8295 init  
  # remap irqs to offset 0x20 and above because the other 
  # vectors (0-0x19) are reserved by intel
  ioutils.writePort(PIC_CTRL_PORT_MASTER, 0x11.uint8)
  ioutils.writePort(PIC_CTRL_PORT_SLAVE, 0x11.uint8)   
 
  ioutils.writePort(PIC_DATA_PORT_MASTER, idt.IRQBASE_MASTERPIC) 
  # irq vectors master pic
  ioutils.writePort(PIC_DATA_PORT_SLAVE, idt.IRQBASE_SLAVEPIC)  
  # irq vectors slave pic 
  ioutils.writePort(PIC_DATA_PORT_MASTER, 0x04.uint8) 
  ioutils.writePort(PIC_DATA_PORT_SLAVE, 0x02.uint8) 
  # set mode cascading 
  ioutils.writePort(PIC_DATA_PORT_MASTER, 0x01.uint8)
  ioutils.writePort(PIC_DATA_PORT_SLAVE, 0x01.uint8) 
  # 0x86mode
  
  ioutils.writePort(PIC_DATA_PORT_MASTER, 0x00.uint8)
  ioutils.writePort(PIC_DATA_PORT_SLAVE, 0x00.uint8)
  # clr
  
  ioutils.writePort(PIC_DATA_PORT_MASTER,0b11111000.uint8)  
  # enable KEYBOARDIRQ and line2 (cascading) and chan0PIT
  ioutils.writePort(PIC_DATA_PORT_SLAVE,0b11111111.uint8)  
  # mask irqs slavepic 
  # if a bit is set the irq is masked out
  
 