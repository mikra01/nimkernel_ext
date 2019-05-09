# Copyright (c) 2019 Michael Krauter
# MIT license
#
# RSDP/ACPI config
# further reading: https://wiki.osdev.org/RSDP and
# https://uefi.org/sites/default/files/resources/ACPI_6_3_final_Jan30.pdf
import debugcon

const
  RSDP_TOKEN_DEF : array[0..7,char] = ['R','S','D',' ','P','T','R',' ']
  EBDA_BASE : uint16 = 0x040E
  MEM_BASE : uint32 = 0xE0000
  
  RSDT_TOKEN_DEF : array[0..3,char] = ['R','S','D','T']
  MCFG_TOKEN_DEF : array[0..3,char] = ['M','C','F','G']
  
type
  RSDPTokenType = array[0..15,char]
  RSDPMemPtr* = ptr array[0.. 8192,RSDPTokenType]
  EdbaBasePtr = ptr array[0..1,uint16]
  
  RSDP_Descriptor {.packed.} = ptr object
    ## acpi 1.0 descriptor
    token : array[0..7,char]
    checksum : uint8
    oemId : array[6,char]
    revision : uint8
    rsdtAddr : uint32
   
  # RSDP_ChecksummedFields = array[sizeof(RSDP_Descriptor),uint8]
  # sizeof seems not to give proper results
  RSDP_ChecksummedFields = ptr array[19,uint8]
  ACPI_ChecksummedFields = ptr array[36,uint8]
  
  RSDP_DescriptorExt {.packed.} = ptr object
    ## acpi 2.0 descriptor  
    descriptor : RSDP_Descriptor
    desclen : uint32
    xsdtAddress : uint64
    extChecksum : uint8
    reserved : array[3,uint8]
  
  ACPI_SDT_Header*  {.packed.} = ptr object
    signature : array[4,char]
    length : uint32       # checksum depends on the length field
    revision : uint8
    checksum : uint8
    oemId : array[6,char]
    oemTableId : array[8,char]
    oemRevision : uint32
    creatorId : uint32
    creatorRevision : uint32
    # after that n entries of 32bit ptr following (according to the length field)

  MCFG_Config_Hdr {.packed.} = ptr object
    baseAddr: uint64
    pciSegmGroupNum : uint16
    startPCINum : uint8
    endPCINum : uint8
    reserved : uint32 

  ACPI_MCFG_Header  {.packed.} = ptr object
    stdHeader : ACPI_SDT_Header
    reserved : uint64
    confighdr : array[0..15,MCFG_Config_Hdr]

template numACPIEntries(hdr : ACPI_SDT_Header ) : uint32 =
  ( hdr.length - 36 ) shr 2

proc calcACPIPtr(hdr : ACPI_SDT_Header, idx : int) : ACPI_SDT_Header =
  result = cast[ACPI_SDT_Header](cast[int](hdr.unsafeAddr) + 36 + (idx * 4))
     
var rsdpBaseAddr* : uint32  
var rsdtBaseAddr* : ACPI_SDT_Header
var mcfgCfgHdrPtr* : MCFG_Config_Hdr

proc validateRsdpChecksum( rsdpBase : var RSDP_ChecksummedFields ) : bool = 
  result = false
  var checksum : uint8 = 0
  for i in countup(0,19):
    checksum = checksum + rsdpBase[i]
  result = checksum == 0.uint8
  
proc validateAcpiChecksum( acpiBase : var  ACPI_ChecksummedFields , length : int ) : bool =
  result = false
  var checksum : uint8 = 0
  for i in countup(0,length):
    checksum = checksum + acpiBase[i]
  result = checksum == 0.uint8
 
 
proc strComp[T,L]( srcptr : ptr array[T,L] , dstptr : ptr array[T,L] , len : int) : bool =
  ## simple check for equality (unused)
  var ctr : int = 0
  for x in countup(0,len-1):
    if srcptr[x] == dstptr[ctr]:
      inc ctr
    else:
      break
  ctr == len
  
