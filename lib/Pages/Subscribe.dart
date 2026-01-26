import 'package:ambulex_users/Pages/Home.dart';
import 'package:ambulex_users/Pages/PackageDetail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Components/Utils.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:async'; // Add this import
import 'package:google_fonts/google_fonts.dart'; // Add Google Fonts for better typography

class Subscribe extends StatefulWidget {
  const Subscribe({super.key});

  @override
  _SubscribeState createState() => _SubscribeState();
}

class _SubscribeState extends State<Subscribe> {
  final storage = const FlutterSecureStorage();
  Map<String, dynamic>? subscriptionInfo;
  List<dynamic>? payments;
  List<dynamic>? packages;
  Map<String, dynamic>? selectedPackage;
  bool isLoading = false;
  bool isLoadingPackages = false;
  bool paymentMade = false; // Track if payment has been made

  String userid = '';
  String phoneNumber = ''; // To store the user's phone number
  double subscriptionAmount =
      200.0; // Default subscription amount, will be updated based on selected package
  Timer? _timer; // Declare a Timer variable

  @override
  void initState() {
    super.initState();
    getUserInfo();
    fetchPackages(); // Fetch available packages
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

  Future<void> fetchPackages() async {
    if (!mounted) return;
    setState(() {
      isLoadingPackages = true;
    });

    try {
      final url = '${getUrl()}packages';
      print('Fetching packages from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      print('Packages response status: ${response.statusCode}');
      print('Packages response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Decoded packages data: $data');

        // Handle different response structures
        List<dynamic>? packagesList;
        if (data is Map) {
          packagesList = data['data'] ?? (data['packages'] ?? null);
          // If data is directly a list
          if (packagesList == null && data is List) {
            packagesList = data as List<dynamic>?;
          }
        } else if (data is List) {
          packagesList = data;
        }

        if (!mounted) return;

        setState(() {
          packages = packagesList ?? [];
          print('Packages loaded: ${packages?.length ?? 0}');

          // Select first package by default if available
          if (packages != null &&
              packages!.isNotEmpty &&
              selectedPackage == null) {
            selectedPackage = packages![0];
            subscriptionAmount = _parsePrice(selectedPackage!['price']);
            print(
                'Selected package: ${selectedPackage!['name']} - ${selectedPackage!['price']}');
          }
        });
      } else {
        print('Failed to load packages: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (!mounted) return;
        setState(() {
          packages = [];
        });
        _showSnackbar('Failed to load packages (${response.statusCode})');
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      print('Error fetching packages: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        packages = [];
      });
      _showSnackbar('Error fetching packages: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingPackages = false;
        });
      }
    }
  }

  double _parsePrice(String priceString) {
    try {
      // Remove "Ksh" and any whitespace, then parse
      final cleaned =
          priceString.replaceAll('Ksh', '').replaceAll(' ', '').trim();
      return double.parse(cleaned);
    } catch (e) {
      print('Error parsing price: $e');
      return 200.0; // Default fallback
    }
  }

  void _selectPackage(Map<String, dynamic> package) {
    setState(() {
      selectedPackage = package;
      subscriptionAmount = _parsePrice(package['price']);
    });
    // Haptic feedback for better UX
    // HapticFeedback.lightImpact(); // Uncomment if you have haptic_feedback package
  }

  IconData _getPackageIcon(String packageName) {
    final name = packageName.toLowerCase();
    if (name.contains('lite') || name.contains('basic')) {
      return Icons.bolt;
    } else if (name.contains('plus')) {
      return Icons.add_circle;
    } else if (name.contains('prime')) {
      return Icons.star;
    } else if (name.contains('total') || name.contains('golden')) {
      return Icons.diamond;
    } else if (name.contains('careride')) {
      return Icons.directions_car;
    } else {
      return Icons.workspace_premium;
    }
  }

