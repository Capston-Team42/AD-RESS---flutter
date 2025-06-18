import 'dart:convert';
import 'package:chat_v0/models/comment_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../providers/login_state_manager.dart';

class CommentProvider with ChangeNotifier {
  final LoginStateManager? loginStateManager;
  CommentProvider(this.loginStateManager);

  final Map<String, List<Comment>> commentsByPostId = {};
  final Map<String, int> _currentPageByPostId = {};
  final Map<String, bool> _hasMoreByPostId = {};
  List<Comment> getComments(String postId) =>
      List.unmodifiable(commentsByPostId[postId] ?? []);

  final Map<String, bool> _isLoadingByPostId = {};
  bool isLoading(String postId) => _isLoadingByPostId[postId] ?? false;

  final int pageSize = 10;

  // 댓글 목록 초기화 및 불러오기
  Future<void> fetchComments({
    required BuildContext context,
    required String postId,
    bool reset = false,
  }) async {
    final isLoading = _isLoadingByPostId[postId] ?? false;
    final hasMore = _hasMoreByPostId[postId] ?? true;
    final currentPage = reset ? 0 : (_currentPageByPostId[postId] ?? 0);

    if (isLoading || (!reset && !hasMore)) return;

    _isLoadingByPostId[postId] = true;
    notifyListeners();

    if (reset) {
      commentsByPostId[postId] = [];
      _currentPageByPostId[postId] = 0;
      _hasMoreByPostId[postId] = true;
    }

    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final uri = Uri.parse(
      'http://$backendIp:8081/api/comments/post/$postId?page=$currentPage&size=$pageSize',
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> commentJsonList = data['content']; // ✅ 여기 수정됨

      final newComments =
          commentJsonList.map((e) => Comment.fromJson(e)).toList();

      commentsByPostId.putIfAbsent(postId, () => []);
      commentsByPostId[postId]!.addAll(newComments);
      _currentPageByPostId[postId] = currentPage + 1;

      if (newComments.length < pageSize) {
        _hasMoreByPostId[postId] = false;
      }
    } else {}

    _isLoadingByPostId[postId] = false;
    notifyListeners();
  }

  // 댓글 등록
  Future<bool> addComment({
    required BuildContext context,
    required String postId,
    required String content,
  }) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8081/api/comments');

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'postId': postId, 'content': content}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final Comment newComment = Comment.fromJson(data['comment']);
      commentsByPostId.putIfAbsent(postId, () => []);
      commentsByPostId[postId]!.insert(0, newComment);
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  // 댓글 삭제
  Future<bool> deleteComment({
    required BuildContext context,
    required String postId,
    required String commentId,
  }) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final uri = Uri.parse('http://$backendIp:8081/api/comments/$commentId');

    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode == 200) {
      if (commentsByPostId.containsKey(postId)) {
        commentsByPostId[postId]!.removeWhere(
          (comment) => comment.commentId == commentId,
        );
      }
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  void reset(String postId) {
    commentsByPostId[postId]?.clear();
    _currentPageByPostId[postId] = 0;
    _hasMoreByPostId[postId] = true;
    _isLoadingByPostId[postId] = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  bool hasMore(String postId) => _hasMoreByPostId[postId] ?? true;
}
