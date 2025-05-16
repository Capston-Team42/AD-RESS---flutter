import 'package:chat_v0/models/item_model.dart';
import 'package:chat_v0/models/wardrobe_model.dart';
import 'package:chat_v0/providers/item_provider.dart';
import 'package:chat_v0/units/item_field_utils.dart';
import 'package:chat_v0/wardrobe/item_update_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemDetailPage extends StatefulWidget {
  final Item item;
  final Wardrobe wardrobe; // 수정 페이지로 전달용

  const ItemDetailPage({super.key, required this.item, required this.wardrobe});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.item.getDataMap();
    final type = data['type'];
    final fields = fieldsByType[type] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('아이템 상세'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ItemUpdatePage(
                          item: widget.item,
                          wardrobe: widget.wardrobe,
                        ),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.of(context).pop(true); // 변경 반영 위해 뒤로 감
                }
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text("정말 삭제하시겠습니까?"),
                        content: const Text("아이템이 삭제되며 복구할 수 없습니다."),
                        actions: [
                          TextButton(
                            child: const Text("취소"),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                          TextButton(
                            child: const Text("삭제"),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                );

                if (confirmed == true) {
                  final provider = Provider.of<ItemProvider>(
                    context,
                    listen: false,
                  );
                  final success = await provider.deleteItem(widget.item.id);

                  if (success && mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const AlertDialog(content: Text("✅ 삭제되었습니다.")),
                    );
                    await Future.delayed(const Duration(seconds: 1));
                    if (mounted) Navigator.of(context).pop(true); // 아이템 제거 후 복귀
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('❌ 삭제 실패')));
                    }
                  }
                }
              }
            },

            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('수정')),
                  const PopupMenuItem(value: 'delete', child: Text('삭제')),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(data['imageUrl'], height: 200),
            const SizedBox(height: 16),
            ...fields.map((field) => _buildDisplayField(field, data, type)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplayField(
    String key,
    Map<String, dynamic> data,
    String? type,
  ) {
    final value = data[key];
    if (value == null || value.toString().isEmpty)
      return const SizedBox.shrink();

    final label = labelFor(key);
    if (key == 'imageUrl') return const SizedBox.shrink();
    // ✅ seasons: 다중 선택 Chip
    if (key == 'season' && value is List) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children:
                  value
                      .map<Widget>((v) => Chip(label: Text(v.toString())))
                      .toList(),
            ),
          ],
        ),
      );
    }

    // ✅ 줄글 필드
    if (fixedTextFields.contains(key) ||
        (typeSpecificTextFields[type]?.contains(key) ?? false)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value.toString()),
          ],
        ),
      );
    }

    // ✅ Boolean 필드
    if (typeSpecificBooleanFields[type]?.contains(key) ?? false) {
      final display = (value == true) ? 'yes' : 'no';
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(display),
          ],
        ),
      );
    }

    // ✅ 기본 단일 텍스트 필드
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value.toString()),
        ],
      ),
    );
  }
}
