import 'dart:convert';
import 'package:chat_v0/profile/user_post_list_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:chat_v0/models/post_model.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Post> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPosts();
  }

  Future<void> _loadUserPosts() async {
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final token = context.read<LoginStateManager>().accessToken;
    final uri = Uri.parse(
      'http://$backendIp:8081/api/profile/${widget.username}',
    );
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        posts = (data['posts'] as List).map((e) => Post.fromJson(e)).toList();
        isLoading = false;
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.username}님의 글')),
      body:
          posts.isEmpty
              ? const Center(child: Text('게시글이 없습니다.'))
              : ListView.separated(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return UserPostListTitle(
                    post: post,
                    onUpdate: (updatedPost) {
                      setState(() {
                        posts[index] = updatedPost;
                      });
                    },
                  );
                },
                separatorBuilder:
                    (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color.fromARGB(255, 238, 238, 238),
                      indent: 16,
                      endIndent: 16,
                    ),
              ),
    );
  }
}
