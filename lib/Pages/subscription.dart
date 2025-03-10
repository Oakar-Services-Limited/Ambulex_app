// ignore_for_file: library_private_types_in_public_api

import 'package:ambulex_users/Pages/Subscribe.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Components/Utils.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Subscriptions extends StatefulWidget {
  const Subscriptions({super.key});

  @override
  _SubscriptionsState createState() => _SubscriptionsState();
}

class _SubscriptionsState extends State<Subscriptions> {
  Map<String, dynamic>? subscriptionInfo;
  List<dynamic>? payments;

  @override
  void initState() {
    super.initState();
    fetchSubscriptionInfo();
  }

  Future<void> fetchSubscriptionInfo() async {
    final response = await getSubscriptionInfo();
    if (response != null) {
      setState(() {
        subscriptionInfo = response;
      });
      await fetchPayments();
    } else {
      setState(() {
        subscriptionInfo = {};
      });
      print('Failed to fetch subscription info');
    }
  }

  Future<void> fetchPayments() async {
    final response = await getPayments();
    if (response != null) {
      setState(() {
        payments = response;
      });
    } else {
      setState(() {
        payments = [];
      });
      print('Failed to fetch payments');
    }
  }

  Future<Map<String, dynamic>?> getSubscriptionInfo() async {
    final response = await http.get(Uri.parse('${getUrl()}subscription'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to load subscription info: ${response.statusCode}');
      return null;
    }
  }

  Future<List<dynamic>?> getPayments() async {
    final response = await http.get(Uri.parse('${getUrl()}payments'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to load payments: ${response.statusCode}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Info'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => Subscribe()));
          },
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        color: Colors.white,
        child: subscriptionInfo != null || payments != null
            ? Center(
                child: Text('Loading data...',
                    style: TextStyle(color: Colors.black54, fontSize: 18)),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subscription Details Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subscription: ${subscriptionInfo?['name'] ?? 'No Subscription'}',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Current Balance: \$${subscriptionInfo?['balance'] ?? '0.00'}',
                            style:
                                TextStyle(fontSize: 20, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Payments:',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  Expanded(
                    child: payments == null || payments!.isEmpty
                        ? Center(
                            child: Text('No payments found',
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 18)))
                        : ListView.builder(
                            itemCount: payments!.length,
                            itemBuilder: (context, index) {
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 8.0),
                                child: ListTile(
                                  title: Text(
                                      'Payment: ${payments![index]['amount']}',
                                      style: TextStyle(color: Colors.black)),
                                  subtitle: Text(
                                      'Date: ${payments![index]['date']}',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget loadingAnimationWidget() {
    return LoadingAnimationWidget.staggeredDotsWave(
      color: Colors.blue,
      size: 100,
    );
  }
}
