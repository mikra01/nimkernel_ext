# Copyright (c) 2019 Michael Krauter
# MIT license
#
# basic conversion utils

const hexChars : array[16,char] = ['0','1','2','3','4','5','6','7','8','9'
                                   ,'A','B','C','D','E','F']

  
template hex2CharB*(par : uint8, res : var array[2,byte]) =
  res[0] = hexChars[par shr 4 ].byte    # process upper nibble                                   
  res[1] = hexChars[par and 0x0F].byte  # process lower nibble

template hex2CharW*(par : uint16, res : var array[4,byte]) =
  res[0] = hexChars[ (par shr 12) and 0x0F.uint16 ].byte                                       
  res[1] = hexChars[ (par shr 8) and 0x0F.uint16 ].byte     
  res[2] = hexChars[ (par shr 4) and 0x0F.uint16 ].byte                                       
  res[3] = hexChars[par and 0x0F.uint16 ].byte  


template hex2CharL*(par : uint32, res : var array[8,byte]) =
  res[0] = hexChars[par shr 28 and 0x0F].byte    # process hs nibble                                   
  res[1] = hexChars[par shr 24 and 0x0F].byte 
  res[2] = hexChars[par shr 20 and 0x0F].byte                                       
  res[3] = hexChars[par shr 16 and 0x0F ].byte  
  res[4] = hexChars[par shr 12 and 0x0F ].byte                                       
  res[5] = hexChars[par shr 8 and 0x0F].byte  
  res[6] = hexChars[par shr 4 and 0x0F ].byte                                       
  res[7] = hexChars[par and 0x0F].byte  # process ls nibble


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