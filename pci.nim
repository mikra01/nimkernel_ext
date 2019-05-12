# Copyright (c) 2019 Michael Krauter
# MIT license
#
# pci hw detection (brute force method)
# only pci_config method 2 is supported (IOPort)
#
# further information : wiki.osdev.org/PCI
# irqs: https://people.freebsd.org/~jhb/papers/bsdcan/2007/article/node4.html#SECTION00041000000000000000

import ioutils,debugcon

const 
  FUNCTION_NUM_PORT_8 = 0x0CF8.uint16
  FORWARDING_REG_8 = 0x0CFA.uint16
  # regs for config_mode2
  PCI_PORT_BASE = 0xC000.uint16
  
type
  PORTWIDTH = enum pw_8bit,pw_16bit,pw_32bit
  
template getPCIConf2Addr(device : uint16, register : uint8) : uint16 =
  PCI_PORT_BASE.uint16 or (device.uint16 shl 8) or ( register.uint16 ) 
 

const 
  StdHdrLen : uint8 = 64
  PCIBridgeHdrLen : uint8 = 64
  CardbusHdrLen : uint8 = 72
  
  # std header offsets. the size in bits is postfixed
  STD_DeviceID_16 : uint8 = 02
  STD_VendorID_16 : uint8 = 00
  STD_STATUS_16 : uint8 = 04
  STD_CMD_16 : uint8 = 06
  STD_ClassCode_8 : uint8 = 8
  STD_SubClass_8 : uint8 = STD_ClassCode_8+1
  STD_ProgID_8 : uint8 = STD_ClassCode_8+2
  STD_RevId_8 : uint8 = STD_ClassCode_8+3
  BIST_8 : uint8 = 0xc
  HeaderType_8 : uint8 = BIST_8+1
  LatencyTimer_8 : uint8 = BIST_8+2 
  CacheLineSize_8 : uint8 = BIST_8+3
  STD_Bar0_32 : uint8 = 0x10.uint8 
  STD_Bar1_32 : uint8 = STD_Bar0_32+4
  STD_Bar2_32 : uint8 = STD_Bar0_32+8
  STD_Bar3_32 : uint8 = STD_Bar0_32+12
  STD_Bar4_32 : uint8 = STD_Bar0_32+16
  STD_Bar5_32 : uint8 = STD_Bar0_32+20
  ExpRomBase_32 : uint8 = 0x30
  Cardbus_CIS_ptr_32 : uint8 = 0x28
  SubsystemId_16 : uint8 = 0x2c
  SubsystemVendorId_16 : uint8 = SubsystemId_16+2
  IRQ_PIN_8 : uint8 = 0x3C + 2
  IRQ_LINE_8 : uint8 = 0x3C + 3
  
  # pci2pci bridge offsets, the size in bits is postfixed
  # not covered
  
  # cardbus bridge offsets, the size in bits is postfixed
  # not covered
  
# 00h Standard Header - 01h PCI-to-PCI Bridge - 02h CardBus Bridge

type 
  HeaderType = enum StdHdr = 0, PCI2PCIHdr = 1, CardbusHdr = 2
  # if highbit (bit7) set this card is a multifunction card
  
  ClassAndSubclass = enum 
    SCSIBusController = 0x0100.uint16, 
    IDEController= 0x0101,
    FloppyDiscController = 0x0102,
    IPIBusController = 0x0103, 
    RaidController = 0x0104, 
    ATA = 0x0105, 
    SerialATA = 0x0106, 
    SerialSCSI = 0x0107,
    NonVolatileMemController = 0x0108, 
    MassStorageOther = 0x0180,
    # end of mass storage class
    EthernetController = 0x0200,
    TokenRing = 0x0201,
    FDDI = 0x0202,
    ATM = 0x0203,
    ISDN = 0x0204,
    WorldFIP = 0x0205, 
    PICMG = 0x0206,
    Infiniband = 0x0207,
    Fabric = 0x0208,
    NetOther = 0x0280,
    # end of net card class
    VGA =  0x0300,
    XGA  =  0x0301,
    NonVGA =  0x0302,
    DispOther  =  0x0380,
    # end of display class
    MultimediaVideo  =  0x0400,
    MultimediaAudio =  0x0401,
    ComputerTelephony =  0x0402,
    AudiDev =  0x0403,
    MultimediaOther = 0x0480,
    # end of multimedia class
    RamController = 0x0500,
    FlashControler= 0x0501,
    MemoryOther= 0x0580,
    # end of memory class
    HostBridge = 0x0600,
    ISA = 0x0601,
    EISA = 0x0602,
    MCA = 0x0603,
    PCI2PCI2 = 0x0604,
    PCMCIA = 0x0605,
    Nubus = 0x0606,
    Cardbus = 0x0607,
    Raceway = 0x0608,
    PCI2PCI = 0x0609,
    Infiniband2PCI = 0x060A,
    BridgeOther = 0x0680,
    # end of bridge class
    SerialController = 0x0700,
    ParallelController= 0x0701,
    MultiportController= 0x0702,
    Modem= 0x0703,
    IEEE488 = 0x0704,
    SmartCard = 0x0705,
    SimpleCommOther = 0x0780,
    # end of simple communications class
    PIC = 0x0800,
    DMAController= 0x0801,
    Timer= 0x0802,
    RTCController= 0x0803,
    PCIHotplug= 0x0804,
    SDHost= 0x0805,
    IOMMU= 0x0806,
    BaseSysPeriperalOther= 0x0880
    # end of base sys peripheral
    # all other following class/subclass codes are not covered
  
