import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/comment_provider.dart';

class CommentInputField extends StatefulWidget {
  final String postId;
  final Function(int newCommentCount)? onCommentAdded;

  const CommentInputField({
    super.key,
    required this.postId,
    this.onCommentAdded,
  });

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;

  Future<void> _submitComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final commentProvider = context.read<CommentProvider>();
    final success = await commentProvider.addComment(
      context: context,
      postId: widget.postId,
      content: content,
    );

    if (success) {
      _controller.clear();
      _focusNode.unfocus();
      if (widget.onCommentAdded != null) {
        widget.onCommentAdded?.call(
          commentProvider.getComments(widget.postId).length,
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // 빈 공간 터치도 감지
      onTap: () {
        FocusScope.of(context).unfocus(); // 포커스 해제 (키보드 내려감)
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 16,
                    ),
                    hintText: '댓글을 입력하세요.',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(width: 1, color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(width: 0.5, color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide(
                        width: 1,
                        color: Colors.grey,
                      ), // 포커스 시 테두리 강조
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 13, 52, 3), // 배경색
                  foregroundColor: Colors.white, // 텍스트/아이콘 색
                  shape: RoundedRectangleBorder(
                    // 모서리 둥글게
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text('등록'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
