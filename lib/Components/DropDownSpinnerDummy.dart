import 'package:flutter/material.dart';

class DropDownSpinner extends StatefulWidget {
  const DropDownSpinner({super.key, required this.type});
  final String type;

  get spinnerList => null;

  @override
  State<StatefulWidget> createState() => _DropDownSpinnerState();
}

class _DropDownSpinnerState extends State<DropDownSpinner> {
   late String currentItem;
   List listItem = ["one", "two", "three"];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(15)
            ),
            child: DropdownButton(
              hint: Text("Select Items"),
              dropdownColor: Colors.grey,
              icon: Icon(Icons.arrow_drop_down),
              iconSize: 36,
              isExpanded: true,
              underline: SizedBox(),
              style: TextStyle(
                color: Colors.black,
                fontSize: 22
              ),
              value: currentItem,
              onChanged: (newValue) {
                setState(() {
                  currentItem = newValue.toString();
                });
              },
              items: listItem.map((valueItem){
                return DropdownMenuItem(
                    value: valueItem,
                  child: Text(valueItem),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}