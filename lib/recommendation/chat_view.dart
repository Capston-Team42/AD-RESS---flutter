import 'package:chat_v0/models/message_model.dart';
import 'package:flutter/material.dart';

class ChatMessageListView extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController? scrollController; // 📌 추가
  final double topPadding; // 추가

  const ChatMessageListView({
    super.key,
    required this.messages,
    this.scrollController,
    this.topPadding = 200, // 기본값: 헤더 높이
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController, // 📌 연결
      padding: EdgeInsets.only(top: topPadding), // 👈 여기가 핵심
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];

        if (msg.customWidget != null) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              child: msg.customWidget!,
            ),
          );
        }

        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: msg.isUser ? Colors.blue[100] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(msg.text ?? ""),
          ),
        );
      },
    );
  }
}
