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
  final TextEditingController _phoneController =
      TextEditingController(); // For phone number

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    try {
      var token = await storage.read(key: "jwt");
      if (token == null) {
        _showSnackbar('User not logged in. Please log in again.');
        return;
      }

      var decoded = parseJwt(token.toString());
      print('Decoded token: $decoded');
      if (!decoded.containsKey("UserID")) {
        print('Decoded token is invalid or does not contain user ID');
        _showSnackbar('Invalid token. Please log in again.');
        return;
      }

      setState(() {
        userid = decoded["UserID"];
      });

      await fetchSubscriptionInfo();
      await fetchPayments(); // Fetch payments on user info retrieval
    } catch (e) {
      print('Error getting user info: $e');
      _showSnackbar('Error getting user info. Please try again.');
    }
  }

  Future<void> fetchSubscriptionInfo() async {
    final response = await getSubscriptionInfo();
    if (response != null &&
        response['data'] != null &&
        response['data'].isNotEmpty) {
      print('Subscription Info: $response');
      setState(() {
        subscriptionInfo = response['data'][0]; // Access the first subscription
      });
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
      print('Payments fetched: $response'); // Log the fetched payments
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
    print('Subscription User ID: $userid');
    final response =
        await http.get(Uri.parse('${getUrl()}subscriptions/user/$userid'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Failed to load subscription info: ${response.statusCode}');
      return null;
    }
  }

  Future<List<dynamic>?> getPayments() async {
    final response =
        await http.get(Uri.parse('${getUrl()}payments/user/$userid'));
    print('Fetching payments for user ID: $userid'); // Log the user ID
    print('Response status: ${response.statusCode}'); // Log the response status
    print('Response body: ${response.body}'); // Log the response body
    if (response.statusCode == 200) {
      return json.decode(response.body)['data']; // Access the 'data' field
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
      _showSnackbar('Subscription created successfully!', isSuccess: true);
      print('Subscription created successfully: ${response.body}');
      await fetchSubscriptionInfo();
      await fetchPayments(); // Refresh payment history after creating a subscription
    } else {
      _showSnackbar('Failed to create subscription: ${response.statusCode}');
      print('Failed to create subscription: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  }

  void _showSnackbar(String message, {bool isSuccess = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Make M-Pesa Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                String phoneNumber = _phoneController.text;
                String amount = _amountController.text;

                if (phoneNumber.isEmpty || amount.isEmpty) {
                  _showSnackbar('Please enter both phone number and amount');
                  return;
                }

                // Call the payment API here
                final paymentResponse =
                    await initiatePayment(phoneNumber, amount);
                if (paymentResponse != null) {
                  _showSnackbar('Payment initiated successfully!',
                      isSuccess: true);
                  _phoneController.clear();
                  _amountController.clear();
                  await fetchPayments(); // Refresh payment history after payment initiation
                } else {
                  _showSnackbar('Failed to initiate payment');
                  _phoneController.clear();
                  _amountController.clear();
                }

                Navigator.of(context).pop();
              },
              child: Text('Pay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>?> initiatePayment(
      String phoneNumber, String amount) async {
    if (phoneNumber.isEmpty) {
      _showSnackbar("Enter 12 digit phone number (254xxxxxxxxx)");
      return null;
    }

    if (phoneNumber.length == 10 && phoneNumber.startsWith('0')) {
      // Replace the leading '0' with '254'
      phoneNumber = phoneNumber.replaceFirst('0', '254');
    }

    final requestUrl =
        '${getUrl()}payments/initiate'; // Adjust the endpoint as necessary

    // Log the request body
    print('Request Body: ${json.encode({
          'phoneNumber': phoneNumber,
          'amount': double.tryParse(amount),
          'userId': userid, // Ensure userid is correctly set
        })}');

    final response = await http
        .post(
          Uri.parse(requestUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'phoneNumber': phoneNumber,
            'amount': double.tryParse(amount),
            'userId': userid, // Include userId in the request body
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print(
          'Payment initiated with ID: ${responseData['paymentId']}'); // Log the payment ID
      return responseData;
    } else {
      print('Failed to initiate payment: ${response.statusCode}');
      return null;
    }
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
                      'Subscription Status: ${subscriptionInfo?['status'] ?? 'No Subscription'}',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Amount Paid: \$${subscriptionInfo?['amountPaid'] ?? '0.00'}',
                      style: TextStyle(fontSize: 20, color: Colors.black54),
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
                        // Parse the payment date
                        DateTime paymentDate =
                            DateTime.parse(payments![index]['paymentDate']);
                        String formattedDate =
                            "${paymentDate.toLocal()}".split(' ')[0]; // Date
                        String formattedTime = "${paymentDate.toLocal()}"
                            .split(' ')[1]
                            .split('.')[0]; // Time

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                                'Payment Amount: \$${payments![index]['amountPaid']}',
                                style: TextStyle(color: Colors.black)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: $formattedDate',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'Time: $formattedTime',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  'M-Pesa Reference: ${payments![index]['mpesaReceiptNumber']}',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showPaymentDialog,
              child: Text('Make Payment'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue, // Text color
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
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
