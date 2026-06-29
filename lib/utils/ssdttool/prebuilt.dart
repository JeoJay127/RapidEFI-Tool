//  prebuilt.dart 
//  Created by JeoJay127 
//
class Prebuilt {
  /// SSDT-EC-DESKTOP
  static String get ssdtECDesktop {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "SsdtEC", 0x00001000)
{
''';

    List<String> basePaths = [
      "_SB_.PC00.LPCB",
      "_SB_.PC00.LPC0",
      "_SB_.PC00.LPC_",
      "_SB_.PCI0.LPC0",
      "_SB_.PCI0.LPC_",
      "_SB_.PCI0.LPCB",
      "_SB_.PCI0.PX40",
      "_SB_.PCI0.SBRG",
    ];

    List<String> subDevices = ["EC0_", "EC__", "ECDV", "H_EC", "PGEC"];

    for (String basePath in basePaths) {
      ssdt += '    External ($basePath, DeviceObj)\n';
      for (String dev in subDevices) {
        String devPath = '$basePath.$dev';
        ssdt += '    External ($devPath, DeviceObj)\n';
        ssdt += '    External ($devPath._STA, MethodObj)\n';
      }
    }
    ssdt += '\n';

    for (String basePath in basePaths) {
      for (String dev in subDevices) {
        String baseScopePath = basePath
            .replaceAll(RegExp(r'_+$'), '')
            .replaceAll('_SB', '\\_SB');
        String devScopePath = dev.replaceAll(RegExp(r'_+$'), '');
        String fullPath = "$baseScopePath.$devScopePath";
        ssdt +=
            '''
    If (CondRefOf ($fullPath))
    {
        If ((((CondRefOf ($fullPath._HID) && CondRefOf ($fullPath._CRS)) 
            && CondRefOf ($fullPath._GPE))))
        {
           if (CondRefOf ($fullPath._STA))
           {
              If (!_OSI ("Darwin"))
              {
                   $fullPath._STA()
              }
             
           }Else{
               Scope ($fullPath)
            {
                Method (_STA, 0, NotSerialized)
                {
                    If (_OSI ("Darwin"))
                    {
                        Return (Zero)
                    }
                    Else
                    {
                        Return (0x0F)
                    }
                }
            }
           }
           
        }
    }
''';
      }
    }

    ssdt += r''' 
    Scope (\_SB)
    {
        Device (EC)
        {
            Name (_HID, "ACID0001")  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
    ''';

    ssdt += "\n}\n";
    return ssdt;
  }

  /// SSDT-EC-LAPTOP
  static String get ssdtECLaptop {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "SsdtEC", 0x00001000)
{
''';

    List<String> basePaths = [
      "_SB_.PCI0.LPC0",
      "_SB_.PCI0.LPC_",
      "_SB_.PCI0.LPCB",
    ];

    List<String> subDevices = ["EC__"];

    for (String basePath in basePaths) {
      for (String dev in subDevices) {
        ssdt += '    External ($basePath.$dev, DeviceObj)\n';
      }
    }

    ssdt += '\n';

    ssdt += '    If (';
    List<String> conds = [];

    for (String basePath in basePaths) {
      String scopeBase = basePath
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB');
      for (String dev in subDevices) {
        String devName = dev.replaceAll(RegExp(r'_+$'), '');
        conds.add('!CondRefOf ($scopeBase.$devName)');
      }
    }

    ssdt += conds.join(' && ');
    ssdt += ')\n';

    ssdt += r'''
    {
        Scope (\_SB)
        {
            Device (EC)
            {
                Name (_HID, "ACID0001")  // _HID: Hardware ID
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    If (_OSI ("Darwin"))
                    {
                        Return (0x0F)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }
            }
        }
    }
''';

    ssdt += "\n}\n";
    return ssdt;
  }

  /// SSDT-EC-USBX-DESKTOP
  static String get ssdtECUSBXDesktop {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "SsdtEC", 0x00001000)
{
''';

    List<String> basePaths = [
      "_SB_.PC00.LPCB",
      "_SB_.PC00.LPC0",
      "_SB_.PC00.LPC_",
      "_SB_.PCI0.LPC0",
      "_SB_.PCI0.LPC_",
      "_SB_.PCI0.LPCB",
      "_SB_.PCI0.PX40",
      "_SB_.PCI0.SBRG",
    ];

    List<String> subDevices = ["EC0_", "EC__", "ECDV", "H_EC", "PGEC"];

    for (String basePath in basePaths) {
      ssdt += '    External ($basePath, DeviceObj)\n';
      for (String dev in subDevices) {
        String devPath = '$basePath.$dev';
        ssdt += '    External ($devPath, DeviceObj)\n';
        ssdt += '    External ($devPath._STA, MethodObj)\n';
      }
    }
    ssdt += '\n';

    for (String basePath in basePaths) {
      for (String dev in subDevices) {
        String baseScopePath = basePath
            .replaceAll(RegExp(r'_+$'), '')
            .replaceAll('_SB', '\\_SB');
        String devScopePath = dev.replaceAll(RegExp(r'_+$'), '');
        String fullPath = "$baseScopePath.$devScopePath";
        ssdt +=
            '''
    If (CondRefOf ($fullPath))
    {
        If ((((CondRefOf ($fullPath._HID) && CondRefOf ($fullPath._CRS)) 
            && CondRefOf ($fullPath._GPE))))
        {
           if (CondRefOf ($fullPath._STA))
           {
              If (!_OSI ("Darwin"))
              {
                   $fullPath._STA()
              }
             
           }Else{
               Scope ($fullPath)
            {
                Method (_STA, 0, NotSerialized)
                {
                    If (_OSI ("Darwin"))
                    {
                        Return (Zero)
                    }
                    Else
                    {
                        Return (0x0F)
                    }
                }
            }
           }
        }
    }
''';
      }
    }

    ssdt += r''' 
    Scope (\_SB)
    {
        Device (EC)
        {
            Name (_HID, "ACID0001")  // _HID: Hardware ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
        Device (USBX)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                If ((Arg2 == Zero))
                {
                    Return (Buffer (One)
                    {
                         0x03                                        
                    })
                }

                Return (Package (0x08)
                {
                    "kUSBSleepPowerSupply",
                    0x13EC,
                    "kUSBSleepPortCurrentLimit",
                    0x0834,
                    "kUSBWakePowerSupply",
                    0x13EC,
                    "kUSBWakePortCurrentLimit",
                    0x0834
                })
            }
        }
    }
    ''';

    ssdt += "\n}\n";
    return ssdt;
  }

  /// SSDT-EC-USBX-LAPTOP
  static String get ssdtECUSBXLaptop {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "SsdtEC", 0x00001000)
{
''';

    List<String> basePaths = [
      "_SB_.PCI0.LPC0",
      "_SB_.PCI0.LPC_",
      "_SB_.PCI0.LPCB",
    ];

    List<String> subDevices = ["EC__"];

    for (String basePath in basePaths) {
      for (String dev in subDevices) {
        ssdt += '    External ($basePath.$dev, DeviceObj)\n';
      }
    }

    ssdt += '\n';
    ssdt += '    If (';
    List<String> conds = [];

    for (String basePath in basePaths) {
      String scopeBase = basePath
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB');
      for (String dev in subDevices) {
        String devName = dev.replaceAll(RegExp(r'_+$'), '');
        conds.add('!CondRefOf ($scopeBase.$devName)');
      }
    }

    ssdt += conds.join(' && ');
    ssdt += ')\n';
    ssdt += r'''
    {
        Scope (\_SB)
        {
            Device (EC)
            {
                Name (_HID, "ACID0001")  // _HID: Hardware ID
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    If (_OSI ("Darwin"))
                    {
                        Return (0x0F)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }
            }
          Device (USBX)
          {
              Name (_ADR, Zero)  // _ADR: Address
              Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
              {
                  If ((Arg2 == Zero))
                  {
                      Return (Buffer (One)
                      {
                          0x03                                        
                      })
                  }

                  Return (Package (0x08)
                  {
                      "kUSBSleepPowerSupply",
                      0x13EC,
                      "kUSBSleepPortCurrentLimit",
                      0x0834,
                      "kUSBWakePowerSupply",
                      0x13EC,
                      "kUSBWakePortCurrentLimit",
                      0x0834
                  })
              }
          }
        }
    }
''';

    ssdt += "\n}\n";
    return ssdt;
  }

  /// SSDT-PLUG
  static String get ssdtPLUG {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "CpuPlug", 0x00001000)
{
''';

    List<String> basePaths = [
      "_PR_.CPU0",
      "_PR_.CP00",
      "_PR_.C000",
      "_PR_.P000",
      "_PR_.PR00",
      "_SB_.CPU0",
      "_SB_.PR00",
      "_SB_.SCK0.CP00",
      "_SB_.SCK0.PR00",
    ];

    for (String basePath in basePaths) {
      ssdt += '    External ($basePath, ProcessorObj)\n';
    }

    ssdt += '\n';

    ssdt += '''
    Method (PMPM, 4, NotSerialized)
    {
            If ((Arg2 == Zero))
            {
                Return (Buffer (One)
                {
                    0x03                                             // .
                })
            }

            Return (Package (0x02)
            {
                "plugin-type", 
                One
            })
   }
''';
    ssdt += '\n';
    for (String basePath in basePaths) {
      String devName = basePath
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB')
          .replaceAll('_PR_', '\\_PR');

      ssdt += 'If(CondRefOf ($devName))';
      ssdt +=
          '''
    {
      If ((ObjectType ($devName) == 0x0C))
      {
          Scope ($devName)
          {
              Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
              {
                  Return (PMPM (Arg0, Arg1, Arg2, Arg3))
              }
          }
      }
   }        
''';
    }
    ssdt += "\n}\n";
    return ssdt;
  }

  /// SSDT-PLUG-ALT
  static String get ssdtPLUGALT {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "CpuPlugA", 0x00001000)
{
    External (_SB_, DeviceObj)

    Scope (\\_SB)
    {
''';

    for (int i = 0; i < 64; i++) {
      String cpuName = i < 10 ? 'CP0$i' : 'CP$i';
      String cpuIDHex =
          '0x${i.toRadixString(16).padLeft(2, '0').toUpperCase()}';
      String uid = i == 0 ? 'Zero' : cpuIDHex;

      ssdt +=
          '''
        Processor ($cpuName, $cpuIDHex, 0x00000510, 0x06)
        {
            Name (_HID, "ACPI0007" /* Processor Device */)
            Name (_UID, $uid)
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
''';

      if (i == 0) {
        ssdt += '''
            Method (_DSM, 4, NotSerialized)
            {
                If ((Arg2 == Zero))
                {
                    Return (Buffer (One)
                    {
                         0x03
                    })
                }

                Return (Package (0x02)
                {
                    "plugin-type", 
                    One
                })
            }
''';
      }

      ssdt += '        }\n\n';
    }

    ssdt += '    }\n}';
    return ssdt;
  }

  /// SSDT-AWAC
  static String get ssdtAWAC {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "NOAWAC", 0x00000000)
{
    External (STAS, IntObj)

    Scope (_SB)
    {
        If (_OSI ("Darwin"))
        {
            STAS = One
        }
    }
}
''';
    return ssdt;
  }

  /// SSDT-PNLF
  static String get ssdtPNLF {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "PNLF", 0x00000000)
{
''';

    List<String> basePaths = [
      "_SB_.PCI0.GFX0",
      "_SB_.PCI0.VID",
      "_SB_.PCI0.VID0",
      "_SB_.PCI0.IGPU",
    ];

    for (String basePath in basePaths) {
      ssdt += '    External ($basePath, DeviceObj)\n';
    }

    ssdt += '    External (RMCF.BKLT, IntObj)\n';
    ssdt += '    External (RMCF.FBTP, IntObj)\n';
    ssdt += '    External (RMCF.GRAN, IntObj)\n';
    ssdt += '    External (RMCF.LEVW, IntObj)\n';
    ssdt += '    External (RMCF.LMAX, IntObj)\n';

    ssdt += r'''  
    If (_OSI ("Darwin"))
    {
    
    ''';
    for (String basePath in basePaths) {
      String devName = basePath
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB');
      ssdt +=
          '''
      If (CondRefOf ($devName))
      {
            Scope ($devName)
            {
                Device (XNLF)
                {
                    Name (_ADR, Zero)
                }

                Alias (XNLF, PNLF)
            }
      }
''';
    }
    ssdt += r'''
    Device (PNLF)
            {
                Name (_HID, EisaId ("APP0002"))  // _HID: Hardware ID
                Name (_CID, "backlight")  // _CID: Compatible ID
                Name (_UID, Zero)  // _UID: Unique ID
                Name (_STA, 0x0B)  // _STA: Status
                OperationRegion (RMP3, PCI_Config, Zero, 0x14)
                Field (RMP3, AnyAcc, NoLock, Preserve)
                {
                    Offset (0x02), 
                    GDID,   16, 
                    Offset (0x10), 
                    BAR1,   32
                }

                OperationRegion (RMB1, SystemMemory, (BAR1 & 0xFFFFFFFFFFFFFFF0), 0x000E1184)
                Field (RMB1, AnyAcc, Lock, Preserve)
                {
                    Offset (0x48250), 
                    LEV2,   32, 
                    LEVL,   32, 
                    Offset (0x70040), 
                    P0BL,   32, 
                    Offset (0xC2000), 
                    GRAN,   32, 
                    Offset (0xC8250), 
                    LEVW,   32, 
                    LEVX,   32, 
                    LEVD,   32, 
                    Offset (0xE1180), 
                    PCHL,   32
                }

                Method (INI1, 1, NotSerialized)
                {
                    If ((Zero == (0x02 & Arg0)))
                    {
                        Local5 = 0xC0000000
                        If (CondRefOf (\RMCF.LEVW))
                        {
                            If ((Ones != \RMCF.LEVW))
                            {
                                Local5 = \RMCF.LEVW /* External reference */
                            }
                        }

                        ^LEVW = Local5
                    }

                    If ((0x04 & Arg0))
                    {
                        If (CondRefOf (\RMCF.GRAN))
                        {
                            ^GRAN = \RMCF.GRAN /* External reference */
                        }
                        Else
                        {
                            ^GRAN = Zero
                        }
                    }
                }

                Method (_INI, 0, NotSerialized)  // _INI: Initialize
                {
                    Local4 = One
                    If (CondRefOf (\RMCF.BKLT))
                    {
                        Local4 = \RMCF.BKLT /* External reference */
                    }

                    If (!(One & Local4))
                    {
                        Return (Zero)
                    }

                    Local0 = ^GDID /* \_SB_.PCI0.GFX0.PNLF.GDID */
                    Local2 = Ones
                    If (CondRefOf (\RMCF.LMAX))
                    {
                        Local2 = \RMCF.LMAX /* External reference */
                    }

                    Local3 = Zero
                    If (CondRefOf (\RMCF.FBTP))
                    {
                        Local3 = \RMCF.FBTP /* External reference */
                    }

                    If (((One == Local3) || (Ones != Match (Package (0x10)
                                        {
                                            0x010B, 
                                            0x0102, 
                                            0x0106, 
                                            0x1106, 
                                            0x1601, 
                                            0x0116, 
                                            0x0126, 
                                            0x0112, 
                                            0x0122, 
                                            0x0152, 
                                            0x0156, 
                                            0x0162, 
                                            0x0166, 
                                            0x016A, 
                                            0x46, 
                                            0x42
                                        }, MEQ, Local0, MTR, Zero, Zero))))
                    {
                        If ((Ones == Local2))
                        {
                            Local2 = 0x0710
                        }

                        Local1 = (^LEVX >> 0x10)
                        If (!Local1)
                        {
                            Local1 = Local2
                        }

                        If ((!(0x08 & Local4) && (Local2 != Local1)))
                        {
                            Local0 = ((^LEVL * Local2) / Local1)
                            Local3 = (Local2 << 0x10)
                            If ((Local2 > Local1))
                            {
                                ^LEVX = Local3
                                ^LEVL = Local0
                            }
                            Else
                            {
                                ^LEVL = Local0
                                ^LEVX = Local3
                            }
                        }
                    }
                    ElseIf (((0x03 == Local3) || (Ones != Match (Package (0x19)
                                        {
                                            0x3E9B, 
                                            0x3EA5, 
                                            0x3E92, 
                                            0x3E91, 
                                            0x3EA0, 
                                            0x3EA6, 
                                            0x3E98, 
                                            0x9BC8, 
                                            0x9BC5, 
                                            0x9BC4, 
                                            0xFF05, 
                                            0x8A70, 
                                            0x8A71, 
                                            0x8A51, 
                                            0x8A5C, 
                                            0x8A5D, 
                                            0x8A52, 
                                            0x8A53, 
                                            0x8A56, 
                                            0x8A5A, 
                                            0x8A5B, 
                                            0x9B41, 
                                            0x9B21, 
                                            0x9BCA, 
                                            0x9BA4
                                        }, MEQ, Local0, MTR, Zero, Zero))))
                    {
                        If ((Ones == Local2))
                        {
                            Local2 = 0xFFFF
                        }
                    }
                    Else
                    {
                        If ((Ones == Local2))
                        {
                            If ((Ones != Match (Package (0x16)
                                            {
                                                0x0D26, 
                                                0x0A26, 
                                                0x0D22, 
                                                0x0412, 
                                                0x0416, 
                                                0x0A16, 
                                                0x0A1E, 
                                                0x0A1E, 
                                                0x0A2E, 
                                                0x041E, 
                                                0x041A, 
                                                0x0BD1, 
                                                0x0BD2, 
                                                0x0BD3, 
                                                0x1606, 
                                                0x160E, 
                                                0x1616, 
                                                0x161E, 
                                                0x1626, 
                                                0x1622, 
                                                0x1612, 
                                                0x162B
                                            }, MEQ, Local0, MTR, Zero, Zero)))
                            {
                                Local2 = 0x0AD9
                            }
                            Else
                            {
                                Local2 = 0x056C
                            }
                        }

                        INI1 (Local4)
                        Local1 = (^LEVX >> 0x10)
                        If (!Local1)
                        {
                            Local1 = Local2
                        }

                        If ((!(0x08 & Local4) && (Local2 != Local1)))
                        {
                            Local0 = ((((^LEVX & 0xFFFF) * Local2) / Local1) | 
                                (Local2 << 0x10))
                            ^LEVX = Local0
                        }
                    }

                    If ((Local2 == 0x0710))
                    {
                        _UID = 0x0E
                    }
                    ElseIf ((Local2 == 0x0AD9))
                    {
                        _UID = 0x0F
                    }
                    ElseIf ((Local2 == 0x056C))
                    {
                        _UID = 0x10
                    }
                    ElseIf ((Local2 == 0x07A1))
                    {
                        _UID = 0x11
                    }
                    ElseIf ((Local2 == 0x1499))
                    {
                        _UID = 0x12
                    }
                    ElseIf ((Local2 == 0xFFFF))
                    {
                        _UID = 0x13
                    }
                    Else
                    {
                        _UID = 0x63
                    }
                }
            }
''';
    ssdt += "\n}\n}";
    return ssdt;
  }

