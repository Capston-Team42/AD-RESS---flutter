import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordScreen extends StatefulWidget {
  final String token; // 로그인 시 받은 accessToken

  const ChangePasswordScreen({super.key, required this.token});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String _message = '';
  Color _messageColor = Colors.red;

  Future<void> _changePassword() async {
    final backendIp = dotenv.env['BACKEND_IP'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8080/api/user/change-password');
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({
        'currentPassword': _currentPasswordController.text,
        'newPassword': _newPasswordController.text,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      setState(() {
        _message = data['message'] ?? '비밀번호가 성공적으로 변경되었습니다.';
        _messageColor = Colors.green;
      });
    } else {
      setState(() {
        _message = data['message'] ?? '비밀번호 변경에 실패했습니다.';
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('비밀번호 변경'),
            ),
            const SizedBox(height: 12),
            Text(_message, style: TextStyle(color: _messageColor)),
          ],
        ),
      ),
    );
  }
}
