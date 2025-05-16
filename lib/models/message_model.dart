import 'package:flutter/material.dart';

class ChatMessage {
  final String? text;
  final bool isUser;
  final Widget? customWidget;

  ChatMessage({this.text, required this.isUser, this.customWidget});
}
