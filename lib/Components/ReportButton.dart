import 'package:flutter/material.dart';

class ReportButton extends StatefulWidget {
  final String label;
   final IconData icon;
  const ReportButton({super.key,required this.label, required this.icon});

  @override
  State<StatefulWidget> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Colors.blue,
          Colors.blueGrey,
        ],
      )),
      child: Center(
        child: Column(children: <Widget>[
          Text(
           widget.label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Icon(
            widget.icon,
            color: Colors.white,
            size: 32,
            semanticLabel: 'Current Location',
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'Ask for Help',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ]),
      ),
    );
  }
}
