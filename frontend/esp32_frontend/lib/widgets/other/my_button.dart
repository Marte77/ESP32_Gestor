import 'package:flutter/material.dart';

class UnselectableElevatedButton extends StatelessWidget {
  const UnselectableElevatedButton({Key? key, required this.child})
      : super(key: key);
  final ElevatedButton child;
  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
        child: MouseRegion(cursor: SystemMouseCursors.click, child: child));
  }
}

class UnselectableTextButton extends StatelessWidget {
  const UnselectableTextButton({Key? key, required this.child})
      : super(key: key);
  final TextButton child;
  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
        child: MouseRegion(cursor: SystemMouseCursors.click, child: child));
  }
}

class UnselectableOutlinedButton extends StatelessWidget {
  const UnselectableOutlinedButton({Key? key, required this.child})
      : super(key: key);
  final OutlinedButton child;
  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
        child: MouseRegion(cursor: SystemMouseCursors.click, child: child));
  }
}

class UnselectableToggleButton extends StatelessWidget {
  const UnselectableToggleButton({Key? key, required this.child})
      : super(key: key);
  final ToggleButtons child;
  @override
  Widget build(BuildContext context) {
    return SelectionContainer.disabled(
        child: MouseRegion(cursor: SystemMouseCursors.click, child: child));
  }
}
