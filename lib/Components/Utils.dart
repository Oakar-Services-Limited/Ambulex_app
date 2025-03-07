// ignore_for_file: file_names
import 'package:jwt_decoder/jwt_decoder.dart';

String getUrl() {
  return "http://192.168.1.136:3003/api/";
  // return "https://api-dashboard.ambulexsolutions.org/api/";
}

Map<String, dynamic>? decodeJwtToken(String token) {
  try {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    if (JwtDecoder.isExpired(token)) {
      // Token has expired
      return null;
    } else {
      // Token is valid and not expired, return decoded payload
      return decodedToken;
    }
  } catch (e) {
    return null;
  }
}
