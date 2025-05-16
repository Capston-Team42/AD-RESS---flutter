import 'package:flutter/material.dart';

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
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 16,
            ), // 높이 조절
            hintText: '어떤 스타일을 원해요?',
            hintStyle: TextStyle(
              color: Colors.grey, // 연한 회색
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // 끝을 둥글게
              borderSide: BorderSide(width: 1, color: Colors.grey), // 테두리 얇게
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(width: 0.5, color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                width: 1,
                color: Colors.grey,
              ), // 포커스 시 테두리 강조
            ),
            isDense: true,
          ),
        ),
        Positioned(
          right: 6, // ← 여기 숫자를 줄이면 테두리에 더 가까워짐
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
