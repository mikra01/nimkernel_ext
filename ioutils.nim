type
  PVIDMem* = ptr array[0..65_000, TEntry]
  IVT* = ptr array[0..255,uint16]
  
  TVGAColor* = enum
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGrey = 7,
    DarkGrey = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    LightMagenta = 13,
    Yellow = 14,
    White = 15

  TPos* = tuple[x: int, y: int]

  TAttribute* = distinct uint8
  TEntry* = distinct uint16

const
  VGAWidth* = 80
  VGAHeight* = 25
  
proc makeColor*(bg: TVGAColor, fg: TVGAColor): TAttribute =
  ## Combines a foreground and background color into a ``TAttribute``.
  return (ord(fg).uint8 or (ord(bg).uint8 shl 4)).TAttribute

proc makeEntry*(c: char, color: TAttribute): TEntry =
  ## Combines a char and a *TAttribute* into a format which can be
  ## directly written to the Video memory.
  let c16 = ord(c).uint16
  let color16 = color.uint16
  return (c16 or (color16 shl 8)).TEntry

proc writeChar*(vram: PVidMem, entry: TEntry, pos: TPos) =
  ## Writes a character at the specified ``pos``.
  let index : int = (80 * pos.y) + pos.x 
  vram[index] = entry

proc rainbow*(vram: PVidMem, text: string, pos: TPos) =
  ## Writes a string at the specified ``pos`` with varying colors which, despite
  ## the name of this function, do not resemble a rainbow.
  var colorBG = DarkGrey
  var colorFG = Blue
  proc nextColor(color: TVGAColor, skip: set[TVGAColor]): TVGAColor =
    if color == White:
      result = Black  
    else:
      result = (ord(color) + 1).TVGAColor
    if result in skip: result = nextColor(result, skip)
  
  for i in 0 .. text.len-1:
    colorFG = nextColor(colorFG, {Black, Cyan, DarkGrey, Magenta, Red,
                                  Blue, LightBlue, LightMagenta})
    let attr = makeColor(colorBG, colorFG)
    
    vram.writeChar(makeEntry(text[i], attr), (pos.x+i, pos.y))

proc writeString*(vram: PVidMem, text: string, color: TAttribute, pos: TPos) =
  ## Writes a string at the specified ``pos`` with the specified ``color``.
  for i in 0 .. text.len-1:
    vram.writeChar(makeEntry(text[i], color), (pos.x+i, pos.y))

proc screenClear*(video_mem: PVidMem, color: TVGAColor) =
  ## Clears the screen with a specified ``color``.
  let attr = makeColor(color, color)
  let space = makeEntry(' ', attr)
  
  var i = 0
  while i <=% VGAWidth*VGAHeight:
    video_mem[i] = space
    inc(i)

{.push stackTrace:off.}
proc getChar*() : char =
  ## gnu asm return example
  asm """
    mov 'T', %0
    :"=r"(`result`)
    : /* */
  """

proc addInt*(a, b: int16): int16 =
  ## gnu as add example
  asm """
    addw %%bx, %%ax
    :"=a"(`result`)
    :"a"(`a`), "b"(`b`)
  """
  
proc readPort8*(portNumber : uint32 ) : uint8  =  
  asm """
    inb %%dx,%%al;         # 
   # outb %%al, $0x80       /* noop (slowdown) needed on real hardware */
    :"=al"(`result`)
    :"edx"(`portNumber`)
   """ 

proc readPort16*(portNumber : uint32 ) : uint16  =  
  asm """
    inw %w1,%0;         # 
    :"=a"(`result`)
    :"d"(`portNumber`)
   """ 
  # asm """
  #   inw %%dx,%%ax;         # 
  #  # outb %%al, $0x80       /* noop (slowdown) needed on real hardware */
  #   :"=ax"(`result`)
  #   :"edx"(`portNumber`)
  #  """ 


proc readPort32*(portNumber : uint32 ) : uint32  =  
  asm """
    in  %%dx,%%eax;         # 
   # outb %%al, $0x80       /* noop (slowdown) needed on real hardware */
    :"=eax"(`result`)
    :"edx"(`portNumber`)
   """ 

proc writePort*(portNumber : uint32, val : uint8) =
  asm """
     outb %%al,%%dx;
     outb %%al, $0x80  /* noop (slowdown) needed on real hardware */
   : /* nothing is returned */
    :"edx"(`portNumber`), "al"(`val`)
   """
 
proc writePort*(portNumber : uint32, val : uint16) =
  asm """
     outw %%ax,%%dx;
     outw %%ax, $0x80  /* noop (slowdown) needed on real hardware */
    : /* nothing is returned */
    :"edx"(`portNumber`), "ax"(`val`)
   """

proc writePort*(portNumber : uint32, val : uint32) =
  asm """
     outl %%eax,%%edx;
     outl %%eax, $0x80  /* noop (slowdown) needed on real hardware */
    : /* nothing is returned */
    :"edx"(`portNumber`), "eax"(`val`)
   """
   
proc disableIRQ*() {.asmNoStackFrame.} =
  asm """
    cli;
    ret
  """
  
proc enableIRQ*() {.asmNoStackFrame.} =
  asm """
    sti;
    ret
  """

{.pop.}

  
 