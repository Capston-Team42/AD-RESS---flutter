class Post {
  final String postId;
  final String username;
  final List<String>? photoUrls;
  final String content;
  final List<String> hashtags;
  int likeCount;
  int commentCount;
  final DateTime createdAt;
  bool get hasContent => content.trim().isNotEmpty;
  bool get hasHashtags => hashtags.isNotEmpty;

  Post({
    required this.postId,
    required this.username,
    required this.photoUrls,
    required this.content,
    required this.hashtags,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'],
      username: json['username'],
      photoUrls:
          json['photoUrls'] != null
              ? List<String>.from(json['photoUrls'])
              : null,
      content: json['content'],
      hashtags: List<String>.from(json['hashtags']),
      likeCount: json['likeCount'],
      commentCount: json['commentCount'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
