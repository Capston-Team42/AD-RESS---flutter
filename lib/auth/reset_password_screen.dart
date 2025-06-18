import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _message = '';
  Color _messageColor = Colors.red;

  Future<void> _resetPassword() async {
    if (widget.token.trim().isEmpty) {
      setState(() {
        _message = '유효하지 않은 재설정 요청입니다.';
        _messageColor = Colors.red;
      });
      return;
    }
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      setState(() {
        _message = '비밀번호가 일치하지 않습니다.';
        _messageColor = Colors.red;
      });
      return;
    }

    final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8080/api/auth/reset-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"token": widget.token, "newPassword": newPassword}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      setState(() {
        _message = data['message'] ?? '비밀번호가 성공적으로 재설정되었습니다.';
        _messageColor = Colors.green;
      });
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/signin');
      });
    } else {
      setState(() {
        _message = data['message'] ?? '비밀번호 재설정에 실패했습니다.';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(labelText: '새 비밀번호'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: '비밀번호 확인'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 13, 52, 3),
              ),
              child: const Text(
                '비밀번호 재설정',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(_message, style: TextStyle(color: _messageColor)),
          ],
        ),
      ),
    );
  }
}