  /// SSDT-PMC
  static String get ssdtPMC {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "PMCR", 0x00001000)
{
''';

    List<String> basePaths = [
      "_SB_.PCI0.LPCB",
      "_SB_.PCI0.LPC",
      "_SB_.PCI0.LPC0",
      "_SB_.PC00.LPCB",
      "_SB_.PC00.LPC",
      "_SB_.PC00.LPC0",
    ];

    for (String basePath in basePaths) {
      ssdt += '    External ($basePath, DeviceObj)\n';
    }

    ssdt += '\n';
    for (String basePath in basePaths) {
      String devName = basePath
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB');
      ssdt += 'If(CondRefOf ($devName))';
      ssdt +=
          '''
    {
        Scope ($devName)
        {
                  Device (PMCR)
                  {
                      Name (_HID, EisaId ("APP9876"))  // _HID: Hardware ID
                      Method (_STA, 0, NotSerialized)  // _STA: Status
                      {
                          If (_OSI ("Darwin"))
                          {
                              Return (0x0B)
                          }
                          Else
                          {
                              Return (Zero)
                          }
                      }

                      Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                      {
                          Memory32Fixed (ReadWrite,
                              0xFE000000,         // Address Base
                              0x00010000,         // Address Length
                              )
                      })
                  }
        }
   }        
''';
    }
    ssdt += "\n}\n";
    return ssdt;
  }

  /// SSDT-XOSI
  static String get ssdtXOSI {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "XOSI", 0x00001000)
{
    Method (XOSI, 1, NotSerialized)
    {
        // Based off of: 
        // https://docs.microsoft.com/en-us/windows-hardware/drivers/acpi/winacpi-osi#_osi-strings-for-windows-operating-systems
        // Add OSes from the above list as needed, most only check up to Windows 2015
        // but check what your DSDT looks for
        Local0 = Package ()
            {
                "Windows 2001", 
                "Windows 2001.1", 
                "Windows 2001 SP1", 
                "Windows 2001 SP2", 
                "Windows 2001 SP3", 
                "Windows 2006", 
                "Windows 2006 SP1", 
                "Windows 2009", 
                "Windows 2012", 
                "Windows 2013",
                "Windows 2015",
                "Windows 2016",
                "Windows 2017",
                "Windows 2018",
                "Windows 2019",
                "Windows 2020",
                "Windows 2021",
                "Microsoft Windows NT", 
                "Microsoft Windows", 
                "Microsoft WindowsME: Millennium Edition"
            }
        If (_OSI ("Darwin"))
        {
            Return ((Ones != Match (Local0, MEQ, Arg0, MTR, Zero, Zero)))
        }
        Else
        {
            Return (_OSI (Arg0))
        }
    }
}
''';
    return ssdt;
  }

  /// SSDT-IMEI
  static String get ssdtIMEI {
    return r'''
DefinitionBlock ("", "SSDT", 2, "RAPID", "IMEI", 0x00000000)
{
    External (_SB_.PCI0, DeviceObj)
    External (_SB_.PCI0.IMEI, DeviceObj)
    External (_SB_.PCI0.HECI, DeviceObj)
    External (_SB_.PCI0.MEI, DeviceObj)

    If ((!CondRefOf (\_SB.PCI0.IMEI) && !CondRefOf (\_SB.PCI0.HECI) && !CondRefOf (\_SB.PCI0.MEI)))
    {
        Scope (_SB.PCI0)
        {
            Device (IMEI)
            {
                Name (_ADR, 0x00160000)  // _ADR: Address
            }
        }
    }
}
''';
  }

  static String get ssdtIMEIFakeId {
    return """
 DefinitionBlock ("", "SSDT", 2, "RAPID", "IMEI", 0x00000000)
{
    External (_SB_.PCI0.IMEI, DeviceObj)

    Scope (_SB_.PCI0)
    {
        Device (IMEI)
        {
            Name (_ADR, 0x00160000)
            Method (_DSM, 4, NotSerialized)
            {
                If (LEqual (Arg2, Zero)) {
                    Return (Buffer (One) { 0x03 })
                }
                Return (Package (0x02)
                {
                    "device-id",
                    Buffer (0x04) { 0x3A, 0x1[[FAKEID]], 0x00, 0x00 }
                })
            }
        }
    }
}

 """;
  }

  /// SSDT-RHUB
  static String get ssdtRHUB {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "RhubOff", 0x00001000)
{
''';

    List<String> basePaths = [
      "_SB_.PCI0.XHCI.RHUB",
      "_SB_.PCI0.XHC1.RHUB",
      "_SB_.PCI0.XHC_.RHUB",
      "_SB_.PC00.XHCI.RHUB",
      "_SB_.PC00.XHC1.RHUB",
      "_SB_.PC00.XHC_.RHUB",
    ];

    for (String basePath in basePaths) {
      ssdt += '    External ($basePath, DeviceObj)\n';
    }

    ssdt += '\n';
    for (String basePath in basePaths) {
      String devName = basePath
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB');
      ssdt += 'If(CondRefOf ($devName))';
      ssdt +=
          '''
    {
        Scope ($devName)
        {
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (0x0F)
                }
            }
        }
   }        
