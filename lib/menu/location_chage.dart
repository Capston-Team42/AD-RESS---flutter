import 'package:flutter/material.dart';

class LocationSettingDialog extends StatefulWidget {
  final Function(String location) onLocationSelected;

  const LocationSettingDialog({super.key, required this.onLocationSelected});

  @override
  State<LocationSettingDialog> createState() => _LocationSettingDialogState();
}

class _LocationSettingDialogState extends State<LocationSettingDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("위치 설정"),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: "예: 서울, 강남역"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
        ElevatedButton(
          onPressed: () {
            final input = _controller.text.trim();
            if (input.isNotEmpty) {
              widget.onLocationSelected(input); // 부모에게 전달
              Navigator.pop(context); // 다이얼로그 닫기
            }
          },
          child: Text("적용"),
        ),
      ],
    );
  }
}
