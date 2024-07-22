// ignore_for_file: file_names, library_private_types_in_public_api
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../Components/NewsBar.dart';
import '../Components/Utils.dart';
import '../Model/NewsItem.dart';

class InfiniteNewsScrollPaginatorDemo extends StatefulWidget {
  const InfiniteNewsScrollPaginatorDemo({
    super.key,
  });

  @override
  _InfiniteNewsScrollPaginatorDemoState createState() =>
      _InfiniteNewsScrollPaginatorDemoState();
}

class _InfiniteNewsScrollPaginatorDemoState
    extends State<InfiniteNewsScrollPaginatorDemo> {
  final _numberOfPostsPerRequest = 5;

  final PagingController<int, NewsItem> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final response = await get(
        Uri.parse("${getUrl()}news"),
      );

      List responseList = json.decode(response.body);

      List<NewsItem> postList = responseList
          .map((data) => NewsItem(
              data['ID'],
              data['Title'],
              data['Type'],
              data['Description'],
              data['Keywords'],
              data['Link'],
              data['Image']))
          .toList();

      final isLastPage = postList.length < _numberOfPostsPerRequest;
      if (isLastPage) {
        _pagingController.appendLastPage(postList);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(postList, nextPageKey);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.sync(() => _pagingController.refresh()),
      child: PagedListView<int, NewsItem>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<NewsItem>(
          itemBuilder: (context, item, index) => Padding(
            padding: const EdgeInsets.all(0),
            child: NewsBar(
                id: item.id,
                title: item.title,
                type: item.type,
                description: item.description,
                keywords: item.keywords,
                link: item.link,
                image: item.image),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
