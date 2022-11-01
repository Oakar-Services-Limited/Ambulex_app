import 'package:flutter/material.dart';

class TextOakar extends StatefulWidget {
  final String label;
  const TextOakar({super.key, required this.label});

  @override
  State<StatefulWidget> createState() => _TextOakarState();
}

class _TextOakarState extends State<TextOakar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Text(widget.label,
      textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
    );
  }
}
