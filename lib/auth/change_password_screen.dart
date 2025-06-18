import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:chat_v0/providers/login_state_manager.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _message = '';
  Color _messageColor = Colors.red;

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      setState(() {
        _message = '새 비밀번호가 일치하지 않습니다.';
        _messageColor = Colors.red;
      });
      return;
    }

    final token =
        Provider.of<LoginStateManager>(context, listen: false).accessToken;
    if (token == null) {
      setState(() {
        _message = '로그인 토큰이 없습니다.';
      });
      return;
    }

    final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'localhost';
    final uri = Uri.parse('http://$backendIp:8080/api/user/change-password');

    final request = http.Request('PUT', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.body = jsonEncode({
      "currentPassword": currentPassword,
      "newPassword": newPassword,
    });

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      setState(() {
        _message = '비밀번호가 성공적으로 변경되었습니다.';
        _messageColor = Colors.green;
      });

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    } else {
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);
      setState(() {
        _message = data['message'] ?? '비밀번호 변경 실패';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(labelText: '현재 비밀번호'),
              obscureText: true,
            ),
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
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 13, 52, 3),
              ),
              child: const Text(
                '비밀번호 변경',
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
