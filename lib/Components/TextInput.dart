import 'package:flutter/material.dart';

class TextInput extends StatefulWidget {
  final String title;

  const TextInput({super.key, required this.title});

  @override
  State<StatefulWidget> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
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
            SizedBox(
              height: 10,
            ),
            const TextField(
              decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                border: OutlineInputBorder(),
                filled: false,
              ),
            )
          ],
        ));
  }
}
