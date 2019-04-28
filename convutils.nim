# Copyright (c) 2019 Michael Krauter
# MIT license
#
# basic conversion utils

const hexChars : array[16,char] = ['0','1','2','3','4','5','6','7','8','9'
                                   ,'A','B','C','D','E','F']

template hex2Char*(par : int8, res : var array[2,char]) =
  res[0] = hexChars[par shr 4 ]    # process upper nibble                                   
  res[1] = hexChars[par and 0x0F]  # process lower nibble

proc toDecimalChar*(par : int16,res : var array[6,char]) =
  ## simple 5 digit decimal conversion
  var tmpval = par
  var decval = 0
  if par < 0:
    res[0] = '-' 
    tmpval = 0 - tmpval # abs
  else:
    res[0] = ' '
  decval = ( tmpval and 0x000F) 
  decval = decval +  ( (tmpval shr 4) and 0x000F ) * ( 16 ) 
  decval = decval + ( (tmpval shr 8) and 0x000F) * ( 256 )
  # issue: we cannot use roof from math 
  decval = decval + ( ( tmpval shr 12) and 0x000F) * ( 4096 )
  
  res[5] = hexChars[ decval mod 10 ]
  res[4] = hexChars[ (decval div 10) mod 10 ]
  res[3] = hexChars[ (decval div 100) mod 10 ]
  res[2] = hexChars[ (decval div 1000) mod 10 ]
  res[1] = hexChars[ (decval div 10000) mod 10 ]