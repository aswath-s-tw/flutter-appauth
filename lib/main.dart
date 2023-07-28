import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';


Map<String, dynamic> parseJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) {
    throw Exception('invalid token');
  }

  final payload = _decodeBase64(parts[1]);
  final payloadMap = json.decode(payload);
  if (payloadMap is! Map<String, dynamic>) {
    throw Exception('invalid payload');
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
      throw Exception('Illegal base64url string!"');
  }

  return utf8.decode(base64Url.decode(output));
}


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterAppAuth appAuth = const FlutterAppAuth();

  String postSignInText = "";
  bool isLoading = false;

  void onSignInPressed() async {
    try {
      setState(() {
        isLoading = true;
      });
      final AuthorizationTokenResponse result =
          (await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          const String.fromEnvironment("CLIENT_ID"),
          const String.fromEnvironment("REDIRECT_URL"),
          discoveryUrl: const String.fromEnvironment("DISCOVERY_URL"),
          scopes: [
            'openid',
            'profile',
            'email',
            'offline_access',
          ],
        ),
      ))!;
      print("${result.accessToken} accessToken");
      print("${result.idToken} idToken");
      print("${result.refreshToken} refreshToken");

      Map<String,dynamic> parsedIdToken = parseJwt(result.idToken!);

      setState(() {
        postSignInText = "Name: ${parsedIdToken["name"]}, Email: ${parsedIdToken["email"]}";
        isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('User cancelled flow')) {
        // The user cancelled the authentication, handle this case here
        print('User cancelled login');
      } else {
        // Other exceptions can still be caught here
        print('An error occurred: $e');
      }

      setState(() {
        postSignInText = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Appauth Okta"),
        ),
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : postSignInText != ""
                  ? Text(postSignInText)
                  : ElevatedButton(
                      onPressed: onSignInPressed,
                      child: const Text("Sign In"),
                    ),
        ),
      ),
    );
  }
}
