import 'dart:convert';
import 'package:chat_v0/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'login_state_manager.dart';

class PostDetailProvider with ChangeNotifier {
  final LoginStateManager? loginStateManager;

  PostDetailProvider(this.loginStateManager);

  Post? _post;
  bool _isLoading = false;

  Post? get post => _post;
  bool get isLoading => _isLoading;

  Future<void> fetchPostDetail(String postId) async {
    _isLoading = true;
    notifyListeners();

    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';

    if (authToken == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final uri = Uri.parse('http://$backendIp:8081/api/posts/$postId');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        _post = Post.fromJson(jsonData);
      } else {
        _post = null;
      }
    } catch (e) {
      _post = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearPost() {
    _post = null;
    notifyListeners();
  }
}
