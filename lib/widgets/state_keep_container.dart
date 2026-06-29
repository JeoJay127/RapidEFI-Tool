import 'package:flutter/widgets.dart';

class StateKeepContainer extends StatefulWidget {
  final Widget child;
  const StateKeepContainer({required this.child, super.key});
  @override
  State createState() => _StateKeepContainerState();
}

class _StateKeepContainerState extends State<StateKeepContainer>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
