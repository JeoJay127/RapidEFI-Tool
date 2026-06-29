import 'package:flutter/material.dart';
import 'package:rapidefi/pages/hardware/models/hardware_models.dart';
import 'package:rapidefi/pages/hardware/widgets/underline_copytext.dart';

class HardwareLine extends StatelessWidget {
  final List<String> items;
  final double spacing;
  final Color? color;

  const HardwareLine(this.items, {super.key, this.spacing = 15, this.color});

  @override
  Widget build(BuildContext context) {
    final visible = items.where((i) => i.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final sep = spacing <= 10 ? '  ' : '    ';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(visible.join(sep),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, height: 1.25, color: color)),
    );
  }
}

class HardwareCopy extends StatelessWidget {
  final String label;
  final String value;
  final int max;
  final Color? color;

  const HardwareCopy(this.label, this.value,
      {super.key, this.max = 120, this.color});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final display =
        value.length > max ? '${value.substring(0, max)}...' : value;
    return Wrap(
        spacing: 6,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SelectableText(label,
              style: TextStyle(fontSize: 14, height: 1.25, color: color)),
          UnderlineCopyText(
            text: display,
            copyText: value,
            style: TextStyle(fontSize: 14, height: 1.25, color: color),
            underlineGap: 1, // 文字和横线间距
            underlineHeight: 1, // 横线粗细
            underlineExtraWidth: 8, // 横线额外宽度
          ),
        ]);
  }
}

class HardwareHeaderCard extends StatelessWidget {
  final List<String> items;

  const HardwareHeaderCard(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    final values = items.where((i) => i.trim().isNotEmpty).toList();
    if (values.isEmpty) return const SizedBox.shrink();
    final colors = hardwareThemeColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: colors.cardColor,
          border: Border.all(color: colors.borderColor),
          borderRadius: BorderRadius.circular(5)),
      child: Column(
          children: values
              .map((i) => Text(i,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: colors.textColor)))
              .toList()),
    );
  }
}

class HardwareDeviceBlock extends StatelessWidget {
  final List<Widget> children;
  const HardwareDeviceBlock(this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    final visible = children.where((c) => c is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: visible),
    );
  }
}

class HardwarePathLine extends StatelessWidget {
  final Map<String, dynamic> device;
  final Color? color;

  const HardwarePathLine(this.device, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final acpiPath = device['ACPI Path']?.toString() ?? '';
    final pciPath = device['PCI Path']?.toString() ?? '';
    final children = <Widget>[
      if (acpiPath.trim().isNotEmpty)
        HardwareCopy('ACPI Path:', acpiPath, max: 80, color: color),
      if (pciPath.trim().isNotEmpty)
        HardwareCopy('PCI Path:', pciPath, max: 90, color: color),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 14, runSpacing: 2, children: children);
  }
}

class HardwareSection extends StatelessWidget {
  final String title;
  final List<Widget> content;
  final CompatibilityNote? note;
  final Widget? trailing;

  const HardwareSection(this.title, this.content,
      {super.key, this.note, this.trailing});

  @override
  Widget build(BuildContext context) {
    final visible = content.where((c) => c is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final colors = hardwareThemeColors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
          color: colors.cardColor,
          border: Border.all(color: colors.borderColor),
          borderRadius: BorderRadius.circular(5)),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: visible),
            ),
          ),
          Container(
            width: 190,
            padding: const EdgeInsets.fromLTRB(18, 4, 0, 4),
            decoration: BoxDecoration(
                border: Border(left: BorderSide(color: colors.borderColor))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note != null)
                  Text(note!.text,
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: note!.color,
                          fontWeight: FontWeight.w600)),
                if (trailing != null) ...[
                  const SizedBox(height: 6),
                  trailing!,
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
