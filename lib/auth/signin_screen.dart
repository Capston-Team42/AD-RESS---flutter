import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final loginState = context.read<LoginStateManager>();

    // 기억하기 설정된 경우, 입력 필드 자동 채우기
    if (loginState.rememberLogin) {
      _usernameController.text = loginState.userId ?? '';
      _passwordController.text = loginState.password ?? '';
      _rememberMe = true;
    }
  }

  Future<void> _signin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final backendIp = dotenv.env['BACKEND_IP'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8080/api/auth/signin');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": _usernameController.text.trim(),
        "password": _passwordController.text,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      // TODO: 로그인 성공 시 홈 화면 등으로 이동
      await Provider.of<LoginStateManager>(
        context,
        listen: false,
      ).saveLoginData(
        userId: _usernameController.text.trim(),
        password: _passwordController.text,
        token: data['token'],
        rememberLogin: _rememberMe,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() {
        _errorMessage = data['message'] ?? '로그인에 실패했습니다.';
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: AutofillGroup(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 218, 230, 219),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 6, 76, 8),
                    ),
                  ),
                  fillColor: Color.fromARGB(255, 232, 246, 232),
                  filled: true,
                  hintText: '아이디',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 120, 120, 120),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 218, 230, 219),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 6, 76, 8),
                    ),
                  ),
                  fillColor: Color.fromARGB(255, 232, 246, 232),
                  filled: true,
                  hintText: '비밀번호',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 120, 120, 120),
                  ),
                ),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
              ),
              const SizedBox(height: 3),
              CheckboxListTile(
                value: _rememberMe,
                onChanged: (val) => setState(() => _rememberMe = val ?? false),
                title: const Text('아이디, 비밀번호 기억하기'),
                activeColor: Colors.green, // 체크박스 활성화 시 색상
                checkColor: Colors.white, // 체크 표시 색

                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _signin,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('로그인'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/signup'),
                    child: const Text('회원가입'),
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    onPressed:
                        () => Navigator.pushNamed(context, '/forgot-password'),
                    child: const Text('비밀번호 찾기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
