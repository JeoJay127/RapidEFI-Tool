import 'package:flutter/widgets.dart';
import 'package:rapidefi/pages/manual/sections/other_section.dart';
import 'package:rapidefi/pages/manual/sections/connectivity_section.dart';
import 'package:rapidefi/pages/manual/sections/graphics_section.dart';
import 'package:rapidefi/pages/manual/sections/output_section.dart';
import 'package:rapidefi/pages/manual/sections/platform_base_section.dart';
import 'package:rapidefi/widgets/state_keep_container.dart';

class ManualSections {
  const ManualSections._();

  static const List<Widget> children = [
    SizedBox(height: 10),
    StateKeepContainer(child: PlatformBaseSectionView()),
    SizedBox(height: 10),
    StateKeepContainer(child: IgpuSectionView()),
    SizedBox(height: 10),
    StateKeepContainer(child: DgpuSectionView()),
    SizedBox(height: 10),
    StateKeepContainer(child: ConnectivitySectionView()),
    SizedBox(height: 10),
    StateKeepContainer(child: OtherSectionView()),
    SizedBox(height: 10),
    StateKeepContainer(child: OutputSectionView()),
    SizedBox(height: 100),
  ];
}
