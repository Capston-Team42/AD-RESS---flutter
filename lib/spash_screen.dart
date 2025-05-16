import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginManager = Provider.of<LoginStateManager>(context);

    // 초기 상태 확인
    if (loginManager.isLoggedIn) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/signin');
      });
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
