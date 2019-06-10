# Copyright (c) 2019 Michael Krauter
# MIT license
#
# simple fixed size circular buffer
# unfetched values are overwritten
# if more values are inserted than the size of buffer
# a wraparound will occur
#

type
  CBuffer*[n : static[int], T] = object
    buffer : array[n,T]
    readidx : int 
    writeidx : int

template hasVal*[n : static[int],T](b : var CBuffer[ n , T] ) : bool =
  ## returns true if there is data ready to read
  b.readidx != b.writeidx

proc getItemCount*[n : static[int],T](b : var CBuffer[ n , T] ) : int =
  ## returns the number of inserted items
  result = b.writeidx - b.readix
  if result < 0:
    result = 0 - result # abs
    
template peekVal*[n : static[int],T](b : var CBuffer[n,T] ) : T =
  ## reads the value without removing it from the buffer
  b.buffer[b.readidx]

proc peekPrevVal*[n : static[int],T](b : var CBuffer[n,T] ) : T = 
  ## peeks the valuae before the current value
  var peekidx = b.readidx
  if peekidx == 0:
    peekidx = b.buff.len-1
  else:
    dec peekidx
  b.buffer[peekidx]
  
proc reset*[n : static[int],T](b : var CBuffer[n,T]) =
  ## internal counters are set to zero
  b.readidx = 0
  b.writeidx = 0
  
proc fetchVal*[n : static[int],T](b : var CBuffer[n,T] ) : T =
  ## reads the value with removing
  result = b.buffer[b.readidx]
  inc b.readidx
  if b.readidx == b.buffer.len:
    b.readidx = 0 # wrap over

proc putVal*[n : static[int],T](b : var CBuffer[n,T], val : T ) =
  b.buffer[b.writeidx] = val
  inc b.writeidx
  if b.writeidx == b.buffer.len:  
    b.writeidx = 0   # wrap over
