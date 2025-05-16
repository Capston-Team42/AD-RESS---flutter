import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeleteAccountScreen extends StatefulWidget {
  final String token; // 로그인 시 발급된 JWT 토큰

  const DeleteAccountScreen({super.key, required this.token});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _passwordController = TextEditingController();
  String _message = '';
  Color _messageColor = Colors.red;

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('정말 삭제하시겠어요?'),
            content: const Text('계정 삭제는 되돌릴 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final backendIp = dotenv.env['BACKEND_IP'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8080/api/user/delete-account');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
      body: jsonEncode({'password': _passwordController.text}),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      setState(() {
        _message = data['message'] ?? '계정이 성공적으로 삭제되었습니다.';
        _messageColor = Colors.green;
      });

      // TODO: 초기화 및 로그인 화면으로 이동
      // Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
    } else {
      setState(() {
        _message = data['message'] ?? '계정 삭제에 실패했습니다.';
        _messageColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('계정 삭제')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '계정을 삭제하려면 비밀번호를 입력하세요.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _deleteAccount,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('계정 삭제'),
            ),
            const SizedBox(height: 12),
            Text(_message, style: TextStyle(color: _messageColor)),
          ],
        ),
      ),
    );
  }
}
