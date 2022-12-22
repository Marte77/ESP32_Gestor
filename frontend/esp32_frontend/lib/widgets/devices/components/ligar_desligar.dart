import 'package:flutter/material.dart';

class LigarDesligar extends StatefulWidget {
  const LigarDesligar({Key? key, required this.onChanged, required this.state})
      : super(key: key);
  final void Function(bool newState) onChanged;
  final bool state;
  @override
  State<LigarDesligar> createState() => _LigarDesligarState();
}

class _LigarDesligarState extends State<LigarDesligar> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Ligar/desligar"),
      leading: Switch(
        value: widget.state,
        onChanged: (value) {
          widget.onChanged(value);
        },
      ),
    );
  }
}
