// ignore_for_file: file_names
import 'dart:convert';

String getUrl() {
  // return "http://192.168.1.136:3003/api/";
  // return "http://20.20.20.239:3003/api/";
  // return "https://api-dashboard.ambulexsolutions.org/api/";
  return "http://161.97.169.110:3733/api/";
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
