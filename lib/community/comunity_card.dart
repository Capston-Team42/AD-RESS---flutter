import 'package:flutter/material.dart';

class CommunityPostCard extends StatefulWidget {
  final String imageUrl;
  final String userId;
  final String userProfile;
  final String title;
  final String hashtags;
  final String description;

  const CommunityPostCard({
    super.key,
    required this.imageUrl,
    required this.userId,
    required this.userProfile,
    required this.title,
    required this.hashtags,
    required this.description,
  });

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxImageHeight = screenWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이미지 영역
        Stack(
          children: [
            Image.network(
              widget.imageUrl,
              width: double.infinity,
              height: maxImageHeight,
              fit: BoxFit.cover,
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(widget.userProfile),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.userId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Row(
                children: const [
                  Icon(Icons.favorite_border, color: Colors.white),
                  SizedBox(width: 12),
                  Icon(Icons.chat_bubble_outline, color: Colors.white),
                ],
              ),
            ),
          ],
        ),

        // 글 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.hashtags,
                style: const TextStyle(color: Colors.blueAccent),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final textSpan = TextSpan(
                    text: widget.description,
                    style: const TextStyle(color: Colors.black87),
                  );
                  final tp = TextPainter(
                    text: textSpan,
                    textDirection: TextDirection.ltr,
                    maxLines: _isExpanded ? null : 3,
                    ellipsis: '...',
                  );
                  tp.layout(maxWidth: constraints.maxWidth);

                  final isOverflowing = tp.didExceedMaxLines;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.description,
                        maxLines: _isExpanded ? null : 3,
                        overflow:
                            _isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                      ),
                      if (isOverflowing)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _isExpanded ? "접기" : "더보기",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 0.5), // 구분선
      ],
    );
  }
}
