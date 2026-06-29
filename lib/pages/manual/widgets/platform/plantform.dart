import 'package:rapidefi/pages/shared/widgets/title_card.dart';
import 'package:rapidefi/utils/config/models/enums/platform_type_enum.dart';
import 'package:rapidefi/widgets/button_segment_widget.dart';
import 'package:flutter/material.dart';

class PlantformWidget extends StatefulWidget {
  final ValueChanged onChanged;
  final PlatformType platformType;

  const PlantformWidget({
    super.key,
    required this.onChanged,
    this.platformType = PlatformType.desktop,
  });

  @override
  State<PlantformWidget> createState() => _PlantformWidgetState();
}

class _PlantformWidgetState extends State<PlantformWidget> {
  late PlatformType platformType = widget.platformType;

  @override
  void didUpdateWidget(covariant PlantformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.platformType != widget.platformType) {
      platformType = widget.platformType;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TitleCard(
      title: "平台选择:",
      content: ButtonSegmentWidget(
        initialSelection: {platformType.value},
        labels: PlatformType.values.map((type) => type.value).toList(),
        onSelectionChanged: (value) {
          final selectedValue = value.first;

          final selectedType = PlatformType.values.firstWhere(
            (type) => type.value == selectedValue,
            orElse: () => PlatformType.desktop,
          );

          if (platformType == selectedType) {
            return;
          }

          setState(() {
            platformType = selectedType;
          });

          widget.onChanged.call(platformType);
        },
      ),
    );
  }
}
