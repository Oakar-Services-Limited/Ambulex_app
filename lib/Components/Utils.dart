// ignore_for_file: file_names
import 'dart:convert';
import 'package:http/http.dart';

String getUrl() {
  return "http://192.168.1.121:3003/";
    // return "http://161.97.169.110:3733/";

  // return "https://api.ambulexsolutions.org/";
}

Map<String, dynamic> parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    return <String, dynamic>{"error": "Invalid token"};
  }

  final payload = _decodeBase64(parts[1]);
  final payloadMap = json.decode(payload);
  if (payloadMap is! Map<String, dynamic>) {
    return <String, dynamic>{"error": "Invalid token"};
  }

  return payloadMap;
}

String _decodeBase64(String str) {
  String output = str.replaceAll('-', '+').replaceAll('_', '/');

  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw Exception('Illegal base64url string!');
  }

  return utf8.decode(base64.decode(output));
}

Future<bool> checkSubscriptionStatus(String userId) async {
  try {
    final response = await get(
      Uri.parse('${getUrl()}subscriptions/user/$userId'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data != null && data['data'] != null && data['data'].isNotEmpty) {
        var subscription = data['data'][0];
        return subscription['status'] == 'active';
      }
    }
    return false;
  } catch (e) {
    print('Error checking subscription status: $e');
    return false;
  }
}
