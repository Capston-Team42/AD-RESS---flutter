import 'package:chat_v0/community/post_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:chat_v0/models/post_model.dart';

class UserPostListTitle extends StatelessWidget {
  final Post post;
  final void Function(Post updatedPost)? onUpdate;

  const UserPostListTitle({super.key, required this.post, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(post.content),
      subtitle: Column(
        children: [
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.favorite_border, size: 16, color: Colors.redAccent),
              const SizedBox(width: 4),
              Text('${post.likeCount}'),
              const SizedBox(width: 16),
              Icon(Icons.mode_comment_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${post.commentCount}'),
            ],
          ),
        ],
      ),

      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: post.postId),
          ),
        );

        if (result is Post && onUpdate != null) {
          onUpdate!(result);
        }
      },
    );
  }
}
