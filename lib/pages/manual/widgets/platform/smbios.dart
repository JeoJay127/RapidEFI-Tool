import 'package:fluent_ui/fluent_ui.dart';
import 'package:rapidefi/utils/config/models/platform_info/pi_generic.dart';
import 'package:rapidefi/utils/config/support/smbios_compatibility.dart';
import 'package:rapidefi/pages/shared/widgets/title_card.dart';

class SMBiosWidget extends StatefulWidget {
  final List<PlatformInfoGeneric> platformInfoGenerics;
  final PlatformInfoGeneric? selectedChoice;
  final Function(PlatformInfoGeneric)? onChanged;

  const SMBiosWidget({
    super.key,
    required this.platformInfoGenerics,
    this.onChanged,
    this.selectedChoice,
  });

  @override
  State<SMBiosWidget> createState() => _SMBiosWidgetState();
}

class _SMBiosWidgetState extends State<SMBiosWidget> {
  late PlatformInfoGeneric selectedChoice = _resolveSelectedChoice();

  PlatformInfoGeneric _resolveSelectedChoice() {
    if (widget.platformInfoGenerics.isEmpty) {
      return PlatformInfoGeneric();
    }

    final selected = widget.selectedChoice;

    if (selected != null && selected.systemProductName.isNotEmpty) {
      return widget.platformInfoGenerics.firstWhere(
        (e) => e.systemProductName == selected.systemProductName,
        orElse: () => widget.platformInfoGenerics.first,
      );
    }

    return widget.platformInfoGenerics.first;
  }

  @override
  void didUpdateWidget(covariant SMBiosWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSelectedName = oldWidget.selectedChoice?.systemProductName;
    final newSelectedName = widget.selectedChoice?.systemProductName;

    final listChanged = oldWidget.platformInfoGenerics.length !=
            widget.platformInfoGenerics.length ||
        oldWidget.platformInfoGenerics
                .map((e) => e.systemProductName)
                .join('|') !=
            widget.platformInfoGenerics
                .map((e) => e.systemProductName)
                .join('|');

    final selectedChanged = oldSelectedName != newSelectedName;

    if (listChanged || selectedChanged) {
      selectedChoice = _resolveSelectedChoice();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TitleCard(
      title: "SMBIOS机型设置:",
      subTitle: "",
      content: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ComboBox<String>(
              isExpanded: false,
              value: selectedChoice.systemProductName,
              items: widget.platformInfoGenerics.map((e) {
                return ComboBoxItem(
                  value: e.systemProductName,
                  child: Text(
                    '${e.systemProductName} - ${e.systemProductNameRelatedCPU}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (info) {
                if (info == null) return;

                final nextChoice = widget.platformInfoGenerics.firstWhere(
                  (e) => e.systemProductName == info,
                  orElse: () => selectedChoice,
                );

                setState(() {
                  selectedChoice = nextChoice;
                });

                widget.onChanged?.call(selectedChoice);
              },
            ),
          ],
        ),
      ),
      snippet: SMBIOSCompatibility.supportSummary(selectedChoice),
    );
  }
}
