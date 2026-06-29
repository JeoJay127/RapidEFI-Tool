import 'package:flutter/material.dart';
import 'package:rapidefi/pages/manual/widgets/graphics/amd_gpu.dart';
import 'package:rapidefi/pages/manual/widgets/graphics/fake_gpu.dart';
import 'package:rapidefi/pages/manual/widgets/graphics/nvidia_gpu.dart';
import 'package:rapidefi/pages/shared/widgets/oclp_link_button.dart';
import 'package:rapidefi/pages/shared/widgets/tabbed_title_card.dart';
import 'package:rapidefi/widgets/state_keep_container.dart';

class DgpuWidget extends StatefulWidget {
  const DgpuWidget({
    super.key,
    this.onNootRXChanged,
    this.onNvidiaChanged,
    this.onFakeGPUChanged,
    this.nootRXSelected = false,
    this.nvidiaSelected = false,
  });

  final ValueChanged<bool>? onNootRXChanged;
  final ValueChanged<bool>? onNvidiaChanged;
  final Function(String, String)? onFakeGPUChanged;
  final bool nootRXSelected;
  final bool nvidiaSelected;

  @override
  State<DgpuWidget> createState() => _DgpuWidgetState();
}

class _DgpuWidgetState extends State<DgpuWidget> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final List<String> tabName;

  @override
  void initState() {
    super.initState();
    tabName = ['Nvidia独显', 'AMD独显', 'AMD独显仿冒'];
    _tabController = TabController(vsync: this, length: tabName.length);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> get pages => [
        StateKeepContainer(
          child: NvidiaGPU(
            selected: widget.nvidiaSelected,
            onChanged: widget.onNvidiaChanged,
          ),
        ),
        StateKeepContainer(
          child: AMDGPU(
            nootRXSelected: widget.nootRXSelected,
            onNootRXChanged: widget.onNootRXChanged,
          ),
        ),
        StateKeepContainer(
          child: FakeGPU(
            onChanged: (dgpuPath, dgpuFakeID) {
              widget.onFakeGPUChanged?.call(dgpuPath, dgpuFakeID);
            },
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return TabbedTitleCard(
      title: '独显配置:',
      subTitle: '(可选项-对应则勾选)',
      initiallyExpanded: false,
      content: const OclpLinkButton(),
      controller: _tabController,
      tabs: tabName.map((name) => Tab(text: name)).toList(),
      children: pages,
    );
  }
}
