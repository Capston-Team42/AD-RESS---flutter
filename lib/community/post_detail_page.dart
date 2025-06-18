import 'package:chat_v0/community/comment_input_field.dart';
import 'package:chat_v0/community/comment_section.dart';
import 'package:chat_v0/community/image_viewer.dart';
import 'package:chat_v0/community/post_edit.dart';
import 'package:chat_v0/models/post_model.dart';
import 'package:chat_v0/providers/comment_provider.dart';
import 'package:chat_v0/providers/like_post_provider.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:chat_v0/providers/post_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;

class PostDetailScreen extends StatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LikePostProvider>().checkLikeStatus(widget.postId);
      context.read<LikePostProvider>().fetchLikeCount(widget.postId);
      _fetchPost();
    });
  }

  late CommentProvider _commentProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _commentProvider = context.read<CommentProvider>();
  }

  @override
  void dispose() {
    _commentProvider.reset(widget.postId);
    super.dispose();
  }

  Future<void> _fetchPost() async {
    final postProvider = context.read<PostDetailProvider>();
    await postProvider.fetchPostDetail(widget.postId);
    if (!mounted) return;

    final post = postProvider.post;
    if (post != null) {
      await context.read<CommentProvider>().fetchComments(
        context: context,
        postId: post.postId,
        reset: true,
      );
    }
  }

  Future<void> _deletePost() async {
    final authToken = context.read<LoginStateManager>().accessToken;
    if (authToken == null) return;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('게시글 삭제'),
            content: const Text('정말 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('삭제'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final uri = Uri.parse('http://$backendIp:8081/api/posts/${widget.postId}');
    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $authToken'},
    );

    if (response.statusCode == 200 && response.body == 'true') {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('삭제 완료')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제 실패: ${response.statusCode}')));
    }
  }

  Widget _buildPostDetail(Post post) {
    final formattedDate = intl.DateFormat(
      'yyyy. MM. dd',
    ).format(post.createdAt.toLocal());
    final loginUsername = context.read<LoginStateManager>().username;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                if (loginUsername == post.username) {
                  Navigator.pushNamed(context, '/myProfile');
                } else {
                  Navigator.pushNamed(
                    context,
                    '/userProfile',
                    arguments: post.username,
                  );
                }
              },
              child: Text(
                post.username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  // color: Colors.blue,
                ),
              ),
            ),
            Text(
              '작성일: $formattedDate',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (post.photoUrls != null && post.photoUrls!.isNotEmpty)
          SizedBox(
            height: 300,
            child: PageView.builder(
              itemCount: post.photoUrls!.length,
              itemBuilder: (context, index) {
                final url = post.photoUrls![index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => FullScreenImageViewer(
                              images: post.photoUrls!,
                              initialIndex: index,
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder:
                          (context, error, stackTrace) =>
                              const Icon(Icons.error),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          children:
              post.hashtags
                  .map(
                    (tag) => GestureDetector(
                      onTap: () => debugPrint('해시태그 클릭됨: $tag'),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 16),
        Text(post.content),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostDetailProvider>();
    final loginUsername = context.read<LoginStateManager>().username;
    final post = provider.post;

    if (post == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final likePostProvider = context.watch<LikePostProvider>();
    final isLiked = likePostProvider.isLiked(post.postId);
    final likeCount = likePostProvider.getLikeCount(post.postId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, {
              'commentCount': post.commentCount,
              'likeCount': likeCount,
              'liked': context.read<LikePostProvider>().isLiked(post.postId),
            });
          },
        ),

        actions: [
          if (!provider.isLoading) ...[
            if (loginUsername == post.username)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostEditScreen(post: post),
                    ),
                  );
                  if (result == true) _fetchPost();
                },
              ),
            if (loginUsername == post.username)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deletePost,
              ),
          ],
        ],
      ),
      body:
          provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildPostDetail(post),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                              onPressed:
                                  () => context
                                      .read<LikePostProvider>()
                                      .toggleLike(post.postId),
                            ),
                            Text('$likeCount'),
                          ],
                        ),
                        const Divider(height: 32),
                        CommentSection(
                          postId: post.postId,
                          onDelete: (newCount) {
                            setState(() {
                              post.commentCount = newCount;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  CommentInputField(
                    postId: post.postId,
                    onCommentAdded: (newCount) {
                      setState(() {
                        post.commentCount = newCount;
                      });
                    },
                  ),
                ],
              ),
    );
  }
}
