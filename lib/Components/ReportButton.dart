// ignore_for_file: must_be_immutable, prefer_typing_uninitialized_variables, file_names

import 'package:flutter/material.dart';

class ReportButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color1;
  var onButtonPressed;

  ReportButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.color1,
      required this.onButtonPressed});

  @override
  State<StatefulWidget> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
        onPressed: widget.onButtonPressed,
        clipBehavior: Clip.none,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Card(
            elevation: 5,
            color: Colors.blue,
            clipBehavior: Clip.hardEdge,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.color1,
                  widget.color1,
                ],
              )),
              child: Center(
                child: Column(children: <Widget>[
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 32,
                    semanticLabel: 'Current Location',
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Ask for Help',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ]),
              ),
            )));
  }
}
