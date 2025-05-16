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
      return Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.5, // 화면의 2/5
          child: Material(
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 50),
                const ListTile(leading: Icon(Icons.home), title: Text('홈')),
                const ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('설정'),
                ),
                ElevatedButton(
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
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 닫기
                  },
                  child: const Text('닫기'),
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
