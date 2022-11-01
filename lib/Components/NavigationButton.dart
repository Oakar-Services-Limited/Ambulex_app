import 'package:flutter/material.dart';

class NavigationButton extends StatefulWidget {
  final String label;
  final StatefulWidget object;
  const NavigationButton(
      {super.key, required this.label, required this.object});

  @override
  State<StatefulWidget> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<NavigationButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
          onPressed: (() {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => widget.object));
          }),
          child: Text(
            widget.label,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.orange),
          )),
    );
  }
}
