import 'package:flutter/material.dart';

class LoadingStyleCard extends StatelessWidget {
  const LoadingStyleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text("추천 스타일을 불러오는 중입니다...")),
          ],
        ),
      ),
    );
  }
}
