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

var cbuf : array[2,char]
  
proc debugOut*(val : int8) =
  ## outputs a value to the console. a hex2Char 
  ## conversion is performed
  ## dangerzone: this proc is not reentrant at the moment!
  ##
  ## issue: if a local variable (char) the compiler complains
  ## about string.h missing
  hex2Char(val,cbuf)
  ioutils.writePort(DEBUGCON_DATAPORT,cbuf[0].byte)
  ioutils.writePort(DEBUGCON_DATAPORT,cbuf[1].byte)
  ioutils.writePort(DEBUGCON_DATAPORT,' '.byte)

template debugOut*(val : char) =
  ioutils.writePort(DEBUGCON_DATAPORT,val.byte)
  
proc debugOut*(val : string, len : int) =
  ## simple debugconsole out. we do not need to utilize a timer
  ## or irq for waiting till a char is transmitted
  ## we need to define the proc here and not within ioutils because
  ## something seems to be optimized
  for i in 0 .. len-1:
    ioutils.writePort(DEBUGCON_DATAPORT,val[i].byte)