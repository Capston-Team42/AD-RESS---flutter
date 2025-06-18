import 'dart:convert';

import 'package:chat_v0/models/post_model.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ProfileProvider with ChangeNotifier {
  final LoginStateManager? loginStateManager;
  ProfileProvider(this.loginStateManager);

  String? username;
  List<Post> myPosts = [];
  List<Post> likedPosts = [];
  List<Post> otherUserPosts = [];

  bool isLoading = false;

  Future<void> fetchMyProfile() async {
    isLoading = true;
    notifyListeners();

    final token = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8081/api/profile/me');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      username = data['username'];
      myPosts =
          (data['myPosts'] as List).map((json) => Post.fromJson(json)).toList();
      likedPosts =
          (data['likedPosts'] as List)
              .map((json) => Post.fromJson(json))
              .toList();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOtherProfile(String targetUsername) async {
    isLoading = true;
    notifyListeners();

    final token = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8081/api/profile/$targetUsername');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      username = data['username'];
      otherUserPosts =
          (data['posts'] as List).map((json) => Post.fromJson(json)).toList();
    }

    isLoading = false;
    notifyListeners();
  }

  void reset() {
    username = null;
    myPosts.clear();
    likedPosts.clear();
    otherUserPosts.clear();
    notifyListeners();
  }
}
