# Copyright (c) 2019 Michael Krauter
# MIT license
#
# simplified keyboard driver (no multikey processing, except shift)
#
# further reading:
# https://www.win.tue.nl/~aeb/linux/kbd/scancodes.html
#
# description:
# the interrupt just reads the scancode out of port 0x60. 
# this value is written into a simple circular buffer.
# the conversion of the scancode to the corresponding keycode 
# is done within main.nim
#
# the keyboard processor is not initialized 
# so don't expect it's working on real hardware
#

import idt,ioutils,circularbuffer

const 
  KEYBOARD_DATA_PORT  = 0x60.byte

  ESC_KEY_Pressed = 0x01.int8
  LEFT_SHIFT_Pressed = 0x2A.int8
  RIGHT_SHIFT_Pressed = 0x36.int8
  LEFT_SHIFT_Released = 0xAA.int8
  RIGHT_SHIFT_Released = 0xB6.int8
  LEFT_CTRL_Pressed = 0x1D.int8
  RIGHT_CTRL_Pressed = 0x1D.int8
  # scancodes for special keys
  # 1d u. 38 right alt (multicode)
  # 
  
var cBuff : CBuffer[4,int8]
var scancodeMultikey : int8  
  
const keybmap_lc : array[128,char] = [
  # lowercase keyboard-mapping us-ascii 
  '\x00', '\x00','1','2','3','4','5','6','7','8','9','0','\'','+','\b','\t',
  'q','w','e','r','t','z','u','i','o','p','{','}','\n','\x00','a','s',
  'd','f','g','h','j','k','l',';','\'','`','\x00','\\','y','x','c','v',
  'b','n','m',',','.','-','\x00','*','\x00',' ','\x00','\x00','\x00','\x00','\x00','\x00',
  '\x00','\x00','\x00','\x00','\x00','\x00','\x00','7','8','9','-','4','5','6','+','1',
  '2','3','0','.','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00',
  '\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00',
  '\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00',
  '\x00','\x00','\x00','\x00','\x00'
  ]

const keybmap_uc : array[128,char] = [
  # uppercase keyboard-mapping us-ascii (capslock/shift active)
  '\x00','\x00','!','"','#','$','%','&','/','(',')','=','\x00','*','\b','\t',
  'Q','W','E','R','T','Z','U','I','O','P','[',']','\n','\x00','A','S',
  'D','F','G','H','J','K','L',';','"','\x00','\x00','|','Y','X','C','V',
  'B','N','M',';',':','_','\x00','\x00','\x00',' ','\x00','\x00','\x00','\x00','\x00','\x00',
  '\x00','\x00','\x00','\x00','\x00','\x00','\x00','7','8','9','-','4','5','6','+','1',
  '2','3','0','.','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00',
  '\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00',
  '\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00','\x00',
  '\x00','\x00','\x00','\x00','\x00'
  ]

proc initialise*() =
  cBuff.reset()  
  scancodeMultikey = 0
  
proc ps2mouseIrq*() {.exportc.} =
  # todo: implement
  writePort(PIC_CTRL_PORT_SLAVE, 0x20) 
  # slavepic end of irq
  writePort(PIC_CTRL_PORT_MASTER, 0x20) 
  # masterpic end of irq

proc keyboardIrq*() {.exportc.}=
  # we do not use __attribute__((interrupt))
  # because its seems not to be supported by i686-gcc. 
  # thus we tailored our own wrapper within boot.s
   
  let scancode = readPort(KEYBOARD_DATA_PORT).int8

  # needs some rework. handle multikey within the buffer
  if (scancode == LEFT_SHIFT_Pressed or 
      scancode == RIGHT_SHIFT_Pressed ):
        scancodeMultikey = scancode
  elif ( scancode == LEFT_SHIFT_Released or
         scancode == RIGHT_SHIFT_Released ):
        scancodeMultikey = 0
  else:    
    if scancode > 0 and scancode < 128:
      # key pressed 
      cBuff.putVal(scancode)
    elif scancode < 0:
      # for now ignore key-release event (highbit set)
      discard 
 
  writePort(PIC_CTRL_PORT_MASTER, 0x20) # signal master pic: end of irq
 
proc isKeyPressed*() : bool =
  ## true if new scancode ready to read
  cBuff.hasVal()
  
template withShift*() : bool =
  scancodeMultikey == LEFT_SHIFT_Pressed or
  scancodeMultikey == RIGHT_SHIFT_Pressed

proc withLeftCtrl*() : bool =
  discard

proc withRightCtrl*() : bool = 
  discard
  
proc withLeftALt*() : bool =
  discard

proc withRightAlt*() : bool =
  discard

proc readScancode*() : int8 =
  cBuff.fetchVal()
  
proc scancode2Keycode*(scancode : int8) : char =  
  ## scancode to ascii-code conversion
  if scancode >= 0 and scancode <= 128:
    if withShift():
      result = keybmap_uc[scancode]    
    else:
      result = keybmap_lc[scancode]
  else:
    result = '\x00'
  
  