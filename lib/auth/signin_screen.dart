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
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    final loginState = context.read<LoginStateManager>();

    // 기억하기 설정된 경우, 입력 필드 자동 채우기
    if (loginState.rememberLogin) {
      _usernameController.text = loginState.username ?? '';
      _passwordController.text = loginState.password ?? '';
      _rememberMe = true;
    }
  }

  Future<void> _signin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'default_ip_address';
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
      await Provider.of<LoginStateManager>(
        context,
        listen: false,
      ).saveLoginData(
        userId: data['id'],
        username: _usernameController.text.trim(),
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 200),
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
                              color: Color.fromARGB(255, 13, 52, 3),
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
                          hintText: '비밀번호',
                          hintStyle: TextStyle(
                            color: Color.fromARGB(255, 120, 120, 120),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        autofillHints: const [AutofillHints.password],
                      ),
                      CheckboxListTile(
                        value: _rememberMe,
                        onChanged:
                            (val) => setState(() => _rememberMe = val ?? false),
                        title: const Text(
                          '아이디, 비밀번호 기억하기',
                          style: TextStyle(fontSize: 14),
                        ),
                        activeColor: Color.fromARGB(255, 122, 255, 89),
                        checkColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(1),
                        ),
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
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _signin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 13, 52, 3),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('로그인'),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 35),
                          const SizedBox(
                            width: 145,
                            child: Text(
                              '회원이 아니신가요?',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_right_alt_rounded,
                            size: 18,
                            color: Color.fromARGB(255, 13, 52, 3),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.pushNamed(context, '/signup'),
                            child: const Text(
                              '회원가입',
                              style: TextStyle(
                                color: Color.fromARGB(255, 13, 52, 3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 35),
                          const SizedBox(
                            width: 145,
                            child: Text(
                              '비밀번호를 잊으셨나요?',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_right_alt_rounded,
                            size: 18,
                            color: Color.fromARGB(255, 13, 52, 3),
                          ),
                          TextButton(
                            onPressed:
                                () => Navigator.pushNamed(
                                  context,
                                  '/forgot-password',
                                ),
                            child: const Text(
                              '비밀번호 찾기',
                              style: TextStyle(
                                color: Color.fromARGB(255, 13, 52, 3),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
