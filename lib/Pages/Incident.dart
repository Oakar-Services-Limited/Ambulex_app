// ignore_for_file: file_names, empty_catches

import 'package:ambulex_app/Components/NavigationDrawer2.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart';
import '../Components/Utils.dart';
import '../Components/MyHomePage.dart';
import 'package:geocoding/geocoding.dart';

class Incident extends StatefulWidget {
  final String id;
  const Incident({super.key, required this.id});

  @override
  State<StatefulWidget> createState() => _IncidentState();
}

class _IncidentState extends State<Incident> {
  String name = "";
  String address = "";
  String building = "";
  String customerID = "";
  double mylat = 0.0;
  double mylon = 0.0;
  double dlat = 0.0;
  double dlon = 0.0;
  String location = '';

  @override
  void initState() {
    getReport(widget.id);
    super.initState();
  }

  getReport(String id) async {
    try {
      final response = await get(
        Uri.parse("${getUrl()}reports/merged/$id"),
      );
      var data = json.decode(response.body);
      setState(() {
        name = data["Name"];
        address = data["Address"];
        building = data["BuildingName"];
        customerID = data["ID"];
        dlat = double.parse(data["DLatitude"]);
        dlon = double.parse(data["DLongitude"]);
        mylat = double.parse(data["MyLatitude"]);
        mylon = double.parse(data["MyLongitude"]);
      });
      List<Placemark> dest = await placemarkFromCoordinates(
          double.parse(data["DLatitude"]), double.parse(data["DLongitude"]));
      List<Placemark> myloc = await placemarkFromCoordinates(
          double.parse(data["MyLatitude"]), double.parse(data["MyLongitude"]));

      setState(() {
        location =
            "${myloc[0].locality}, ${myloc[0].street}, ${myloc[0].name} \n - \n ${dest[0].locality}, ${dest[0].street}, ${dest[0].subLocality}";
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Incident",
        home: Scaffold(
          appBar: AppBar(title: Text(name)),
          drawer: const Drawer(child: NavigationDrawer2()),
          body: Stack(children: <Widget>[
            mylat != 0.0
                ? MyHomePage(
                    mylat: mylat,
                    mylon: mylon,
                    dlat: dlat,
                    dlon: dlon,
                    id: widget.id,
                    customerID: customerID,
                  )
                : const SizedBox(),
            Align(
              alignment: AlignmentDirectional.topCenter,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Text(
                      location,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  )),
            ),
          ]),
        ));
  }
}

class Report {
  final String type;
  final String name;
  final String address;
  final String landmark;
  final String city;
  final String date;
  final String street;
  Report(this.type, this.name, this.address, this.landmark, this.city,
      this.date, this.street);
}
