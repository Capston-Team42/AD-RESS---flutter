class Comment {
  final String commentId;
  final String postId;
  final String username;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.commentId,
    required this.postId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'],
      postId: json['postId'],
      username: json['username'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
