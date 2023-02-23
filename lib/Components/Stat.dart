import 'package:flutter/material.dart';

class Stats extends StatefulWidget {
  final String label;
   final String image;
    final String value;

  const Stats({
    super.key,
    required this.label, required this.image, required this.value,
  });

  @override
  State<StatefulWidget> createState() => _StatState();
}

class _StatState extends State<Stats> {
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5,
        color: Colors.white,
        clipBehavior: Clip.hardEdge,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Column(children: <Widget>[
              Text(
                widget.label,
                textAlign: TextAlign.left,
                textWidthBasis: TextWidthBasis.parent,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
               const SizedBox(
                height: 10,
              ),
              Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Image.asset(widget.image)
            ]),
          ),
        ));
  }
}
