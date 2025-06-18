import 'package:chat_v0/models/comment_model.dart';
import 'package:chat_v0/providers/comment_provider.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  final void Function(int newCount)? onDelete;

  const CommentSection({super.key, required this.postId, this.onDelete});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetched) {
      _hasFetched = true;
      Future.microtask(() {
        final provider = context.read<CommentProvider>();
        provider.fetchComments(
          context: context,
          postId: widget.postId,
          reset: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentProvider = context.watch<CommentProvider>();
    final comments = commentProvider.getComments(widget.postId);
    final isLoading = commentProvider.isLoading(widget.postId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.comment, size: 20),
            const SizedBox(width: 4),
            const Text('댓글', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text('${comments.length}'),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: comments.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < comments.length) {
              final comment = comments[index];
              return buildCommentTile(context, comment);
            } else {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ],
    );
  }

  Widget buildCommentTile(BuildContext context, Comment comment) {
    final loginUsername = context.read<LoginStateManager>().username;
    bool itsMe = false;
    if (loginUsername == comment.username) {
      itsMe = true;
    }
    return ListTile(
      leading: const Icon(Icons.account_circle),
      title: Text(
        comment.username,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment.content),
          const SizedBox(height: 4),
          Text(
            comment.createdAt.toLocal().toString().split('.').first,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      trailing:
          itsMe
              ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: const Text('댓글 삭제'),
                          content: const Text('정말 이 댓글을 삭제하시겠습니까?'),
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

                  if (confirm == true) {
                    final provider = context.read<CommentProvider>();
                    final success = await provider.deleteComment(
                      context: context,
                      postId: widget.postId,
                      commentId: comment.commentId,
                    );
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('댓글 삭제 실패')));
                    } else {
                      final updatedCount =
                          context
                              .read<CommentProvider>()
                              .getComments(widget.postId)
                              .length;
                      widget.onDelete?.call(updatedCount);
                    }
                  }
                },
              )
              : null,
    );
  }
}
