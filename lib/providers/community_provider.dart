import 'dart:convert';
import 'package:chat_v0/models/post_model.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CommunityProvider with ChangeNotifier {
  final LoginStateManager? loginStateManager;
  CommunityProvider(this.loginStateManager);

  List<Post> _posts = [];
  bool _isLoading = false;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;

  Future<int> fetchPosts({
    required String sort,
    required int page,
    required int size,
    bool append = true,
    bool reset = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    if (reset) {
      _posts = [];
    }

    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final url = Uri.parse(
      'http://$backendIp:8081/api/posts?sort=$sort&page=$page&size=$size',
    );

    int fetchedCount = 0;

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        final List<dynamic> contentList = decoded['content'] ?? [];

        final List<Post> newPosts =
            contentList.map((json) => Post.fromJson(json)).toList();

        fetchedCount = newPosts.length;

        if (append) {
          _posts.addAll(newPosts);
        } else {
          _posts = newPosts;
        }
      } else {
        if (!append) _posts = [];
      }
    } catch (e) {
      if (!append) _posts = [];
    }

    _isLoading = false;
    notifyListeners();

    return fetchedCount;
  }

  void clearPosts() {
    _posts = [];
    notifyListeners();
  }
}
