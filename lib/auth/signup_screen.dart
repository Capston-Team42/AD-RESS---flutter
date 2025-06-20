import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  String _errorMessage = '';

  Future<void> _signup() async {
    final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8080/api/auth/signup');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": _usernameController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
      }),
    );

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      Navigator.pushNamed(context, '/verify-email');
    } else {
      setState(() {
        _errorMessage = data['message'] ?? '회원가입에 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _usernameController,
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
                    hintText: '아이디',
                    hintStyle: TextStyle(
                      color: Color.fromARGB(255, 120, 120, 120),
                    ),
                  ),
                ),
                SizedBox(height: 12),
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
                    hintText: '이메일',
                    hintStyle: TextStyle(
                      color: Color.fromARGB(255, 120, 120, 120),
                    ),
                  ),
                ),
                SizedBox(height: 12),
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
                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 13, 52, 3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('회원가입'),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 35),
                    SizedBox(
                      width: 145,
                      child: Text('이미 회원인가요?', style: TextStyle(fontSize: 14)),
                    ),
                    Icon(
                      Icons.arrow_right_alt_rounded,
                      size: 18,
                      color: Color.fromARGB(255, 13, 52, 3),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signin'),
                      child: const Text(
                        '로그인',
                        style: TextStyle(
                          color: Color.fromARGB(255, 13, 52, 3),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
