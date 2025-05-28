import 'package:ambulex_users/Pages/Home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Components/Utils.dart';
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
      if (mounted) {
        // Only fetch if widget is still mounted
        fetchPayments();
      } else {
        _timer?.cancel(); // Cancel timer if widget is not mounted
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Ensure timer is cancelled when widget is disposed
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
    try {
      print('Subscription User ID: $userid');
      final response =
          await http.get(Uri.parse('${getUrl()}subscriptions/user/$userid'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to load subscription info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching subscription info: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getPayments() async {
    try {
      final response =
          await http.get(Uri.parse('${getUrl()}payments/user/$userid'));
      print('Fetching payments for user ID: $userid'); // Log the user ID
      print(
          'Response status: ${response.statusCode}'); // Log the response status
      print('Response body: ${response.body}'); // Log the response body
      if (response.statusCode == 200) {
        return json.decode(response.body)['data']; // Access the 'data' field
      } else {
        print('Failed to load payments: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching payments: $e');
      return null;
    }
  }

  Future<void> createSubscription() async {
    try {
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
        _showPaymentDialog();
        await fetchSubscriptionInfo();
        await fetchPayments();
        setState(() {
          paymentMade =
              true; // Set paymentMade to true after successful payment
        });
      } else {
        _showSnackbar('Failed to create subscription: ${response.statusCode}');
        print('Failed to create subscription: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error creating subscription: $e');
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Payment Confirmation',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You will receive an M-Pesa prompt on:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '+$phoneNumber',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.pop(context); // Close current dialog
                      _showPhoneNumberEditDialog();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Amount: KES ${subscriptionAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Please enter your M-Pesa PIN when prompted.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSnackbar('Payment cancelled');
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _initiateSTKPush();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Proceed',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPhoneNumberEditDialog() {
    final TextEditingController phoneController =
        TextEditingController(text: phoneNumber);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Edit Phone Number',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter the phone number that will receive the M-Pesa prompt:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 12,
                decoration: InputDecoration(
                  hintText: 'e.g., 254700000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.phone, color: Colors.blue),
                  counterText: '',
                  prefixText: '',
                ),
                onChanged: (value) {
                  // Remove any non-digit characters
                  String digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

                  // If user tries to remove 254, add it back
                  if (!digitsOnly.startsWith('254')) {
                    digitsOnly = '254${digitsOnly.replaceAll('254', '')}';
                  }

                  // Update the text field with the formatted number
                  if (value != digitsOnly) {
                    phoneController.value = TextEditingValue(
                      text: digitsOnly,
                      selection:
                          TextSelection.collapsed(offset: digitsOnly.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Number must start with 254 and be 12 digits long',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showPaymentDialog(); // Show payment dialog again
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newPhone = phoneController.text.trim();
                // Validate phone number format
                if (newPhone.length == 12 && newPhone.startsWith('254')) {
                  setState(() {
                    phoneNumber = newPhone;
                  });
                  Navigator.pop(context);
                  _showPaymentDialog(); // Show payment dialog with new number
                } else {
                  _showSnackbar(
                      'Please enter a valid phone number (12 digits starting with 254)');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _initiateSTKPush() async {
    _showSnackbar('Processing Payment...');
    final paymentResponse =
        await initiatePayment(phoneNumber, subscriptionAmount.toString());

    if (paymentResponse != null) {
      _showPaymentConfirmationDialog();
    } else {
      _showSnackbar('Failed to initiate payment');
    }
  }

  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirm Payment',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mobile_friendly,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Have you completed the payment on your phone?',
                style: GoogleFonts.poppins(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close only the dialog
                _showSnackbar('Payment cancelled');
              },
              child: Text(
                'No, Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close only the dialog
                await fetchPayments();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes, Completed',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
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
          'amount': subscriptionAmount,
          'userId': userid, // Ensure userid is correctly set
        })}');

    final response = await http.post(
      Uri.parse(requestUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'phoneNumber': phoneNumber,
        'amount': subscriptionAmount,
        'userId': userid, // Include userId in the request body
      }),
    );

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
          "Subscription",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const Home()));
            },
          ),
        ],
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      floatingActionButton: ElevatedButton(
        onPressed: _showPaymentDialog,
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 5),
        child: Text(
          'Make Payment',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await fetchSubscriptionInfo();
                    await fetchPayments();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubscriptionCard(),
                        const SizedBox(height: 24),
                        _buildPaymentsSection(),
                        if (isLoading) Center(child: loadingAnimationWidget()),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Home()),
              );
            },
            icon: Icon(Icons.arrow_back, color: Colors.blue.shade700),
          ),
          Text(
            'Subscription',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const Spacer(),
          if (!paymentMade)
            ElevatedButton.icon(
              onPressed: createSubscription,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Subscribe',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final bool isActive = subscriptionInfo?['status'] == 'active';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [Colors.blue.shade400, Colors.blue.shade700]
                : [Colors.grey.shade400, Colors.grey.shade700],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isActive ? Icons.verified : Icons.warning_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Status',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subscriptionInfo?['status']?.toUpperCase() ??
                          'NO SUBSCRIPTION',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildSubscriptionDetail(
              'Amount Paid',
              'Ksh${subscriptionInfo?['amountPaid'] ?? '0.00'}',
              Icons.payment,
            ),
            const SizedBox(height: 16),
            _buildSubscriptionDetail(
              'Valid Until',
              _formatDate(subscriptionInfo?['endDate']),
              Icons.event,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 16),
        if (payments == null || payments!.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No payments found',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _showPaymentDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Make Payment',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments!.length,
            itemBuilder: (context, index) {
              final payment = payments![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(Icons.receipt, color: Colors.blue.shade700),
                  ),
                  title: Text(
                    'Ksh${payment['amountPaid']}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateTime(payment['createdAt']),
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      Text(
                        'Ref: ${payment['mpesaReceiptNumber']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDateTime(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Widget loadingAnimationWidget() {
    return LoadingAnimationWidget.staggeredDotsWave(
      color: Colors.blue,
      size: 100,
    );
  }
}
