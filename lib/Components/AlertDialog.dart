import 'package:flutter/material.dart';

class MyAlertDialog extends StatefulWidget {
  final String type;
  const MyAlertDialog({super.key, required this.type});

  @override
  State<StatefulWidget> createState() => _MyAlertDialogState();
}

class _MyAlertDialogState extends State<MyAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.type),
      content: const Text(
          'Your report was submitted successfully. Please be patient our emergency response team has been notified.'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'OK'),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
