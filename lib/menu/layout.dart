import 'package:chat_v0/auth/user_setting_page.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void showCustomMenuDrawer(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "메뉴",
    barrierColor: Colors.black.withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      final screenHeight = MediaQuery.of(context).size.height;
      return Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          child: Material(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/myProfile');
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "MY PROFILE",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('설정'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserSettingsPage(),
                      ),
                    );
                  },
                ),
                SizedBox(height: screenHeight * 0.6),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Provider.of<LoginStateManager>(
                        context,
                        listen: false,
                      ).clearToken();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/signin',
                        (_) => false,
                      );
                    },
                    child: const Text('로그아웃'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('닫기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(animation);

      return SlideTransition(position: offset, child: child);
    },
  );
}
