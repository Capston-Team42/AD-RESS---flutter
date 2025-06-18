import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_v0/providers/login_state_manager.dart';

class ChangeUsernameScreen extends StatefulWidget {
  const ChangeUsernameScreen({super.key});

  @override
  State<ChangeUsernameScreen> createState() => _ChangeUsernameScreenState();
}

class _ChangeUsernameScreenState extends State<ChangeUsernameScreen> {
  final _usernameController = TextEditingController();
  String _message = '';
  Color _messageColor = Colors.red;

  Future<void> _changeUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      setState(() {
        _message = '새 사용자명을 입력해주세요.';
        _messageColor = Colors.red;
      });
      return;
    }

    final loginManager = Provider.of<LoginStateManager>(context, listen: false);
    final token = loginManager.accessToken;

    if (token == null) {
      setState(() {
        _message = '로그인이 필요합니다.';
        _messageColor = Colors.red;
      });
      return;
    }

    final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'localhost';
    final uri = Uri.parse('http://$backendIp:8080/api/user/change-username');

    final request = http.Request('PUT', uri);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });
    request.body = jsonEncode({"username": newUsername});

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      final newToken = data['token'];
      final updatedUsername = data['username'];

      // 저장소에 새 토큰 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', newToken);

      // 상태관리 업데이트
      loginManager.setToken(newToken);
      loginManager.setUsername(updatedUsername);

      setState(() {
        _message = '사용자명이 성공적으로 변경되었습니다.';
        _messageColor = Colors.green;
      });
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context, updatedUsername);
      });
    } else {
      setState(() {
        _message = data['message'] ?? '사용자명 변경 실패';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용자명 변경')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: '새 사용자명'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changeUsername,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 13, 52, 3),
              ),
              child: const Text('변경하기', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 12),
            Text(_message, style: TextStyle(color: _messageColor)),
          ],
        ),
      ),
    );
  }
}
