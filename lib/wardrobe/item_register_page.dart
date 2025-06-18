import 'dart:convert';
import 'dart:io';
import 'package:chat_v0/providers/wardobe_provider.dart';
import 'package:chat_v0/units/item_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_v0/providers/item_provider.dart';

class ItemRegisterPage extends StatefulWidget {
  final File image;

  const ItemRegisterPage({super.key, required this.image});

  @override
  State<ItemRegisterPage> createState() => _ItemRegisterPageState();
}

class _ItemRegisterPageState extends State<ItemRegisterPage> {
  bool _isAnalyzing = true;
  Map<String, dynamic>? _analyzedData;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> dropdownValues = {};
  final Map<String, Set<String>> multiSelectValues = {};
  String? selectedWardrobeId;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final result = await itemProvider.analyzeImage(widget.image);
    if (result != null && mounted) {
      setState(() {
        _analyzedData = result;
        _isAnalyzing = false;

        final type = result['type'];
        final combinedDropdownFields = {
          ...fixedOptions,
          ...?typeSpecificOptions[type],
        };

        for (final field in combinedDropdownFields.keys) {
          final value = result[field];
          if (multiSelectFields.contains(field)) {
            if (value is List) {
              multiSelectValues[field] = Set<String>.from(
                value.map((e) => e.toString()),
              );
            }
          } else if (value is String) {
            dropdownValues[field] = value;
          }
        }
        final boolFields = typeSpecificBooleanFields[type] ?? [];
        for (final field in boolFields) {
          final value = result[field];
          if (value is bool) {
            _analyzedData?[field] = value;
          }
        }
      });
    }
  }

  String getLabelByField(String field, String value) {
    final fieldMap = categorizedLabelMapping[field];
    final label = fieldMap != null ? fieldMap[value] : null;
    return label != null ? '$value ($label)' : value;
  }

  Widget _buildImageWithOverlay() {
    return Stack(
      children: [
        Image.file(
          widget.image,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        if (_isAnalyzing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('분석 중...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(String fieldName) {
    final controller = TextEditingController(
      text: _analyzedData?[fieldName] ?? '',
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: fieldName,
          border: OutlineInputBorder(),
        ),
        onChanged: (value) => _analyzedData?[fieldName] = value,
      ),
    );
  }

  Widget _buildDropdownField(String fieldName, List<String> options) {
    final currentValue = dropdownValues[fieldName];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: fieldName,
          border: OutlineInputBorder(),
        ),
        items:
            options
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(getLabelByField(fieldName, e)),
                  ),
                )
                .toList(),
        onChanged: (value) {
          setState(() {
            dropdownValues[fieldName] = value;
            _analyzedData?[fieldName] = value;
          });
        },
      ),
    );
  }

  Widget _buildMultiSelectChips(String fieldName, List<String> options) {
    final selected = multiSelectValues[fieldName] ?? <String>{};
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fieldName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                options.map((option) {
                  final isSelected = selected.contains(option);
                  return ChoiceChip(
                    label: Text(getLabelByField(fieldName, option)),
                    selected: isSelected,
                    onSelected: (selectedNow) {
                      setState(() {
                        if (selectedNow) {
                          selected.add(option);
                        } else {
                          selected.remove(option);
                        }
                        multiSelectValues[fieldName] = selected;
                        _analyzedData?[fieldName] = selected.toList();
                      });
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBooleanField(String fieldName) {
    final currentValue = _analyzedData?[fieldName] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(fieldName),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('Yes'),
            selected: currentValue,
            onSelected: (_) => setState(() => _analyzedData?[fieldName] = true),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('No'),
            selected: !currentValue,
            onSelected:
                (_) => setState(() => _analyzedData?[fieldName] = false),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoField(String fieldName) {
    final type = _analyzedData?['type'];

    if (typeSpecificBooleanFields[type]?.contains(fieldName) == true) {
      return _buildBooleanField(fieldName);
    }

    if (fixedTextFields.contains(fieldName) ||
        (typeSpecificTextFields[type]?.contains(fieldName) ?? false)) {
      return _buildTextField(fieldName);
    }
    final options =
        typeSpecificOptions[type]?[fieldName] ?? fixedOptions[fieldName];
    if (options != null) {
      if (multiSelectFields.contains(fieldName)) {
        return _buildMultiSelectChips(fieldName, options);
      } else {
        return _buildDropdownField(fieldName, options);
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _submit() async {
    if (_analyzedData == null || selectedWardrobeId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("등록 중..."),
              ],
            ),
          ),
    );

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final userId = itemProvider.loginStateManager?.userId;
    final itemData = {
      ..._analyzedData!,
      'userId': userId,
      'wardrobeId': selectedWardrobeId,
    };
    debugPrint('📤 등록 전 itemData: ${jsonEncode(itemData)}');

    final success = await itemProvider.registerItem(itemData);
    if (success && mounted) {
      Navigator.of(context).pop();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(content: Text("✅ 등록이 완료되었습니다!")),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ 등록 실패")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wardrobes = Provider.of<WardrobeProvider>(context).wardrobes;
    final type = _analyzedData?['type'];
    final fields = fieldsByType[type] ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('아이템 등록')),
      body:
          _isAnalyzing
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildImageWithOverlay()],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.file(widget.image, height: 200),
                    const SizedBox(height: 16),
                    ...fields.map(_buildAutoField),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedWardrobeId,
                      decoration: const InputDecoration(
                        labelText: '옷장 선택',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          wardrobes
                              .map(
                                (w) => DropdownMenuItem(
                                  value: w.id,
                                  child: Text(w.name ?? '이름 없음'),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) => setState(() => selectedWardrobeId = value),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('등록하기'),
                    ),
                  ],
                ),
              ),
    );
  }
}
