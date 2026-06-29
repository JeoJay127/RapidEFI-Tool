import 'package:fluent_ui/fluent_ui.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';

class OSVersionWidget extends StatefulWidget {
  final List<String> verions;
  final String macOSVersion;
  final Function(String)? onChanged;

  const OSVersionWidget({
    super.key,
    required this.verions,
    this.onChanged,
    this.macOSVersion = '',
  });

  @override
  State<OSVersionWidget> createState() => _OSVersionWidgetState();
}

class _OSVersionWidgetState extends State<OSVersionWidget> {
  late String macOSVersion = _resolveMacOSVersion();

  String _resolveMacOSVersion() {
    if (widget.verions.isEmpty) {
      return '';
    }

    if (widget.macOSVersion.isNotEmpty &&
        widget.verions.contains(widget.macOSVersion)) {
      return widget.macOSVersion;
    }

    return widget.verions.first;
  }

  @override
  void didUpdateWidget(covariant OSVersionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final versionsChanged = oldWidget.verions.length != widget.verions.length ||
        oldWidget.verions.join('|') != widget.verions.join('|');

    final macOSVersionChanged = oldWidget.macOSVersion != widget.macOSVersion;

    if (versionsChanged || macOSVersionChanged) {
      macOSVersion = _resolveMacOSVersion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TitleCard(
      title: "安装macOS版本:",
      subTitle: "",
      content: ComboBox<String>(
        isExpanded: false,
        value: macOSVersion.isEmpty ? null : macOSVersion,
        items: widget.verions.map((e) {
          return ComboBoxItem(
            value: e,
            child: Text(e),
          );
        }).toList(),
        onChanged: (info) {
          if (info == null) {
            return;
          }

          if (macOSVersion == info) {
            return;
          }

          setState(() {
            macOSVersion = info;
          });

          widget.onChanged?.call(info);
        },
      ),
      snippet:
          '根据当前选择的macOS版本,制作的EFI,会向下兼容.例如,如果选择了Tahoe 26,那么该引导同时支持Sequoia 15及以下版本。\n\n温馨提示:工具制作的EFI向下兼容,经测试支持macOS EI Capitan 10.11.x ~ macOS Tahoe 26.x系统。更低版本自行测试,太老了,也没必要了。',
    );
  }
}
