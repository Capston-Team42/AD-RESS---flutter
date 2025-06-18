import 'dart:convert';
import 'package:chat_v0/auth/forgot_password_screen.dart';
import 'package:chat_v0/auth/signin_screen.dart';
import 'package:chat_v0/auth/signup_screen.dart';
import 'package:chat_v0/auth/verify_email_screen.dart';
import 'package:chat_v0/profile/my_profile.dart';
import 'package:chat_v0/profile/user_profile.dart';
import 'package:chat_v0/providers/comment_provider.dart';
import 'package:chat_v0/providers/community_provider.dart';
import 'package:chat_v0/providers/favorite_provider.dart';
import 'package:chat_v0/providers/input_focus_provider.dart';
import 'package:chat_v0/providers/like_post_provider.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:chat_v0/providers/item_provider.dart';
import 'package:chat_v0/providers/post_detail_provider.dart';
import 'package:chat_v0/providers/wardobe_provider.dart';
import 'package:chat_v0/spash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final loginStateManager = LoginStateManager();
  await loginStateManager.loadLoginInfo();

  // 자동 로그인 시도
  if (loginStateManager.accessToken != null) {
    await loginStateManager.tryAutoLogin((id, pw) async {
      final backendIp = dotenv.env['BACKEND_IP_REC']!;
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
    OverlaySupport.global(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => InputFocusProvider()),
          ChangeNotifierProvider<LoginStateManager>.value(
            value: loginStateManager,
          ),
          ChangeNotifierProxyProvider<LoginStateManager, WardrobeProvider>(
            create: (_) => WardrobeProvider(null),
            update:
                (_, loginStateManager, __) =>
                    WardrobeProvider(loginStateManager),
          ),
          ChangeNotifierProxyProvider<LoginStateManager, ItemProvider>(
            create: (_) => ItemProvider(null),
            update:
                (_, loginStateManager, __) => ItemProvider(loginStateManager),
          ),
          ChangeNotifierProvider(create: (_) => FavoriteProvider()),
          ChangeNotifierProxyProvider<LoginStateManager, CommunityProvider>(
            create: (_) => CommunityProvider(null),
            update:
                (_, loginStateManager, __) =>
                    CommunityProvider(loginStateManager),
          ),
          ChangeNotifierProxyProvider<LoginStateManager, PostDetailProvider>(
            create: (_) => PostDetailProvider(null),
            update:
                (_, loginStateManager, __) =>
                    PostDetailProvider(loginStateManager),
          ),
          ChangeNotifierProxyProvider<LoginStateManager, CommentProvider>(
            create: (_) => CommentProvider(null),
            update:
                (_, loginStateManager, __) =>
                    CommentProvider(loginStateManager),
          ),
          ChangeNotifierProxyProvider<LoginStateManager, LikePostProvider>(
            create: (_) => LikePostProvider(null),
            update:
                (_, loginStateManager, __) =>
                    LikePostProvider(loginStateManager),
          ),
        ],

        child: const AdressApp(),
      ),
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
            '/myProfile': (context) => const MyProfileScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/userProfile') {
              final username = settings.arguments as String;
              return MaterialPageRoute(
                builder: (context) => UserProfileScreen(username: username),
              );
            }
            return null;
          },
        );
      },
    );
  }
}
