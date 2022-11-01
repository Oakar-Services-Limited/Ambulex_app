import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';

class Map extends StatefulWidget {
  const Map({Key? key}) : super(key: key);

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(children: const <Widget>[
         SizedBox(
              width: double.infinity,
              child:  Text("Physical Location",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ))),
          SizedBox(
            height: 10,
          ),
          SizedBox(
            height: 250,
            child:WebView(
            initialUrl: 'http://demo.osl.co.ke:444/api/homepage',
          ))
        ]));
  }
}
