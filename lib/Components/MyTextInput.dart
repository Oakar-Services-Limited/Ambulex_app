import 'package:flutter/material.dart';

class MyTextInput extends StatefulWidget {
  String title;
  var type;
  Function(String) onSubmit;
  MyTextInput(
      {super.key,
      required this.title,
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
        child: Column(
          children: <Widget>[
            SizedBox(
                width: double.infinity,
                child: Text(widget.title,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ))),
            const SizedBox(
              height: 10,
            ),
            TextField(
              onChanged: widget.onSubmit,
              keyboardType: widget.type,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                border: OutlineInputBorder(),
                filled: false,
              ),
            )
          ],
        ));
  }
}
