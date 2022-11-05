import 'package:flutter/material.dart';

class MyTextInput extends StatefulWidget {
  String title;
  String value;
  var type;
  Function(String) onSubmit;
  MyTextInput(
      {super.key,
      required this.title,
      required this.value,
      required this.type,
      required this.onSubmit});

  @override
  State<StatefulWidget> createState() => _MyTextInputState();
}

class _MyTextInputState extends State<MyTextInput> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: TextFormField(
          initialValue: widget.value,
            onChanged: widget.onSubmit,
            keyboardType: widget.type,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              border: const OutlineInputBorder(),
              filled: false,
              label: Text(widget.title.toString()),
              floatingLabelBehavior: FloatingLabelBehavior.always
            )));
  }
}
