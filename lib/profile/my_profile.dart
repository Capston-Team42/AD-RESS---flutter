import 'dart:convert';
import 'package:chat_v0/models/post_model.dart';
import 'package:chat_v0/profile/my_post_list_title.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  List<Post> myPosts = [];
  List<Post> likedPosts = [];
  String username = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
  }

  Future<void> _loadMyProfile() async {
    final loginState = context.read<LoginStateManager>();
    final token = loginState.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';

    final uri = Uri.parse('http://$backendIp:8081/api/profile/me');
    final res = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      setState(() {
        username = data['username'];
        myPosts =
            (data['myPosts'] as List).map((e) => Post.fromJson(e)).toList();
        likedPosts =
            (data['likedPosts'] as List).map((e) => Post.fromJson(e)).toList();
        isLoading = false;
      });
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('$username님의 프로필')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: Color.fromARGB(255, 10, 59, 55),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color.fromARGB(255, 10, 59, 55),
              tabs: [Tab(text: '내가 쓴 글'), Tab(text: '좋아요한 글')],
            ),
            Expanded(
              child: TabBarView(
                children: [_buildPostList(myPosts), _buildPostList(likedPosts)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostList(List<Post> posts) {
    if (posts.isEmpty) return const Center(child: Text('게시글이 없습니다.'));
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return MyPostListTitle(
          post: post,
          onUpdate: (updatedPost) {
            setState(() {
              posts[index] = updatedPost;
            });
          },
        );
      },
    );
  }
}
