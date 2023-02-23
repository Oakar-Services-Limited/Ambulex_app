import 'package:flutter/material.dart';

import '../Pages/ReadNews.dart';

class NewsBar extends StatefulWidget {
  final String id;
  final String title;
  final String type;
  final String description;
  final String keywords;
  final String link;
  final String image;

  const NewsBar(
      {super.key,
      required this.id,
      required this.title,
      required this.type,
      required this.description,
      required this.keywords,
      required this.link,
      required this.image});

  @override
  State<StatefulWidget> createState() => _NewsStatState();
}

class _NewsStatState extends State<NewsBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Card(
            elevation: 5,
            color: Colors.white,
            clipBehavior: Clip.hardEdge,
            child: TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ReadNews(id: widget.id)));
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: [
                      Image.network(
                        'http://185.215.180.181:9934/${widget.image}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Flexible(
                          flex: 1,
                          fit: FlexFit.tight,
                          child: Column(children: <Widget>[
                            Text(
                              widget.title,
                              textAlign: TextAlign.left,
                              textWidthBasis: TextWidthBasis.parent,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              "${widget.type} - ${widget.keywords}: Near ${widget.link}",
                              style: const TextStyle(),
                            ),
                          ]))
                    ],
                  ),
                ))));
  }
}