''';
    }
    ssdt += "\n}\n";
    return ssdt;
  }

  /// SSDT-RTC0-RANGE
  static String get ssdtRTC0RANGE {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "RtcRange", 0x00001000)
{
''';

    List<String> basePCIPaths = ["_SB_.PC00", "_SB_.PCI0"];
    List<String> baseLPCPaths = ["LPC0", "LPC_", "LPCB", "SBRG"];
    List<String> subDevices = ["RTC0", "RTC_"];

    for (String basePath in basePCIPaths) {
      ssdt += '    External ($basePath, DeviceObj)\n';
      for (String lpc in baseLPCPaths) {
        for (String dev in subDevices) {
          ssdt += '    External ($basePath.$lpc.$dev, DeviceObj)\n';
        }
      }
    }
    ssdt += "\n";
    for (String basePath in basePCIPaths) {
      String pciBase = basePath
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB');
      for (String lpc in baseLPCPaths) {
        int rtcIndex = 1;

        for (String dev in subDevices) {
          String devScopePath = dev.replaceAll(RegExp(r'_+$'), '');
          String fullPath = "$pciBase.$lpc.$devScopePath";
          String basePath = "$pciBase.$lpc";
          String newDevice = 'RTC$rtcIndex';
          ssdt +=
              '''
    If (CondRefOf ($fullPath))
    {
        Device ($basePath.$newDevice)
        {
            Name (_HID, EisaId ("PNP0B00"))
            Name (_CRS, ResourceTemplate ()
            {
                    IO (Decode16,
                    0x0070,             // Range Minimum
                    0x0070,             // Range Maximum
                    0x01,               // Alignment
                    0x04,               // Length
                    )
                IO (Decode16,
                    0x0074,             // Range Minimum
                    0x0074,             // Range Maximum
                    0x01,               // Alignment
                    0x04,               // Length
                    )
                IRQNoFlags ()
                    {8}
            })
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }

        If (!CondRefOf ($fullPath._STA))
        {
            Scope ($fullPath)
            {
                Method (_STA, 0, NotSerialized)
                {
                  If (_OSI ("Darwin"))
                    {
                        Return (Zero)
                    }
                    Else
                    {
                        Return (0x0F)
                    }
                }
            }
        }
    }
            ''';
          rtcIndex++;
        }
      }
    }

    ssdt += '\n}';

    return ssdt;
  }

  /// SSDT-ALS0
  static const String ssdtALS0 = """ 
  DefinitionBlock ("", "SSDT", 2, "RAPID", "ALS0", 0x00000000)
{
    Scope (_SB)
    {
        Device (ALS0)
        {
            Name (_HID, "ACPI0008" /* Ambient Light Sensor Device */)  // _HID: Hardware ID
            Name (_CID, "smc-als")  // _CID: Compatible ID
            Name (_ALI, 0x012C)  // _ALI: Ambient Light Illuminance
            Name (_ALR, Package (0x01)  // _ALR: Ambient Light Response
            {
                Package (0x02)
                {
                    0x64, 
                    0x012C
                }
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}
  """;

  /// SSDT-GPRW
  static const String ssdtGPRW = """
/*
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000065 (101)
 *     Revision         0x02
 *     Checksum         0x87
 *     OEM ID           "RAPID"
 *     OEM Table ID     "GPRW"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200528 (538969384)
 */
DefinitionBlock ("", "SSDT", 2, "RAPID", "GPRW", 0x00000000)
{
    External (XPRW, MethodObj)    // 2 Arguments

    Method (GPRW, 2, NotSerialized)
    {
        If (_OSI ("Darwin"))
        {
            If ((0x6D == Arg0))
            {
                Return (Package (0x02)
                {
                    0x6D, 
                    Zero
                })
            }

            If ((0x0D == Arg0))
            {
                Return (Package (0x02)
                {
                    0x0D, 
                    Zero
                })
            }
        }

        Return (XPRW (Arg0, Arg1))
    }
}

""";

  /// SSDT-UPRW
  static const String ssdtUPRW = """
/*
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000065 (101)
 *     Revision         0x02
 *     Checksum         0x87
 *     OEM ID           "RAPID"
 *     OEM Table ID     "UPRW"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200528 (538969384)
 */
DefinitionBlock ("", "SSDT", 2, "RAPID", "UPRW", 0x00000000)
{
    External (XPRW, MethodObj)    // 2 Arguments

    Method (UPRW, 2, NotSerialized)
    {
        If (_OSI ("Darwin"))
        {
            If ((0x6D == Arg0))
            {
                Return (Package (0x02)
                {
                    0x6D, 
                    Zero
                })
            }

            If ((0x0D == Arg0))
            {
                Return (Package (0x02)
                {
                    0x0D, 
                    Zero
                })
            }
        }

        Return (XPRW (Arg0, Arg1))
    }
} 
""";

  /// SSDT-UNC
  /// Fixing Uncore Bridges (X79/C602,X99/C612 Required)
  static const String ssdtUNC = """ 
  /*
 * Discovered on X99-series.
 * These platforms have uncore PCI bridges for 4 CPU sockets
 * present in ACPI despite having none physically.
 *
 * Under normal conditions these are disabled depending on
 * CPU presence in the socket via Processor Bit Mask (PRBM),
 * but on X99 this code is unused or broken as such bridges
 * simply do not exist. We fix that by writing 0 to PRBM.
 *
 * Doing so is important as starting with macOS 11 IOPCIFamily
 * will crash as soon as it sees non-existent PCI bridges.
 */

DefinitionBlock ("", "SSDT", 2, "RAPID", "UNC", 0x00000000)
{
    External (_SB.UNC0, DeviceObj)
    External (_SB_.UNC1, DeviceObj)
    External (_SB_.UNC2, DeviceObj)
    External (_SB_.UNC3, DeviceObj)
    External (PRBM, IntObj)

    Scope (_SB.UNC0)
    {
        Method (_INI, 0, NotSerialized)
        {
            // In most cases this patch does benefit all operating systems,
            // yet on select pre-Windows 10 it may cause issues.
            // Remove If (_OSI ("Darwin")) in case you have none.
            If (_OSI ("Darwin")) {
                PRBM = 0
            }
        }
    }
    Scope (_SB.UNC1)
    {
        Method (_INI, 0, NotSerialized)  
        {
            If (_OSI ("Darwin"))
            {
                PRBM = Zero
            }
        }
    }

    Scope (_SB.UNC2)
    {
        Method (_INI, 0, NotSerialized) 
        {
            If (_OSI ("Darwin"))
            {
                PRBM = Zero
            }
        }
    }

    Scope (_SB.UNC3)
    {
        Method (_INI, 0, NotSerialized)  
        {
            If (_OSI ("Darwin"))
            {
                PRBM = Zero
            }
        }
    }
}
  """;

  /// SSDT-CPUR
  static String get ssdtCPUR {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "CPUR", 0x00003000)
{
''';

    for (int i = 0; i <= 31; i++) {
      String suffix = i.toRadixString(16).toUpperCase().padLeft(3, '0');
      ssdt += '    External (_SB_.PLTF.C$suffix, DeviceObj)\n';
    }

    ssdt += '''
    Scope (\\_SB)
    {
''';

    for (int i = 0; i <= 31; i++) {
      String id = i.toRadixString(16).toUpperCase().padLeft(2, '0');
      String suffix = i.toRadixString(16).toUpperCase().padLeft(3, '0');
      ssdt += '        Processor (PR$id, 0x$id, 0x00000810, 0x06)\n        {\n';

      if (i <= 11) {
        ssdt += '            Return (\\_SB.PLTF.C$suffix)\n';
      } else {
        ssdt += '            If (CondRefOf (\\_SB.PLTF.C$suffix))\n';
        ssdt += '            {\n';
        ssdt += '                Return (\\_SB.PLTF.C$suffix)\n';
        ssdt += '            }\n';
      }
      ssdt += '        }\n\n';
    }

    ssdt += '    }\n}\n';

    return ssdt;
  }

  /// SSDT-GPI0
  static const String ssdtGPI0 = r"""

/*
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000057 (87)
 *     Revision         0x02
 *     Checksum         0x3D
 *     OEM ID           "RAPID"
 *     OEM Table ID     "GPI0"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200110 (538968336)
 */
DefinitionBlock ("", "SSDT", 2, "RAPID", "GPI0", 0x00000000)
{
    External (GPEN, FieldUnitObj)

    Scope (\)
    {
        If (_OSI ("Darwin"))
        {
            If (CondRefOf (\GPEN)) { GPEN = One }
        }
    }
}
""";

  /// ssdtRMNE
  static const String ssdtRMNE = """
/*
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000000D4 (212)
 *     Revision         0x02
 *     Checksum         0xF3
 *     OEM ID           "RAPID"
 *     OEM Table ID     "RMNE"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20160422 (538313762)
 */
DefinitionBlock ("", "SSDT", 2, "RAPID", "RMNE", 0x00001000)
{
    Device (RMNE)
    {
        Name (_ADR, Zero)  // _ADR: Address
        Name (_HID, "NULE0000")  // _HID: Hardware ID
        Name (MAC, Buffer (0x06)
        {
             0x11, 0x22, 0x33, 0x44, 0x55, 0x66                     //.
        })
        Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
        {
            If ((Arg2 == Zero))
            {
                Return (Buffer (One)
                {
                     0x03                                             // .
                })
            }

            Return (Package (0x0A)
            {
                "built-in", 
                Buffer (One)
                {
                     0x00                                             // .
                }, 

                "IOName", 
                "ethernet", 
                "name", 
                Buffer (0x09)
                {
                    "ethernet"
                }, 

                "model", 
                Buffer (0x15)
                {
                    "RM-NullEthernet-1001"
                }, 

                "device_type", 
                Buffer (0x09)
                {
                    "ethernet"
                }
            })
        }
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (0x0F)
            }
            Else
            {
                Return (Zero)
            }
        }
    }
}

""";

  static const String ssdtFixShutdown = r"""
DefinitionBlock ("", "SSDT", 2, "RAPID", "ZPTS", 0x00000000)
{
    External (_SB_.PCI0.XHC_.PMEE, FieldUnitObj)
    External (ZPTS, MethodObj)    

    Method (_PTS, 1, NotSerialized)  
    {
        ZPTS (Arg0)
        If ((0x05 == Arg0))
        {
            \_SB.PCI0.XHC.PMEE = Zero
        }
    }
}
""";

  /// SSDT-SBUS-MCHC
  static String get ssdtSBUSMCHC {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "SBUSMCHC", 0x00001000)
{
''';

    List<String> basePaths = ["_SB_.PCI0", "_SB_.PC00"];

    List<String> subDevices = ["SBUS"];

    for (String basePath in basePaths) {
      ssdt += '    External ($basePath, DeviceObj)\n';
      for (String dev in subDevices) {
        ssdt += '    External ($basePath.$dev, DeviceObj)\n';
      }
    }

    ssdt += '\n';
    for (String basePath in basePaths) {
      ssdt += '    If (';
      List<String> conds = [];
      String scopeBase = basePath
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB');
      for (String dev in subDevices) {
        String devName = dev.replaceAll(RegExp(r'_+$'), '');
        conds.add('!CondRefOf ($scopeBase.$devName)');
        ssdt += conds.join(' && ');
        ssdt += ')\n';

        ssdt +=
            '''
        {
            Scope ($scopeBase)
        {
            Device ($devName)
            {
                Name (_ADR, Zero)  // _ADR: Address
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    If (_OSI ("Darwin"))
                    {
                        Return (0x0F)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }
            }
        }
            Device ($scopeBase.$devName.BUS0)
    {
        Name (_CID, "smbus")  // _CID: Compatible ID
        Name (_ADR, Zero)  // _ADR: Address
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If (_OSI ("Darwin"))
            {
                Return (0x0F)
            }
            Else
            {
                Return (Zero)
            }
        }
    }
        }
    ''';
      }
    }

    ssdt += "\n}\n";
    return ssdt;
  }

  static const String ssdtDTGP = """ 

DefinitionBlock ("", "SSDT", 2, "RAPID", "DTGP", 0x00001000)
{
    Method (DTGP, 5, NotSerialized)
    {
        If ((Arg0 == ToUUID ("a0b5b7c6-1318-441c-b0c9-fe695eaf949b")))
        {
            If ((Arg1 == One))
            {
                If ((Arg2 == Zero))
                {
                    Arg4 = Buffer (One)
                        {
                             0x03                                          
                        }
                    Return (One)
                }

                If ((Arg2 == One))
                {
                    Return (One)
                }
            }
        }

        Arg4 = Buffer (One)
            {
                 0x00                                            
            }
        Return (Zero)
    }
}

""";

  static String get ssdtDMAC {
    String ssdt = '''
DefinitionBlock ("", "SSDT", 2, "RAPID", "DMAC", 0x00000000)
{
''';

    List<String> basePaths = [
      "_SB_.PCI0.LPCB",
      "_SB_.PCI0.LPC",
      "_SB_.PCI0.LPC0",
      "_SB_.PC00.LPCB",
      "_SB_.PC00.LPC",
      "_SB_.PC00.LPC0",
      "_SB_.PCI0.PX40",
      "_SB_.PCI0.SBRG",
    ];

    for (String basePath in basePaths) {
      ssdt += '    External ($basePath, DeviceObj)\n';
    }

    ssdt += '\n';
    for (String basePath in basePaths) {
      String devName = basePath
          .replaceAll(RegExp(r'_+$'), '')
          .replaceAll('_SB_', '\\_SB');
      ssdt += 'If(CondRefOf ($devName))';
      ssdt +=
          '''
    {
        Scope ($devName)
        {
                  Device (DMAC)
                  {
                      Name (_HID, EisaId ("PNP0200"))  // _HID: Hardware ID
                      Method (_STA, 0, NotSerialized)  // _STA: Status
                      {
                          If (_OSI ("Darwin"))
                          {
                              Return (0x0F)
                          }
                          Else
                          {
                              Return (Zero)
                          }
                      }

                      Name (_CRS, ResourceTemplate ()
                      {
                          IO (Decode16,
                              0x0000,             // Range Minimum
                              0x0000,             // Range Maximum
                              0x01,               // Alignment
                              0x20,               // Length
                              )
                          IO (Decode16,
                              0x0081,             // Range Minimum
                              0x0081,             // Range Maximum
                              0x01,               // Alignment
                              0x11,               // Length
                              )
                          IO (Decode16,
                              0x0093,             // Range Minimum
                              0x0093,             // Range Maximum
                              0x01,               // Alignment
                              0x0D,               // Length
                              )
                          IO (Decode16,
                              0x00C0,             // Range Minimum
                              0x00C0,             // Range Maximum
                              0x01,               // Alignment
                              0x20,               // Length
                              )
                          DMA (Compatibility, NotBusMaster, Transfer8_16, )
                              {4}
                      })
                  }
        }
   }        
''';
    }
    ssdt += "\n}\n";
    return ssdt;
  }

  static const String ssdtS3Disable = """

DefinitionBlock("", "SSDT", 2, "RAPID", "S3-Disable", 0)
{
    External (XS3, MethodObj)
    
    If (_OSI ("Darwin"))
    {
        //
    }
    Else
    {
        Method (_S3, 0, NotSerialized)
        {
            Return(XS3 ())
        }
    }
}

""";

  static const String ssdtPWRB = r"""

DefinitionBlock("", "SSDT", 2, "RAPID", "PWRB", 0)
{
    Scope (\_SB)
    {
        Device (PWRB)
        {
            Name (_HID, EisaId ("PNP0C0C"))
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}

""";

  static const String ssdtSLPB = r"""

DefinitionBlock("", "SSDT", 2, "RAPID", "SLPB", 0)
{
    Scope (\_SB)
    {
        Device (SLPB)
        {
            Name (_HID, EisaId ("PNP0C0E"))
            Method (_STA, 0, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0B)
                }
                Else
                {
                    Return (Zero)
                }
            }
        }
    }
}

""";

  static const String ssdtMEM2 = """ 

DefinitionBlock ("", "SSDT", 2, "RAPID", "MEM2", 0)
{
    Device (MEM2)
    {
        Name (_HID, EisaId ("PNP0C01"))
        Name (_UID, 0x02)
        Name (CRS, ResourceTemplate ()
        {
            Memory32Fixed (ReadWrite,
                0x20000000,         // Address Base
                0x00200000,         // Address Length
                )
            Memory32Fixed (ReadWrite,
                0x40000000,         // Address Base
                0x00200000,         // Address Length
                )
        })
        Method (_CRS, 0, NotSerialized)
        {
            Return (CRS)
        }
        
        Method (_STA, 0, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                Return (0x0F)
            }
            Else
            {
                Return (Zero)
            }
        }
    }
}

 """;
}
