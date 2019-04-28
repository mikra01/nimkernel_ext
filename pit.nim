# Copyright (c) 2019 Michael Krauter
# MIT license
#
# periodic interrupt timer handling routines
# 0x86 arch specific (8253/8254)
# only channel 0 is utilized
# only channel 0 can fire irqs (on low to high transition)
# mode 2 used (rate generator)
# frequency = 1193182 / counter_val Hz (ticks per second)
#
#
import idt,ioutils,circularbuffer

const
  CHAN0_COUNTER =0x40.uint32
  PIT_CMD =0x43.uint32

var pitReloadVal : int32
var countVal : int32

var tickBuffer : CBuffer[4,int32]

proc pitIrq {.exportc.} =
  ## pit ISR no. 0
  ## called each ms 
  dec countVal  
  if countVal <= 0:
    countVal= pitReloadVal
    tickBuffer.putVal(pitReloadVal)
  
  writePort(idt.PIC_CTRL_PORT_MASTER,0x20.uint8)

proc initialise*() = 
  tickBuffer.reset()
  pitReloadVal = 0
  countVal = 0
  # preset reload value,
  # initialised pic
  var counter : uint16 = ( 0x1234DD.uint32 div 1000).uint16 # 1kHz 
  writePort(PIT_CMD,0b00110100.uint8) # read/load lsb and msb (mode2,binary16)
  writePort(CHAN0_COUNTER, (counter mod 256).uint8) # lsb
  writePort(CHAN0_COUNTER, (counter div 256).uint8) # msb

proc setTicktime*( millisecs : int32)=
   countVal = millisecs
   pitReloadVal = millisecs
   tickBuffer.reset()     

proc hasTickEvent*() : bool =
  ## returns true if value is in buffer
  result = tickBuffer.hasVal
  if result:
    tickBuffer.reset()
   
proc sleep*( millisecs : int32) =
  ## blocking version. 
  setTicktime(millisecs)
  while not tickBuffer.hasVal:
     asm """ 
       hlt;     
     """  # halt till next irq
   
