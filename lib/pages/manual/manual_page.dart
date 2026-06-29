import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' hide Colors;
import 'package:provider/provider.dart';
import 'package:rapidefi/pages/manual/manual_config_controller.dart';
import 'package:rapidefi/pages/manual/sections/manual_sections.dart';
import 'package:rapidefi/utils/config/build/efi_build_options.dart';
import 'package:rapidefi/utils/config/config_model.dart';
import 'package:rapidefi/utils/config/services/config_option_provider.dart';
import 'package:rapidefi/utils/config/services/config_session.dart';
import 'package:rapidefi/widgets/custom_floating_button_location.dart';
import 'package:rapidefi/widgets/inkwell_widget.dart';
import 'package:rapidefi/widgets/custom_toast.dart';
import 'package:oktoast/oktoast.dart';

class ManualPage extends StatefulWidget {
  const ManualPage({
    super.key,
    this.configModel,
    this.configModelMode = ConfigModelMode.manual,
    this.acpiSourceDirectory,
    this.onReady,
  });

  final ConfigModel? configModel;
  final ConfigModelMode configModelMode;
  final String? acpiSourceDirectory;
  final VoidCallback? onReady;

  @override
  State<ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> {
  late final ManualConfigController _controller;
  late final ConfigOptionProvider _configOptionProvider;

  @override
  void initState() {
    super.initState();

    _controller = ManualConfigController();
    _configOptionProvider = ConfigOptionProvider();

    Future.microtask(() async {
      await _controller.initialize(
        widget.configModel,
        mode: widget.configModelMode,
      );
      if (!mounted) return;
      widget.onReady?.call();
    });
  }

  @override
  void dispose() {
    _configOptionProvider.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.activateSession();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ManualConfigController>.value(
          value: _controller,
        ),
        ChangeNotifierProvider<ConfigOptionProvider>.value(
          value: _configOptionProvider,
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: const _ManualPageBody(),
        floatingActionButton: InkWellWidget(
          width: 120,
          height: 36,
          radius: 18,
          child: const Text(
            '生成EFI',
            style: TextStyle(color: Colors.white),
          ),
          onTap: () async {
            CustomToast.show(context, "配置EFI中,请稍后");
            final success = await _controller.exportEfi(
              options: EfiBuildOptions(
                acpiSourceDirectory: widget.acpiSourceDirectory,
              ),
            );
            CustomToast.dismiss();
            showToast(success ? "配置EFI成功" : "配置EFI发生错误!\n请更换EFI输出路径");
          },
        ),
        floatingActionButtonLocation: CustomFloatingActionButtonLocation(15),
      ),
    );
  }
}

class _ManualPageBody extends StatelessWidget {
  const _ManualPageBody();

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<ManualConfigController, bool>(
      (controller) => controller.isLoading,
    );

    if (isLoading) {
      return const Center(
        child: Text('数据加载中...'),
      );
    }

    final children = ManualSections.children;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: children.length,
      itemBuilder: (_, index) => children[index],
    );
  }
}
