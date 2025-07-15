// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTextInput extends StatefulWidget {
  final String title;
  final String value;
  final int? lines;
  final TextInputType type;
  final Function(dynamic) onSubmit;
  final IconData? prefixIcon;
  final bool isPassword;

  const MyTextInput({
    super.key,
    required this.title,
    required this.value,
    required this.type,
    required this.onSubmit,
    this.lines,
    this.prefixIcon,
    this.isPassword = false,
  });

  @override
  State<StatefulWidget> createState() => _MyTextInputState();
}

class _MyTextInputState extends State<MyTextInput> {
  TextEditingController _controller = TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant MyTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          maxLines: widget.lines ?? 1,
          style: GoogleFonts.poppins(color: Colors.blue, fontSize: 15),
          cursorColor: Colors.blue,
          obscureText:
              widget.isPassword || widget.type == TextInputType.visiblePassword
                  ? _obscureText
                  : false,
          enableSuggestions: true,
          autocorrect: false,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintStyle: GoogleFonts.poppins(color: Colors.blue.shade200),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5),
            ),
            fillColor: Colors.white,
            filled: true,
            label: Text(
              widget.title.toString(),
              style: GoogleFonts.poppins(
                  color: Colors.blue, fontWeight: FontWeight.w500),
            ),
            suffixIcon: (widget.isPassword ||
                    widget.type == TextInputType.visiblePassword)
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.blue,
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
                : null,
          ),
        ),
      ),
    );
  }
}
