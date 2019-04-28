import ioutils
import idt
import keyboard
import gdt
import pit
import debugcon
import circularbuffer
import convutils
import pci

type
  TMultiboot_header = object
  PMultiboot_header = ptr TMultiboot_header

var stringbuffer : string
  # unfortunately we can not define the size

var charbuffer : array[6,char]

proc kmain(mb_header: PMultiboot_header, magic: int) {.exportc.} =
  # multiboot supports only 0x86 arch
  # we are running in protected-mode (32bit), Ring0, seaBios loaded and interrupts disabled
  if magic != 0x2BADB002:
    discard # Something went wrong?

  var vram = cast[ioutils.PVIDMem](0xB8000)
  screenClear(vram, ioutils.Yellow) # Make the screen yellow.

  # Demonstration of error handling.
  var x = len(vram[])
  var outOfBounds = vram[x]
  
  let attr = makeColor(ioutils.Yellow, ioutils.DarkGrey)
  writeString(vram, "Nim", attr, (25, 9))
  writeString(vram, "Expressive. Efficient. Elegant.", attr, (25, 10))
  rainbow(vram, "It's pure pleasure.", (x: 25, y: 11))
  writeString(vram, "please try the keyboard..", attr, (25, 13))
  
  initialiseGDT()
  initialiseAndLoadIDT()
  idt.initialisePIC() # remaps the intel 8295 

  keyboard.initialise()
  pit.initialise()
  
  pci.initPCI()

  
  ioutils.enableIRQ()

  var tstval : int16 = -10
  pit.setTicktime(1000)
  
  while true:
    if pit.hasTickEvent():
      inc tstval
      convutils.toDecimalChar(tstval,charbuffer)
      for i in countup(0,5):  
        writeChar(vram,makeEntry(charbuffer[i],attr),(12+i,14)) # char to screen

    if keyboard.isKeyPressed():
      let scancode = readScancode()
      let ascii  = scancode2Keycode(scancode)
      writeChar(vram,makeEntry(ascii,attr),(12,12)) # char to screen
      stringbuffer[0] = ascii
      stringbuffer[1] = ' '
      debugcon.debugOut(scancode)       # debug out scancode
      debugcon.debugOut(stringbuffer,2) # debug out asciicode
    
    asm """
       hlt;     
     """  

  