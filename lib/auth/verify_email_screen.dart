import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이메일 인증')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read, size: 50, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              '가입하신 이메일 주소로 인증 메일을 보냈습니다.\n메일함에서 인증 링크를 눌러주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: 인증 후 로그인 화면으로 이동
                // 인증이 잘 됐는지 여부를 로그인 진행시 확인하려면 isVerified를 서버에서 받아와야 함.
                // 이메일의 링크 클릭 → 서버에서 isVerified = true 처리가 이뤄져야 함.
                Navigator.pushNamed(context, '/signin');
              },
              child: const Text('로그인 화면으로'),
            ),
          ],
        ),
      ),
    );
  }
}
