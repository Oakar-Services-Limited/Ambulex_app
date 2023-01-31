import 'package:flutter/material.dart';

class EMRSpinnerDialog extends StatefulWidget {
  const EMRSpinnerDialog({super.key});

  @override
  State<StatefulWidget> createState() {
    return EMRSpinnerDialogState();
  }
}

class EMRSpinnerDialogState extends State<EMRSpinnerDialog> {
  final List categorylist = [
    "Abdominal Conditions",
    "Cardiac Conditions",
    "Pulmonary Conditions",
    "Head Injuries",
    "Burns and Scalds",
    "Fractures",
    "Epilepsy",
    "Stroke",
    "Fainting",
    "Hypertension and Hypotension",
    "Hyperglycemia and Hypoglycemia",
    "Poisoning",
    "Bites"
  ];

  late List<DropdownMenuItem<String>> _dropDownMenuItems;
  late String _currentType;

  @override
  void initState() {
    _dropDownMenuItems = getDropDownMenuItems();
    _currentType = _dropDownMenuItems[0].value!;
    super.initState();
  }

  // here we are creating the list needed for the DropDownButton
  List<DropdownMenuItem<String>> getDropDownMenuItems() {
    List<DropdownMenuItem<String>> items = [];
    for (String city in categorylist) {
      // here we are creating the drop down menu items, you can customize the item right here
      // but I'll just use a simple text for this
      items.add(DropdownMenuItem(value: city, child: new Text(city)));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Dialog(
      child: Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          height: 150,
          child: Column(
            children: <Widget>[
              const Text(
                "Select Medical Emergency",
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 22),
              ),
              DropdownButton(
                value: _currentType,
                items: _dropDownMenuItems,
                onChanged: changedDropDownItem,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue
                    ),
                    onPressed: () => Navigator.pop(context, _currentType),
                    child: const Text(
                      "Submit",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            ],
          )),
    );
  }

  void changedDropDownItem(String? selectedCity) {
    print("Selected city $selectedCity, we are going to refresh the UI");
    setState(() {
       _currentType = selectedCity!;
    });
  }

  void submit() {}
}