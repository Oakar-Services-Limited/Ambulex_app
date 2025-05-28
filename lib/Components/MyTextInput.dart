// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyTextInput extends StatefulWidget {
  final String title;
  final String value;
  final TextInputType type;
  final Function(dynamic) onSubmit;
  final IconData? prefixIcon;
  final bool isPassword;

  const MyTextInput(
      {super.key,
      required this.title,
      required this.value,
      required this.type,
      required this.onSubmit,
      this.prefixIcon,
      this.isPassword = false});

  @override
  State<StatefulWidget> createState() => _MyTextInputState();
}

class _MyTextInputState extends State<MyTextInput> {
  TextEditingController _controller = new TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MyTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _controller.text =
            widget.value != "null" ? widget.value.toString() : '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: Theme.of(context).copyWith(
            hintColor: Colors.blue,
            inputDecorationTheme: const InputDecorationTheme(
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red)))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: TextField(
              onChanged: (value) {
                widget.onSubmit(value);
              },
              keyboardType: widget.type,
              inputFormatters: widget.type ==
                      const TextInputType.numberWithOptions(decimal: false)
                  ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
                  : null,
              controller: _controller,
              style: const TextStyle(color: Colors.blue),
              cursorColor: Colors.blue,
              obscureText: widget.isPassword ? _obscureText : false,
              enableSuggestions: true,
              autocorrect: false,
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8),
                  hintStyle: const TextStyle(color: Colors.blue),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue, width: 0.0),
                  ),
                  focusColor: Colors.red,
                  border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2.0)),
                  filled: false,
                  label: Text(
                    widget.title.toString(),
                    style: const TextStyle(color: Colors.blue),
                  ),
                  suffixIcon: widget.type == TextInputType.visiblePassword
                      ? IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        )
                      : null,
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  prefixIcon: widget.prefixIcon != null
                      ? Icon(widget.prefixIcon, color: Colors.blue)
                      : null)),
        ));
  }
}
