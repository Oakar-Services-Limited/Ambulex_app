import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../Components/Utils.dart';
import 'package:ambulex_app/Components/NavigationDrawer2.dart';

class ReadNews extends StatefulWidget {
  final String id;
  const ReadNews({super.key, required this.id});

  @override
  State<StatefulWidget> createState() => _ReadNewsState();
}

class _ReadNewsState extends State<ReadNews> {
  String newsID = "";
  String title = "";
  String image = "";
  String type = "";
  String description = "";
  String keywords = "";
  String link = "";
  String time = "";

  String? value;
  var isLoading = null;
  String error = '';

  @override
  void initState() {
    getReport(widget.id);
    super.initState();
  }

  getReport(String id) async {
    final response = await get(
      Uri.parse("${getUrl()}news/${id}"),
    );

    var data = json.decode(response.body);

    setState(() {
      newsID = (data["ID"]);
      title = data["Title"];
      image = data["Image"];
      type = data["Type"];
      description = data["Description"];
      keywords = data["Keywords"];
      link = data["Link"];
    });

    print("the data is $image and $title");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: MaterialApp(
        title: "News Page",
        home: Scaffold(
          appBar: AppBar(
              title: Text(title),
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )),
          drawer: const Drawer(child: NavigationDrawer2()),
          body: Padding(
              padding: const EdgeInsets.fromLTRB(24, 5, 24, 0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(
                      height: 24,
                    ),
                    image != ""
                        ? Image.network(
                            'http://185.215.180.181:9934/${image}',
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 24,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      description,
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.normal),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              )),
        ),
      ),
    );
  }
}
