import 'package:fluent_ui/fluent_ui.dart';

class ExpanderCard extends StatefulWidget {
  const ExpanderCard(
      {super.key,
      this.header,
      this.expander,
      required this.child,
      this.backgroundColor,
      this.snippet,
      this.initiallyExpanded = false});

  final Widget? header;
  final Widget? expander;
  final String? snippet;
  final Widget child;
  final Color? backgroundColor;
  final bool initiallyExpanded;

  @override
  State<ExpanderCard> createState() => _ExpanderCardState();
}

class _ExpanderCardState extends State<ExpanderCard> {
  final GlobalKey expanderKey = GlobalKey<ExpanderState>(
    debugLabel: 'Card Expander Key',
  );

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.resources.controlStrokeColorSecondary,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Column(children: [
          Mica(
            backgroundColor: widget.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: SizedBox(
                  width: double.infinity,
                  child: widget.child,
                ),
              ),
            ),
          ),
          if (widget.expander != null ||
              (widget.snippet != null && widget.snippet!.isNotEmpty))
            Expander(
              key: expanderKey,
              initiallyExpanded: widget.initiallyExpanded,
              onStateChanged: (_) {},
              header: widget.header ?? const Text('详细信息'),
              headerShape: (open) {
                return const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.zero,
                  ),
                );
              },
              content: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(6.0),
                ),
                child: widget.expander ?? Text(widget.snippet!),
              ),
            ),
        ]),
      ),
    );
  }
}
