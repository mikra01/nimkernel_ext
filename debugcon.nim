# Copyright (c) 2019 Michael Krauter
# MIT license
#
# isa debug console driver
# qemu specific
# needs qemu option: 
# -chardev stdio,id=seabios -device isa-debugcon,iobase=0x402,chardev=seabios

import convutils,ioutils

const
  DEBUGCON_DATAPORT = 0x402.uint16

  
var cbufL : array[8,byte]  
var cbufW : array[4,byte]
var cbufB: array[2,byte]
## no stdlib present so buffer is defined globally (not threadsafe)
  
template outNextLine* =
  debugOut("\n",1);  
  
    
proc debugOut*(val : uint8) =
  ## outputs a value to the console. a hex2Char 
  ## conversion is performed
  hex2CharB(val,cbufB)
  ioutils.writePort(DEBUGCON_DATAPORT,cbufB[0].uint8)
  ioutils.writePort(DEBUGCON_DATAPORT,cbufB[1].uint8)

proc debugOut*(val : uint16) =
  hex2CharW(val,cbufW)
  for i in 0..3:
    ioutils.writePort(DEBUGCON_DATAPORT,cbufW[i].uint8)
    
proc debugOut*(val : uint32) =
  hex2CharL(val,cbufL)
  for i in 0 .. 7 :
    ioutils.writePort(DEBUGCON_DATAPORT,cbufL[i].uint8)  
    
template debugOut*(val : char) =
  ioutils.writePort(DEBUGCON_DATAPORT,val.byte)

template debugOut*(arrptr : ptr , len : int) =
  for i in 0 .. len-1 :
    ioutils.writePort(DEBUGCON_DATAPORT,arrptr[i].uint8)  
  
proc debugOut*(val : string, len : int) =
  ## simple debugconsole out. we do not need to utilize a timer
  ## or irq for waiting till a char is transmitted
  ## we need to define the proc here and not within ioutils because
  ## something seems to be optimized
  for i in 0 .. len-1:
    ioutils.writePort(DEBUGCON_DATAPORT,val[i].byte)
  
proc dumpMemBin*( start : int , len : int ) =
  ## bin memory dump toconsole  
  var p : int = start
  for i in countup(0,len-1):
    debugOut( (cast[ptr uint8](p))[] )
    inc p

proc dumpMemAsc*( start : int , len : int ) =
  ## bin memory dump toconsole  
  var p : int = start
  for i in countup(0,len-1):
    debugOut( (cast[ptr char](p))[] )
    inc p
