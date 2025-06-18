import 'package:chat_v0/providers/input_focus_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final FocusNode focusNode;

  const UserInputArea({
    super.key,
    required this.controller,
    required this.onSubmit,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final focusNode = context.watch<InputFocusProvider>().inputFocusNode;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
            hintText: '어떤 스타일을 원해요?',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(width: 1, color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(width: 0.5, color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(width: 1, color: Colors.grey),
            ),
            isDense: true,
          ),
        ),
        Positioned(
          right: 6,
          child: SizedBox(
            height: 24,
            width: 24,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: CircleBorder(),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Icon(Icons.send, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}
