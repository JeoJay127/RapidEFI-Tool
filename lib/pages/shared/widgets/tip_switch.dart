import 'package:fluent_ui/fluent_ui.dart';

class TipSwitch extends StatefulWidget {
  const TipSwitch(
      {super.key, this.checked = false, this.title, this.tip, this.onChanged});
  final bool checked;
  final String? title;
  final String? tip;
  final ValueChanged? onChanged;

  @override
  State<TipSwitch> createState() => _TipSwitchState();
}

class _TipSwitchState extends State<TipSwitch> {
  late bool checked = widget.checked;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tip ?? '',
      child: ToggleSwitch(
        checked: checked,
        onChanged: (v) {
          setState(() => checked = v);
          widget.onChanged?.call(v);
        },
        content: Text(widget.title ?? ''),
      ),
    );
  }
}