  Map<String, Color> _getPackageColorScheme(int index, String packageName) {
    final name = packageName.toLowerCase();

    // Color schemes for different packages
    if (name.contains('lite')) {
      return {
        'primary': Colors.green.shade600,
        'secondary': Colors.green.shade300,
      };
    } else if (name.contains('plus')) {
      return {
        'primary': Colors.blue.shade600,
        'secondary': Colors.blue.shade300,
      };
    } else if (name.contains('prime')) {
      return {
        'primary': Colors.purple.shade600,
        'secondary': Colors.purple.shade300,
      };
    } else if (name.contains('total')) {
      return {
        'primary': Colors.orange.shade600,
        'secondary': Colors.orange.shade300,
      };
    } else if (name.contains('golden')) {
      return {
        'primary': Colors.amber.shade700,
        'secondary': Colors.amber.shade300,
      };
    } else if (name.contains('careride')) {
      return {
        'primary': Colors.red.shade600,
        'secondary': Colors.red.shade300,
      };
    } else {
      // Default color schemes based on index
      final colors = [
        {'primary': Colors.blue.shade600, 'secondary': Colors.blue.shade300},
        {'primary': Colors.teal.shade600, 'secondary': Colors.teal.shade300},
        {
          'primary': Colors.indigo.shade600,
          'secondary': Colors.indigo.shade300
        },
        {'primary': Colors.pink.shade600, 'secondary': Colors.pink.shade300},
        {'primary': Colors.cyan.shade600, 'secondary': Colors.cyan.shade300},
        {
          'primary': Colors.deepPurple.shade600,
          'secondary': Colors.deepPurple.shade300
        },
      ];
      return colors[index % colors.length];
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

      final requestBody = {
        'userId': userid,
        'amountPaid': subscriptionAmount,
        'paymentDate': paymentDate,
        'startDate': startDate,
        'endDate': endDate,
        'status': status,
      };

      // Add package information if available
      if (selectedPackage != null) {
        requestBody['packageId'] = selectedPackage!['id'];
        requestBody['packageName'] = selectedPackage!['name'];
        // Include features array for backend to parse maxResponses
        if (selectedPackage!['features'] != null) {
          requestBody['features'] = selectedPackage!['features'];
        }
      }

      final response = await http.post(
        Uri.parse(requestUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
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
              if (selectedPackage != null) ...[
                Text(
                  'Package: ${selectedPackage!['name']}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Amount: ${selectedPackage?['price'] ?? 'KES ${subscriptionAmount.toStringAsFixed(2)}'}',
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

    try {
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

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Payment initiated with ID: ${responseData['paymentId']}');
        _showSnackbar('Payment initiated successfully!');
        return responseData;
      } else {
        final errorBody = json.decode(response.body);
        print('Failed to initiate payment: ${response.statusCode}');
        print('Error details: $errorBody');
        _showSnackbar(
            'Payment failed: ${errorBody['message'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('Exception during payment initiation: $e');
      _showSnackbar('Payment failed: ${e.toString()}');
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
      floatingActionButton: subscriptionInfo?['status'] != 'active'
          ? ElevatedButton(
              onPressed: selectedPackage == null
                  ? () {
                      _showSnackbar('Please select a package first');
                    }
                  : _showPaymentDialog,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5),
              child: Text(
                selectedPackage == null
                    ? 'Select Package'
                    : 'Subscribe - ${selectedPackage!['price']}',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            )
          : null,
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
                    await fetchPackages();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubscriptionCard(),
                        const SizedBox(height: 24),
                        if (subscriptionInfo?['status'] != 'active')
                          _buildPackagesSection(),
                        if (subscriptionInfo?['status'] != 'active')
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

  Widget _buildPackagesSection() {
    if (isLoadingPackages) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading packages...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (packages == null || packages!.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'No packages available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  fetchPackages();
                },
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: Colors.blue.shade700,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Select a Package',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the subscription plan that best fits your needs',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = MediaQuery.of(context).size.width;
            final isNarrow = w < 360;
            final isCompact = w >= 360 && w < 400;
            final isTablet = w >= 600;
            final crossAxisCount =
                isNarrow ? 1 : (isTablet ? (w > 900 ? 4 : 3) : 2);
            final spacing = isNarrow ? 8.0 : (isCompact ? 10.0 : 12.0);
            final aspectRatio =
                crossAxisCount == 1 ? 0.52 : (isNarrow ? 0.68 : 0.75);
            final cardPadding = isNarrow ? 10.0 : (isCompact ? 12.0 : 14.0);
            final iconSize = isNarrow ? 20.0 : (isCompact ? 22.0 : 24.0);
            final nameFontSize = isNarrow ? 12.0 : (isCompact ? 12.5 : 13.0);
            final featureFontSize = isNarrow ? 9.0 : (isCompact ? 9.5 : 10.0);
            final priceFontSize = isNarrow ? 15.0 : (isCompact ? 16.0 : 18.0);
            final borderRadius = isNarrow ? 12.0 : 16.0;
            final badgeTop = isNarrow ? 4.0 : 6.0;
            final badgePaddingH = isNarrow ? 4.0 : 6.0;
            final badgePaddingV = isNarrow ? 2.0 : 3.0;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: aspectRatio,
              ),
              itemCount: packages!.length,
              itemBuilder: (context, index) {
                final package = packages![index];
                final isSelected = selectedPackage != null &&
                    selectedPackage!['id'] == package['id'];
                final packageName = package['name'] ?? 'Package';
                final isPopular = packageName.toLowerCase().contains('prime') ||
                    packageName.toLowerCase().contains('total');
                final colorScheme = _getPackageColorScheme(index, packageName);

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PackageDetail(package: package),
                      ),
                    );
                    if (result != null && mounted) {
                      _selectPackage(result);
                      _showPaymentDialog();
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Stack(
                      children: [
                        Card(
                          elevation: isSelected ? 8 : 3,
                          shadowColor: isSelected
                              ? colorScheme['primary']!.withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(borderRadius),
                            side: BorderSide(
                              color: isSelected
                                  ? colorScheme['primary']!
                                  : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(borderRadius),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isSelected
                                    ? [
                                        colorScheme['primary']!
                                            .withOpacity(0.15),
                                        colorScheme['secondary']!
                                            .withOpacity(0.1),
                                        Colors.white,
                                      ]
                                    : [
                                        colorScheme['primary']!
                                            .withOpacity(0.08),
                                        colorScheme['secondary']!
                                            .withOpacity(0.05),
                                        Colors.white,
                                      ],
                              ),
                            ),
                            padding: EdgeInsets.all(cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(isNarrow ? 6 : 8),
                                      decoration: BoxDecoration(
                                        color: colorScheme['primary']!
                                            .withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                            isNarrow ? 8 : 10),
                                      ),
                                      child: Icon(
                                        _getPackageIcon(packageName),
                                        color: colorScheme['primary'],
                                        size: iconSize,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isSelected)
                                      Container(
                                        padding:
                                            EdgeInsets.all(isNarrow ? 3 : 4),
                                        decoration: BoxDecoration(
                                          color: colorScheme['primary'],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: isNarrow ? 14 : 16,
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: isNarrow ? 6 : 8),
                                Text(
                                  packageName,
                                  style: GoogleFonts.poppins(
                                    fontSize: nameFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? colorScheme['primary']!
                                            .withOpacity(0.9)
                                        : Colors.black87,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (package['features'] != null &&
                                    (package['features'] as List)
                                        .isNotEmpty) ...[
                                  SizedBox(height: isNarrow ? 4 : 6),
                                  ...((package['features'] as List)
                                      .take(2)
                                      .map((feature) {
                                    final featureName = feature is Map
                                        ? feature['name']
                                        : feature.toString();
                                    return Padding(
                                      padding: EdgeInsets.only(
                                          bottom: isNarrow ? 2 : 3),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: isNarrow ? 10 : 12,
                                            color: colorScheme['primary']!
                                                .withOpacity(0.7),
                                          ),
                                          SizedBox(width: isNarrow ? 3 : 4),
                                          Expanded(
                                            child: Text(
                                              featureName,
                                              style: GoogleFonts.poppins(
                                                fontSize: featureFontSize,
                                                color: Colors.grey.shade700,
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList()),
                                ],
                                const Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      package['price'] ?? 'N/A',
                                      style: GoogleFonts.poppins(
                                        fontSize: priceFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme['primary'],
                                      ),
                                    ),
                                    SizedBox(height: isNarrow ? 1 : 2),
                                    Text(
                                      'per year',
                                      style: GoogleFonts.poppins(
                                        fontSize: isNarrow ? 9 : 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isPopular && !isSelected)
                          Positioned(
                            top: badgeTop,
                            right: badgeTop,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: badgePaddingH,
                                vertical: badgePaddingV,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade400,
                                borderRadius:
                                    BorderRadius.circular(isNarrow ? 8 : 10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.white, size: 10),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Popular',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  int _getRemainingResponses() {
    final maxResponses = subscriptionInfo?['maxResponses'];
    final responsesUsed = subscriptionInfo?['responsesUsed'] ?? 0;

    if (maxResponses == null || maxResponses == -1) {
      return -1; // Unlimited
    }

    return maxResponses - responsesUsed;
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
            if (isActive && subscriptionInfo?['maxResponses'] != null) ...[
              const SizedBox(height: 16),
              _buildSubscriptionDetail(
                'Responses Remaining',
                _getRemainingResponses() >= 0
                    ? '${_getRemainingResponses()} / ${subscriptionInfo?['maxResponses']}'
                    : 'Unlimited',
                Icons.emergency,
              ),
            ],
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
