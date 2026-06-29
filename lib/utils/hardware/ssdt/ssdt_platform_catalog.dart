import 'package:rapidefi/utils/config/models/enums/config_enums.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_configs.dart';
import 'package:rapidefi/utils/config/presets/platform_profiles/platform_profile.dart';
import 'package:rapidefi/utils/hardware/ssdt/ssdt_selection.dart';
import 'package:rapidefi/utils/ssdttool/table.dart';

class SsdtPlatformCatalog {
  const SsdtPlatformCatalog._();

  static const _optionalDesktop = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtPWRB,
    ACPITable.ssdtSLPB,
  ];

  static const _optionalLaptop = [
    ACPITable.ssdtSBUSMCHC,
    ACPITable.ssdtGPRW,
    ACPITable.ssdtFixShutdown,
    ACPITable.ssdtFACP,
    ACPITable.ssdtRMNE,
    ACPITable.ssdtDMAC,
    ACPITable.ssdtSLPB,
    ACPITable.ssdtPWRB,
  ];

  static const _recommendedLaptopSupplement = [
    ACPITable.ssdtLID,
    ACPITable.ssdtWakeScreen,
    ACPITable.ssdtLED,
  ];

  static const _intelDesktop = {
    'penryn': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop],
      recommend: [ACPITable.ssdtHPET],
      optional: _optionalDesktop,
    ),
    'lynnfield': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop],
      recommend: [ACPITable.ssdtHPET],
      optional: _optionalDesktop,
    ),
    'sandy_bridge': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop],
      recommend: [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1C'},
      ],
      optional: _optionalDesktop,
    ),
    'ivy_bridge': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop],
      recommend: [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1E'},
        ACPITable.ssdtDMAR,
      ],
      optional: _optionalDesktop,
    ),
    'haswell': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: [..._optionalDesktop, ACPITable.ssdtMEM2],
    ),
    'broadwell': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: [..._optionalDesktop, ACPITable.ssdtMEM2],
    ),
    'skylake': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: [..._optionalDesktop, ACPITable.ssdtMEM2],
    ),
    'kaby_lake': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: [..._optionalDesktop, ACPITable.ssdtMEM2],
    ),
    'coffee_lake_8th': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'coffee_lake_9th': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'comet_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'rocket_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'alder_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
      ],
      recommend: [
        ACPITable.ssdtRHUB,
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtDMAR,
      ],
      optional: _optionalDesktop,
    ),
    'raptor_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtPMC],
      optional: _optionalDesktop,
    ),
    'raptor_lake_refresh': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtPMC],
      optional: _optionalDesktop,
    ),
    'arrow_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtPMC],
      optional: _optionalDesktop,
    ),
  };

  static const _intelLaptop = {
    'penryn': _SsdtRule(
      basic: [
        ACPITable.ssdtECLaptop,
        {...ACPITable.ssdtPNLF, 'extra': 14},
      ],
      recommend: [ACPITable.ssdtHPET],
      optional: _optionalLaptop,
    ),
    'clarksfield_arrandale': _SsdtRule(
      basic: [
        ACPITable.ssdtECLaptop,
        {...ACPITable.ssdtPNLF, 'extra': 14},
      ],
      recommend: [ACPITable.ssdtHPET],
      optional: _optionalLaptop,
    ),
    'sandy_bridge': _SsdtRule(
      basic: [
        ACPITable.ssdtECLaptop,
        {...ACPITable.ssdtPNLF, 'extra': 14},
      ],
      recommend: [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1C'},
      ],
      optional: _optionalLaptop,
    ),
    'ivy_bridge': _SsdtRule(
      basic: [
        ACPITable.ssdtECLaptop,
        {...ACPITable.ssdtPNLF, 'extra': 14},
      ],
      recommend: [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1E'},
        ACPITable.ssdtALS0,
        ACPITable.ssdtDMAR,
      ],
      optional: _optionalLaptop,
    ),
    'haswell': _SsdtRule(
      basic: [
        ACPITable.ssdtECLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 15},
        ACPITable.ssdtXOSI,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop, ACPITable.ssdtMEM2],
    ),
    'broadwell': _SsdtRule(
      basic: [
        ACPITable.ssdtECLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 15},
        ACPITable.ssdtXOSI,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop, ACPITable.ssdtMEM2],
    ),
    'skylake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 16},
        ACPITable.ssdtXOSI,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop, ACPITable.ssdtMEM2],
    ),
    'kaby_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 16},
        ACPITable.ssdtXOSI,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop, ACPITable.ssdtMEM2],
    ),
    'coffee_lake_8th': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      recommend: [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtDMAR,
      ],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop],
    ),
    'coffee_lake_9th': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
        ACPITable.ssdtXOSI,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtALS0, ACPITable.ssdtDMAR],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop],
    ),
    'comet_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      recommend: [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtDMAR,
      ],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop],
    ),
    'ice_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
        ACPITable.ssdtRHUB,
      ],
      recommend: [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtDMAR,
      ],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop],
    ),
    'tiger_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      recommend: [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop],
    ),
    'alder_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      recommend: [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop],
    ),
    'raptor_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      recommend: [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop],
    ),
    'raptor_lake_refresh': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtXOSI,
      ],
      recommend: [
        ACPITable.ssdtHPET,
        ACPITable.ssdtPMC,
        ACPITable.ssdtALS0,
        ACPITable.ssdtRHUB,
        ACPITable.ssdtDMAR,
      ],
      optional: [ACPITable.ssdtGPI0, ..._optionalLaptop],
    ),
  };

  static const _intelNuc = {
    'penryn': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop],
      recommend: [ACPITable.ssdtHPET],
      optional: _optionalDesktop,
    ),
    'clarksfield_arrandale': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop],
      recommend: [ACPITable.ssdtHPET],
      optional: _optionalDesktop,
    ),
    'sandy_bridge': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop],
      recommend: [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1C'},
      ],
      optional: _optionalDesktop,
    ),
    'ivy_bridge': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop],
      recommend: [
        ACPITable.ssdtHPET,
        {...ACPITable.ssdtIMEI, 'extra': '3A1E'},
        ACPITable.ssdtDMAR,
      ],
      optional: _optionalDesktop,
    ),
    'haswell': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: [..._optionalDesktop, ACPITable.ssdtMEM2],
    ),
    'broadwell': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: [..._optionalDesktop, ACPITable.ssdtMEM2],
    ),
    'skylake': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: [..._optionalDesktop, ACPITable.ssdtMEM2],
    ),
    'kaby_lake': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: [..._optionalDesktop, ACPITable.ssdtMEM2],
    ),
    'coffee_lake_8th': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'coffee_lake_9th': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtPNLF,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtPMC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'comet_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'ice_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
        ACPITable.ssdtRHUB,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'tiger_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtAWAC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtRHUB, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'alder_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtRHUB, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'raptor_lake': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtRHUB, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'raptor_lake_refresh': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUGALT,
        ACPITable.ssdtAWAC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtRHUB, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
  };

  static const _intelHedt = {
    'nehalem_westmere': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop],
      recommend: [ACPITable.ssdtHPET,ACPITable.ssdtAPIC],
      optional: _optionalDesktop,
    ),
    'sandy_bridge_e': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop, ACPITable.ssdtUNC],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR, ACPITable.ssdtAPIC],
      optional: _optionalDesktop,
    ),
    'ivy_bridge_e': _SsdtRule(
      basic: [ACPITable.ssdtECDesktop, ACPITable.ssdtUNC],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR, ACPITable.ssdtAPIC],
      optional: _optionalDesktop,
    ),
    'haswell_e': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtRTC0RANGE,
        ACPITable.ssdtUNC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR, ACPITable.ssdtAPIC],
      optional: _optionalDesktop,
    ),
    'broadwell_e': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtRTC0RANGE,
        ACPITable.ssdtUNC,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR, ACPITable.ssdtAPIC],
      optional: _optionalDesktop,
    ),
    'skylake_x_w': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtRTC0RANGE,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR, ACPITable.ssdtAPIC],
      optional: _optionalDesktop,
    ),
    'cascade_lake_x_w': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXDesktop,
        ACPITable.ssdtPLUG,
        ACPITable.ssdtRTC0RANGE,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR, ACPITable.ssdtAPIC],
      optional: _optionalDesktop,
    ),
  };

  static const _amdDesktop = {
    'bulldozer_jaguar': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXDesktop],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'ryzen_threadripper': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
  };

  static const _amdLaptop = {
    'bulldozer_jaguar': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXLaptop],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalLaptop,
    ),
    'ryzen': _SsdtRule(
      basic: [
        ACPITable.ssdtECUSBXLaptop,
        ACPITable.ssdtPLUG,
        {...ACPITable.ssdtPNLF, 'extra': 19},
        ACPITable.ssdtXOSI,
      ],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalLaptop,
    ),
  };

  static const _amdNuc = {
    'bulldozer_jaguar': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXDesktop],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
    'ryzen': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
  };

  static const _amdHedt = {
    'ryzen_threadripper': _SsdtRule(
      basic: [ACPITable.ssdtECUSBXDesktop, ACPITable.ssdtPLUG],
      recommend: [ACPITable.ssdtHPET, ACPITable.ssdtDMAR],
      optional: _optionalDesktop,
    ),
  };

  static const _rules = {
    CpuType.intel: {
      PlatformType.desktop: _intelDesktop,
      PlatformType.laptop: _intelLaptop,
      PlatformType.nuc: _intelNuc,
      PlatformType.hedt: _intelHedt,
    },
    CpuType.amd: {
      PlatformType.desktop: _amdDesktop,
      PlatformType.laptop: _amdLaptop,
      PlatformType.nuc: _amdNuc,
      PlatformType.hedt: _amdHedt,
    },
  };

  static PlatformModel? platformModel(
    CpuType cpuType,
    PlatformType platformType,
  ) {
    return Configs().configsRepository.getPlatformModel(cpuType, platformType);
  }

  static List<String> platformCodes(
    CpuType cpuType,
    PlatformType platformType,
  ) {
    return platformModel(cpuType, platformType)?.platformCodes ??
        const <String>[];
  }

  static String platformLabel(
    CpuType cpuType,
    PlatformType platformType,
    String platformCode,
  ) {
    final model = platformModel(cpuType, platformType);
    return model?.platforms[platformCode]?.label ?? platformCode;
  }

  static List<SsdtItem> items(
    CpuType cpuType,
    PlatformType platformType,
    String platformCode,
  ) {
    final rule = _rules[cpuType]?[platformType]?[platformCode];
    if (rule == null) return const <SsdtItem>[];
    final recommend = platformType == PlatformType.laptop
        ? [...rule.recommend, ..._recommendedLaptopSupplement]
        : rule.recommend;
    return _uniqueItems([
      ..._parse(rule.basic, SsdtItemGroup.basic),
      ..._parse(recommend, SsdtItemGroup.recommend),
      ..._parse(rule.optional, SsdtItemGroup.optional),
    ]);
  }

  static Set<String> defaultSelectedKeys(
    CpuType cpuType,
    PlatformType platformType,
    String platformCode,
  ) {
    return items(cpuType, platformType, platformCode)
        .where(
          (item) =>
              item.isBasic ||
              (item.isRecommend && platformType != PlatformType.desktop),
        )
        .map((item) => item.key)
        .toSet();
  }

  static List<SsdtItem> _parse(
    List<Map<String, dynamic>> maps,
    SsdtItemGroup group,
  ) {
    return maps
        .map(
          (map) => SsdtItem(
            name: map.name,
            remark: map['remark'] ?? '',
            note: map['note'],
            extra: map['extra'],
            group: group,
          ),
        )
        .toList();
  }

  static List<SsdtItem> _uniqueItems(List<SsdtItem> items) {
    final keys = <String>{};
    return items.where((item) => keys.add(item.key)).toList();
  }
}

class _SsdtRule {
  const _SsdtRule({
    required this.basic,
    required this.recommend,
    required this.optional,
  });

  final List<Map<String, dynamic>> basic;
  final List<Map<String, dynamic>> recommend;
  final List<Map<String, dynamic>> optional;
}
