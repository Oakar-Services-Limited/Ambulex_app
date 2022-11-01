import 'package:flutter/material.dart';

class SubmitButton extends StatefulWidget {
  final String label;


  const SubmitButton({super.key, required this.label});

  @override
  State<StatefulWidget> createState() => _SubmitButton();
}

class _SubmitButton extends State<SubmitButton> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 12, 44, 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          minimumSize: const Size.fromHeight(50), // NEW
        ),
        onPressed: (() {
          
        }),
        child: Text(
          widget.label,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