proc checkForToken( memptr : RSDPMemPtr, idx : int) : bool =
  ## returns true if token found
  var ctr : int = 0
  
  for x in countup(0,7):
    if memptr[idx][x] == RSDP_TOKEN_DEF[ctr]:
      inc ctr
  ctr == 8

proc isRSDTHeader( acpiHeader : var ACPI_SDT_Header ) : bool =
  var ctr : int = 0
  for x in countup(0,3):
    if acpiHeader.signature[x] == RSDT_TOKEN_DEF[ctr]:
      inc ctr    
  ctr == 4
  
proc isMCFGHeader( acpiHeader : var ACPI_SDT_Header) : bool =
  var ctr : int = 0
  for x in countup(0,3):
    if acpiHeader.signature[x] == MCFG_TOKEN_DEF[ctr]:
      inc ctr    
  ctr == 4
  
proc searchRSDPToken*() : bool =
  ## searches the memregion 0xE0000 to 0xFFFFF for the token 
  ## additional ebdabase search not performed
  result = false;
  var edbaBaseVal : uint32 = ((cast[EdbaBasePtr](EBDA_BASE))[0]) shl 4
  debugOut("EBDABASE at: ",13)
  debugOut(edbaBaseVal)
  outNextLine
  
  let rsdpmem = cast[RSDPMEMPtr](MEM_BASE) 
    
  var tokenFound : bool = false;
  
  for i in countup(0,len(rsdpmem[])):
    if rsdpmem[i][0] == RSDP_TOKEN_DEF[0]:
      # if first char found perform complete 8-char scan
      if checkForToken(rsdpmem,i):
        rsdpBaseAddr = ( i.uint32 shl 4 ) + MEM_BASE
        result = true
        break
        
proc acpiTablesLookup*() =
  var rsdphdr = cast[RSDP_ChecksummedFields](rsdpBaseAddr)
  var rsdpdesc =  cast[RSDP_Descriptor](rsdpBaseAddr)
  var isAcpi_1_0 = false
  if validateRsdpChecksum(rsdphdr):
    debugOut("rsdpchecksum valid!",19)
    outNextLine
    if rsdpdesc.revision == 0:
      debugOut("acpi_1.0 detected ",18)
      isAcpi_1_0 = true 
    elif rsdpdesc.revision >= 2.uint8:
      debugOut("acpi_2.0 detected ",18)
      # todo implement 2.0 handling
    debugOut("rsdt_table at: ",15)
    debugOut(rsdpdesc.rsdtAddr)
    outNextLine
    var rsdt_hdr = cast[ACPI_SDT_Header](rsdpdesc.rsdtAddr)    
    debugOut("oemId: ",7)
    debugOut(rsdt_hdr.oemId.addr,6)      
    outNextLine
    debugOut("oemTableId: ",12)
    debugOut(rsdt_hdr.oemTableId.addr,8)     
    outNextLine
 
    if isRSDTHeader(rsdt_hdr):
      rsdtBaseAddr = rsdt_hdr
      debugOut("rsdt_header_found",17)
      outNextLine

      var acpi_chksumfields = cast[ACPI_ChecksummedFields](rsdt_hdr)
      # little bit hacky
      debugOut("num_entries ",12)
      debugOut(numACPIEntries(rsdt_hdr))    
      outNextLine
     
      if  validateAcpiChecksum(acpi_chksumfields,rsdt_hdr.length.int):
        debugOut("rstd_hdr: checksum_valid",24)
        outNextLine

        var mcfg_idx : int = -1

        for x in countup(0,(numACPIEntries(rsdt_hdr)-1).int):
          var hdrptr = calcACPIPtr(rsdt_hdr,x)
          if isMCFGHeader(hdrptr):            
            mcfg_idx = x
            mcfgCfgHdrPtr = cast[MCFG_Config_Hdr](hdrptr)
            break

        if mcfg_idx > -1:
          debugOut("mcfg_table found",16)
        else:
          debugOut("mcfg_table not found! ",21) 
          # table required for MMIO

        outNextLine
    else:
      debugOut("no RSDT found! please check hw",30)

  else:
    debugOut("rsdpchecksum invalid!",21);
  
 