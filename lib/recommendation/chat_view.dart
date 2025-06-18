import 'package:chat_v0/models/message_model.dart';
import 'package:flutter/material.dart';

class ChatMessageListView extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController? scrollController;
  final double topPadding;

  const ChatMessageListView({
    super.key,
    required this.messages,
    this.scrollController,
    this.topPadding = 200,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(top: topPadding),
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

        if (msg.type == ChatMessageType.system) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                msg.text ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        return Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  msg.isUser
                      ? Color.fromARGB(255, 221, 230, 222)
                      : const Color.fromARGB(255, 224, 239, 226),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(msg.text ?? ""),
          ),
        );
      },
    );
  }
}
