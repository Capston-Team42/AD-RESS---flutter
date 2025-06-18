import 'package:flutter/material.dart';

enum ChatMessageType { user, ai, system }

class ChatMessage {
  final String? text;
  final ChatMessageType type;
  final Widget? customWidget;

  ChatMessage({this.text, required this.type, this.customWidget});

  bool get isUser => type == ChatMessageType.user;

  @override
  String toString() {
    return 'ChatMessage(type: $type, text: $text)';
  }
}
