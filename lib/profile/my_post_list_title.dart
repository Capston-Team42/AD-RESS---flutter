import 'package:chat_v0/community/post_detail_page.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:chat_v0/models/post_model.dart';
import 'package:provider/provider.dart';

class MyPostListTitle extends StatefulWidget {
  final Post post;
  final void Function(Post updatedPost)? onUpdate;

  const MyPostListTitle({super.key, required this.post, this.onUpdate});

  @override
  State<MyPostListTitle> createState() => _MyPostListTitleState();
}

class _MyPostListTitleState extends State<MyPostListTitle> {
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  void _updatePost(Post newPost) {
    setState(() {
      _post = newPost;
    });
    widget.onUpdate?.call(newPost);
  }

  @override
  Widget build(BuildContext context) {
    final loginUsername = context.read<LoginStateManager>().username;
    return ListTile(
      title: GestureDetector(
        onTap: () {
          if (loginUsername == _post.username) {
            Navigator.pushNamed(context, '/myProfile');
          } else {
            Navigator.pushNamed(
              context,
              '/userProfile',
              arguments: _post.username,
            );
          }
        },
        child: Row(
          children: [
            const Icon(Icons.person, size: 18),
            const SizedBox(width: 6),
            Text(
              _post.username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      subtitle: Text(_post.content),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_border,
                size: 16,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 4),
              Text('${_post.likeCount}'),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mode_comment_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text('${_post.commentCount}'),
            ],
          ),
        ],
      ),
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: _post.postId),
          ),
        );

        if (result is Post) {
          _updatePost(result);
        }
      },
    );
  }
}
