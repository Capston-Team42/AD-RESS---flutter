import 'dart:convert';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class LikePostProvider with ChangeNotifier {
  late final LoginStateManager? loginStateManager;
  LikePostProvider(this.loginStateManager);

  final Map<String, bool> _likedMap = {};
  final Map<String, int> _likeCountMap = {};

  bool isLiked(String postId) => _likedMap[postId] ?? false;
  int getLikeCount(String postId) => _likeCountMap[postId] ?? 0;

  Future<void> checkLikeStatus(String postId) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final url = Uri.parse(
      'http://$backendIp:8081/api/likes/check?postId=$postId',
    );

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (res.statusCode == 200) {
      final liked = res.body.toLowerCase() == 'true';
      _likedMap[postId] = liked;
      notifyListeners();
    }
  }

  Future<void> fetchLikeCount(String postId) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final url = Uri.parse(
      'http://$backendIp:8081/api/likes/count?postId=$postId',
    );

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (res.statusCode == 200) {
      _likeCountMap[postId] = int.tryParse(res.body) ?? 0;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final url = Uri.parse('http://$backendIp:8081/api/likes/toggle');

    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'postId': postId}),
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      _likedMap[postId] = data['liked'];
      _likeCountMap[postId] = data['likeCount'];
      notifyListeners();
    }
  }
}
