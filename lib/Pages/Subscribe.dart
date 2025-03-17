import 'package:ambulex_users/Pages/Home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Components/Utils.dart';
import '../Components/MyTextInput.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:async'; // Add this import
import 'package:google_fonts/google_fonts.dart'; // Add Google Fonts for better typography

class Subscribe extends StatefulWidget {
  @override
  _SubscribeState createState() => _SubscribeState();
}

class _SubscribeState extends State<Subscribe> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? subscriptionInfo;
  List<dynamic>? payments;
  bool isLoading = false;
  bool paymentMade = false; // Track if payment has been made

  final TextEditingController _amountController = TextEditingController();
  String userid = '';
  String phoneNumber = ''; // To store the user's phone number
  final double subscriptionAmount = 200.0; // Constant subscription amount
  Timer? _timer; // Declare a Timer variable

  @override
  void initState() {
    super.initState();
    getUserInfo();
    _startPaymentUpdateTimer(); // Start the timer
  }

  void _startPaymentUpdateTimer() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      fetchPayments(); // Fetch payments every 10 seconds
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
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
      if (!decoded.containsKey("UserID") || !decoded.containsKey("Phone")) {
        print('Decoded token is invalid or does not contain user ID or Phone');
        _showSnackbar('Invalid token. Please log in again.');
        return;
      }

      setState(() {
        userid = decoded["UserID"];
        var phone = decoded["Phone"]; // Get the user's phone number
        phoneNumber = phone;
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
          'amountPaid': subscriptionAmount,
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
        'amountPaid': subscriptionAmount,
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
      await fetchPayments();
      setState(() {
        paymentMade = true; // Set paymentMade to true after successful payment
      });
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
          title: Text('Confirm Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Phone Number: +$phoneNumber'),
                Text('Amount: Ksh${subscriptionAmount.toString()}'),
                SizedBox(height: 10),
                Text('Please ensure you have enough money in your M-Pesa.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _showSnackbar('Initiating payment...');

                final paymentResponse = await initiatePayment(
                    phoneNumber, subscriptionAmount.toString());

                if (paymentResponse != null) {
                  print('Payment Response: $paymentResponse');
                  // Check for success
                  if (paymentResponse['success'] == true) {
                    // Show success message if payment is successful
                    _showSnackbar(
                        'Payment initiated successfully! Receipt: ${paymentResponse['mpesaReceiptNumber']}',
                        isSuccess: true);
                    await fetchPayments(); // Refresh payment history after payment initiation
                    setState(() {
                      paymentMade =
                          true; // Set paymentMade to true after successful payment
                    });
                  } else {
                    // Handle failure or cancellation
                    String message =
                        paymentResponse['message'] ?? 'Transaction failed';
                    _showSnackbar(message);
                  }

                  await fetchPayments();
                } else {
                  _showSnackbar('Failed to initiate payment');
                }

                Navigator.of(context).pop();
              },
              child: Text('Pay'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackbar('User cancelled prompt');
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
      _showSnackbar("Enter a valid phone number");
      return null;
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
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Payment initiated with ID: ${responseData['paymentId']}');
      _showSnackbar('Payment initiated successfully!');
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
        title: Text(
          'Subscribe',
          style: GoogleFonts.lato(
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        padding: EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text('Welcome to Ambulex',
                style: GoogleFonts.lato(
                    fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('View subscription information and payment',
                style: GoogleFonts.lato(fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: createSubscription,
              child: Text('Subscribe Now',
                  style: GoogleFonts.lato(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
            // Change button to "Go to Home" if payment has been made

            SizedBox(height: 20),
            if (isLoading) Center(child: loadingAnimationWidget()),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Subscription Status: ${subscriptionInfo?['status'] ?? 'No Subscription'}',
                        style: GoogleFonts.lato(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                    SizedBox(height: 10),
                    Text(
                        'Subscription Amount: Ksh${subscriptionInfo?['amountPaid'] ?? '0.00'}',
                        style: GoogleFonts.lato(
                            fontSize: 20, color: Colors.black54)),
                    SizedBox(height: 10),
                    Text(
                        'Time Span: ${subscriptionInfo?['paymentDate'] ?? '0.00'} -> ${subscriptionInfo?['endDate'] ?? '0.00'}',
                        style: GoogleFonts.lato(
                            fontSize: 20, color: Colors.black54)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('Payments:',
                style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            Expanded(
              child: payments == null || payments!.isEmpty
                  ? Center(
                      child: Text('No payments found',
                          style: GoogleFonts.lato(
                              color: Colors.black54, fontSize: 18)))
                  : ListView.builder(
                      itemCount: payments!.length,
                      itemBuilder: (context, index) {
                        // Parse the payment date
                        DateTime paymentDate =
                            DateTime.parse(payments![index]['createdAt']);
                        String formattedDate =
                            "${paymentDate.toLocal()}".split(' ')[0]; // Date
                        String formattedTime = "${paymentDate.toLocal()}"
                            .split(' ')[1]
                            .split('.')[0]; // Time

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            title: Text(
                                'Payment Amount: Ksh${payments![index]['amountPaid']}',
                                style: GoogleFonts.lato(color: Colors.black)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: $formattedDate',
                                    style: TextStyle(color: Colors.grey)),
                                Text('Time: $formattedTime',
                                    style: TextStyle(color: Colors.grey)),
                                Text(
                                    'M-Pesa Reference: ${payments![index]['mpesaReceiptNumber']}',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 20),
            if (payments == null ||
                payments!.isEmpty) // Show "Make Payment" if no payments
              ElevatedButton(
                onPressed: _showPaymentDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Make Payment',
                    style: GoogleFonts.lato(fontSize: 18, color: Colors.white)),
              ),
            if (payments != null &&
                payments!.isNotEmpty) // Show "Go to Home" if there are payments
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => Home()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: Text('Go to Home',
                    style: GoogleFonts.lato(fontSize: 18, color: Colors.white)),
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
