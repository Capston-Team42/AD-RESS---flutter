import 'package:chat_v0/auth/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';
  Color _messageColor = Colors.red;

  Future<void> _requestReset() async {
    final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8080/api/auth/forgot-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": _emailController.text.trim()}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      setState(() {
        _message = data['message'] ?? '재설정 메일이 발송되었습니다.';
        _messageColor = Colors.green;
      });
    } else {
      setState(() {
        _message = data['message'] ?? '비밀번호 재설정 요청에 실패했습니다.';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // 빈 공간에서도 터치 감지
          onTap: () {
            FocusScope.of(context).unfocus(); // 포커스 해제 => 키보드 내려감
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 218, 230, 219),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 13, 52, 3),
                    ),
                  ),
                  fillColor: Color.fromARGB(255, 232, 246, 232),
                  filled: true,
                  hintText: '가입한 이메일',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 120, 120, 120),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _requestReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 13, 52, 3),
                  foregroundColor: Colors.white,
                ),
                child: const Text('비밀번호 재설정 요청 전송'),
              ),
              const SizedBox(height: 12),
              Text(_message, style: TextStyle(color: _messageColor)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResetPasswordScreen(token: ''), // 빈 토큰
                    ),
                  );
                },
                child: const Text(
                  '비밀번호 재설정 페이지로 이동',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '인증 메일을 통해 받은 링크 없이 접근하면 재설정이 적용되지 않습니다.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
