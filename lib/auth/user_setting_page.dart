import 'package:chat_v0/auth/change_password_screen.dart';
import 'package:chat_v0/auth/change_username_screen.dart';
import 'package:chat_v0/auth/delete_account_screen.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final token =
        Provider.of<LoginStateManager>(context, listen: false).accessToken;

    return Scaffold(
      appBar: AppBar(title: const Text("개인 정보 설정")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("사용자명 변경"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangeUsernameScreen()),
              );
            },
          ),
          ListTile(
            title: const Text("비밀번호 변경"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          ListTile(
            title: const Text("계정 삭제"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () async {
              if (token != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeleteAccountScreen(token: token),
                  ),
                );
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("로그인 토큰이 없습니다.")));
              }
            },
          ),
        ],
      ),
    );
  }
}
