import 'package:ambulex_users/Pages/subscription.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Components/Utils.dart';
import '../Components/MySelectInput.dart';
import '../Components/MyTextInput.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class Subscribe extends StatefulWidget {
  @override
  _SubscribeState createState() => _SubscribeState();
}

class _SubscribeState extends State<Subscribe> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? subscriptionInfo;
  List<dynamic>? payments;
  String? _selectedPlanType;
  bool isLoading = false;

  final List<String> planTypes = [
    'Select Plan',
    'Diamond',
    'Gold',
    'Silver',
    'Bronze'
  ];
  final TextEditingController _amountController = TextEditingController();
  String userid = '';

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    try {
      var token = await storage.read(key: "jwt");
      if (token == null) {
        print('JWT token is null');
        _showSnackbar('User not logged in. Please log in again.');
        return;
      }

      var decoded = parseJwt(token.toString());
      print('Decoded token: $decoded');
      if (decoded == null || !decoded.containsKey("UserID")) {
        print('Decoded token is invalid or does not contain user ID');
        _showSnackbar('Invalid token. Please log in again.');
        return;
      }

      setState(() {
        userid = decoded["UserID"];
      });

      print('User ID: $userid');

      fetchSubscriptionInfo();
    } catch (e) {
      print('Error getting user info: $e');
      _showSnackbar('Error getting user info. Please try again.');
    }
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

  Future<void> createSubscription() async {
    if (_selectedPlanType == null || _amountController.text.isEmpty) {
      _showSnackbar('Plan type and amount cannot be empty');
      print('Plan type and amount cannot be empty');
      return;
    }

    setState(() {
      isLoading = true;
    });

    final paymentDate = DateTime.now().toIso8601String();
    final startDate = DateTime.now().toIso8601String();
    final endDate = DateTime.now().add(Duration(days: 365)).toIso8601String();
    final status = 'active';

    final requestUrl = '${getUrl()}subscriptions';
    print('Request URL: $requestUrl');
    print('Request Body: ${json.encode({
          'userId': userid,
          'amountPaid': double.tryParse(_amountController.text),
          'paymentDate': paymentDate,
          'startDate': startDate,
          'endDate': endDate,
          'status': status,
        })}');

    final response = await http.post(
      Uri.parse(requestUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userid,
        'amountPaid': double.tryParse(_amountController.text),
        'paymentDate': paymentDate,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
      }),
    );

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 201) {
      _showSnackbar('Subscription created successfully!');
      print('Subscription created successfully: ${response.body}');
      fetchSubscriptionInfo();
    } else {
      _showSnackbar('Failed to create subscription: ${response.statusCode}');
      print('Failed to create subscription: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  void _showSnackbar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscribe'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => Subscriptions()));
          },
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MySelectInput(
              label: 'Plan Type',
              value: _selectedPlanType ?? '',
              list: planTypes,
              onSubmit: (String newValue) {
                setState(() {
                  _selectedPlanType = newValue;
                });
              },
            ),
            MyTextInput(
              title: 'Amount',
              value: _amountController.text,
              type: TextInputType.number,
              onSubmit: (value) {
                _amountController.text = value;
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: createSubscription,
              child: Text('Subscribe'),
            ),
            SizedBox(height: 16),
            if (isLoading)
              Center(
                child: loadingAnimationWidget(),
              ),
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
                      style: TextStyle(fontSize: 20, color: Colors.black54),
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
                          style:
                              TextStyle(color: Colors.black54, fontSize: 18)))
                  : ListView.builder(
                      itemCount: payments!.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                                'Payment: ${payments![index]['amount']}',
                                style: TextStyle(color: Colors.black)),
                            subtitle: Text('Date: ${payments![index]['date']}',
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
