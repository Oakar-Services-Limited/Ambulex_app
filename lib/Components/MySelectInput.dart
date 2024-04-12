import 'package:flutter/material.dart';

class MySelectInput extends StatefulWidget {
  final String label;
  final String value;
  final List<String> list;
  final Function(String) onSubmit;
  const MySelectInput(
      {super.key,
      required this.list,
      required this.label,
      required this.onSubmit,
      required this.value});

  @override
  State<StatefulWidget> createState() => _MySelectInputState();
}

class _MySelectInputState extends State<MySelectInput> {
  late String _selectedOption = '';

  @override
  void initState() {
    super.initState();
    if (widget.list.contains(widget.value)) {
      setState(() {
        _selectedOption = widget.value;
      });
    } else {
      setState(() {
        _selectedOption = widget.list.first;
      });
    }
  }

  @override
  void didUpdateWidget(covariant MySelectInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.list != widget.list) {
      setState(() {
        _selectedOption = widget.list.first;
      });
    }
    if (oldWidget.value != widget.value) {
      if (widget.list.contains(widget.value)) {
        setState(() {
          _selectedOption = widget.value;
        });
      } else {
        setState(() {
          _selectedOption = widget.list.first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
          canvasColor: Colors.blue,
          hintColor: Colors.black,
          inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.yellow)))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Stack(
          children: [
            TextField(
              onChanged: (value) {},
              onTap: () {},
              enabled: false,
              enableSuggestions: false,
              autocorrect: false,
              style: const TextStyle(color: Colors.transparent),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8),
                  hintStyle: const TextStyle(color: Colors.black),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 0.0),
                  ),
                  disabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 0.0),
                  ),
                  focusColor: Colors.yellow,
                  border: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.yellow, width: 1.0)),
                  filled: false,
                  label: Text(
                    widget.label,
                    style: const TextStyle(color: Colors.black),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 0, 16, 0),
              child: DropdownButton<String>(
                icon: const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black,
                  ),
                ),
                isExpanded: true,
                underline: Container(),
                value: _selectedOption,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedOption = newValue!;
                  });
                  widget.onSubmit(newValue!);
                },
                items:
                    widget.list.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.black12),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