proc readPCIMode2(bus : uint8, device: uint8, function: uint8, register : uint8 , portwidth : PORTWIDTH ) : int32 =
    ## reads the bus at the specified busnum,device function and register with the desired portwidth. 
    ## the obtained value is returned
    # enable bus access 
    writePort(0xcf8.uint16,((function shl 1) or 0xF0).uint8 )
    # set function number
    writePort(0xcfa.uint16,bus.uint8)         
    # select bus
    
    # read value
    case portwidth
    of PORTWIDTH.pw_8bit:
      result = readPort8(getPCIConf2Addr(device,register)).int32
    of PORTWIDTH.pw_16bit:
      result = readPort16(getPCIConf2Addr(device,register)).int32
    of PORTWIDTH.pw_32bit:
      result = readPort32(getPCIConf2Addr(device,register)).int32

    writePort(0xcfa.uint16,0x0.uint8)
    # disable access

proc writePCIMode2(bus:uint8, device:uint8,function:uint8,register:uint8,portwidth:PORTWIDTH, val:uint32) =
    ## writes the pci bus in mode2    
    # enable bus access 
    FUNCTION_NUM_PORT_8.writePort( ((function shl 1) or 0xF0.uint8)   )
    # set function number
    FORWARDING_REG_8.writePort(bus)         
    # select bus

    # write value
    case portwidth
    of PORTWIDTH.pw_8bit:
      writePort(getPCIConf2Addr(device,register),val.uint8)
    of PORTWIDTH.pw_16bit:
      writePort(getPCIConf2Addr(device,register),val.uint16)
    of PORTWIDTH.pw_32bit:
      writePort(getPCIConf2Addr(device,register),val.uint32)

    FUNCTION_NUM_PORT_8.writePort(0x0.uint8)
    # disable access


proc scanDeviceAndVendorByPort*()  =
  ## scans the pci bus for device_id and vendor_id and outputs
  ## the values to the debug_console
  ## we dont scan bridge devices
  ## TODO: does not work like intended - evaluate  
  var vendorid : uint16
  var deviceid: uint16
  
  for busnum in 0.uint8 .. 254:
    for devicenum in 0.uint8 .. 30:
      for funcnum in 0.uint8 .. 6:
        
        vendorid = readPCIMode2(busnum,devicenum,funcnum,0.uint8,PORTWIDTH.pw_16bit).uint16
        deviceid = readPCIMode2(busnum,devicenum,funcnum,2.uint8,PORTWIDTH.pw_16bit).uint16
        # todo: evaluate - doesn't work
        if (vendorid == 0xFFFF.uint16 or deviceid == 0xFFFF.uint16) or (vendorid == 0.uint16 and deviceid == 0.uint16):
          continue
        else:
          debugOut(vendorid)
          debugOut(deviceid)
  
  debugOut("pci device scan finished",24)
  outNextLine


proc checkBAR() =
  discard  

proc fetchVendorID(bus : uint8, device : uint8, function : uint8 = 0) =
  discard

proc getHeaderType(bus : uint8, device : uint8, function : uint8 = 0) =
  discard

proc checkFunction(bus : uint8, device : uint8, function : uint8 = 0) =
  discard
  
proc probeDevice( bus : uint16, device : uint8) =
  discard


