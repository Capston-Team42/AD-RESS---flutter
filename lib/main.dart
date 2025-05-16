import 'dart:convert';
import 'package:chat_v0/auth/forgot_password_screen.dart';
import 'package:chat_v0/auth/signin_screen.dart';
import 'package:chat_v0/auth/signup_screen.dart';
import 'package:chat_v0/auth/verify_email_screen.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:chat_v0/providers/item_provider.dart';
import 'package:chat_v0/providers/wardobe_provider.dart';
import 'package:chat_v0/spash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'homepage.dart'; // 로그인 후 이동할 메인 화면

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final loginStateManager = LoginStateManager();
  await loginStateManager.loadLoginInfo(); // id/pw, token 불러오기

  // 자동 로그인 시도
  if (loginStateManager.accessToken != null) {
    await loginStateManager.tryAutoLogin((id, pw) async {
      final backendIp = dotenv.env['BACKEND_IP']!;
      final uri = Uri.parse('http://$backendIp:8080/api/auth/signin');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"username": id, "password": pw}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginStateManager>.value(
          value: loginStateManager,
        ),
        ChangeNotifierProxyProvider<LoginStateManager, WardrobeProvider>(
          create: (_) => WardrobeProvider(null),
          update:
              (_, loginStateManager, __) => WardrobeProvider(loginStateManager),
        ),
        ChangeNotifierProxyProvider<LoginStateManager, ItemProvider>(
          create: (_) => ItemProvider(null),
          update: (_, loginStateManager, __) => ItemProvider(loginStateManager),
        ),
      ],
      child: const AdressApp(),
    ),
  );
}

class AdressApp extends StatelessWidget {
  const AdressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginStateManager>(
      builder: (context, loginManager, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: Colors.white),
          home: const SplashScreen(), // ✅ 로그인 여부 판단 화면
          routes: {
            '/signin': (_) => const SigninScreen(),
            '/signup': (_) => const SignupScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/verify-email': (_) => const VerifyEmailScreen(),
            '/home': (_) => const HomePage(),
          },
        );
      },
    );
  }
}
