import 'package:chat_v0/providers/wardobe_provider.dart';
import 'package:chat_v0/units/item_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_v0/models/item_model.dart';
import 'package:chat_v0/models/wardrobe_model.dart';
import 'package:chat_v0/providers/item_provider.dart';

class ItemUpdatePage extends StatefulWidget {
  final Item item;
  final Wardrobe wardrobe;

  const ItemUpdatePage({super.key, required this.item, required this.wardrobe});

  @override
  State<ItemUpdatePage> createState() => _ItemUpdatePageState();
}

class _ItemUpdatePageState extends State<ItemUpdatePage> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> dropdownValues = {};
  final Map<String, Set<String>> multiSelectValues = {};
  final Map<String, dynamic> _editedData = {};

  late final Map<String, dynamic> _originalData;
  late final String? _type;
  late final List<String> _fields;

  late String _selectedWardrobeId;
  List<Wardrobe> _wardrobes = [];
  bool _isLoadingWardrobes = true;

  @override
  void initState() {
    super.initState();
    _originalData = widget.item.getDataMap();
    _type = _originalData['type'];
    _fields = fieldsByType[_type] ?? [];

    _selectedWardrobeId = widget.wardrobe.id;

    final combinedDropdownFields = {
      ...fixedOptions,
      ...?typeSpecificOptions[_type],
    };

    for (final field in combinedDropdownFields.keys) {
      final value = _originalData[field];
      if (multiSelectFields.contains(field)) {
        if (value is List) {
          multiSelectValues[field] = Set<String>.from(value);
        }
      } else if (value is String) {
        dropdownValues[field] = value;
      }
    }

    for (final field in fixedTextFields) {
      final value = _originalData[field];
      if (value != null) {
        _controllers[field] = TextEditingController(text: value);
      }
    }
    for (final field in typeSpecificTextFields[_type] ?? []) {
      final value = _originalData[field];
      if (value != null) {
        _controllers[field] = TextEditingController(text: value);
      }
    }

    Future.microtask(() async {
      final wardrobeProvider = Provider.of<WardrobeProvider>(
        context,
        listen: false,
      );
      await wardrobeProvider.fetchWardrobes();
      if (!mounted) return;
      setState(() {
        _wardrobes = wardrobeProvider.wardrobes;
        _isLoadingWardrobes = false;
      });
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String getLabelByField(String field, String value) {
    final fieldMap = categorizedLabelMapping[field];
    final label = fieldMap != null ? fieldMap[value] : null;
    return label != null ? '$value ($label)' : value;
  }

  Widget _buildTextField(String fieldName) {
    final controller = _controllers[fieldName]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelFor(fieldName),
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) => _editedData[fieldName] = value,
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
          labelText: labelFor(fieldName),
          border: const OutlineInputBorder(),
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
            _editedData[fieldName] = value;
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
          Text(
            labelFor(fieldName),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
                        _editedData[fieldName] = selected.toList();
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
    final currentValue = _originalData[fieldName] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(labelFor(fieldName)),
          const SizedBox(width: 16),
          ChoiceChip(
            label: const Text('Yes'),
            selected:
                _editedData[fieldName] == true ||
                (currentValue && !_editedData.containsKey(fieldName)),
            onSelected: (_) => setState(() => _editedData[fieldName] = true),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('No'),
            selected:
                _editedData[fieldName] == false ||
                (!currentValue && !_editedData.containsKey(fieldName)),
            onSelected: (_) => setState(() => _editedData[fieldName] = false),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoField(String fieldName) {
    if (typeSpecificBooleanFields[_type]?.contains(fieldName) == true) {
      return _buildBooleanField(fieldName);
    }
    if (fixedTextFields.contains(fieldName) ||
        (typeSpecificTextFields[_type]?.contains(fieldName) ?? false)) {
      return _buildTextField(fieldName);
    }
    final options =
        typeSpecificOptions[_type]?[fieldName] ?? fixedOptions[fieldName];
    if (options != null) {
      if (multiSelectFields.contains(fieldName)) {
        return _buildMultiSelectChips(fieldName, options);
      } else {
        return _buildDropdownField(fieldName, options);
      }
    }
    return const SizedBox.shrink();
  }

  Future<void> _submitUpdate() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final itemId = widget.item.id;

    final Map<String, dynamic> updatedFields = {};
    for (final entry in _editedData.entries) {
      final key = entry.key;
      final newValue = entry.value;
      final originalValue = _originalData[key];

      if (newValue is List && originalValue is List) {
        if (!listEquals(newValue, originalValue)) {
          updatedFields[key] = newValue;
        }
      } else {
        if (newValue != originalValue) {
          updatedFields[key] = newValue;
        }
      }
    }

    if (_selectedWardrobeId != widget.wardrobe.id) {
      updatedFields['wardrobeId'] = _selectedWardrobeId;
    }

    if (updatedFields.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('변경된 내용이 없습니다.')));
      return;
    }

    final success = await itemProvider.updateItem(
      itemId: itemId,
      updatedFields: updatedFields,
    );

    if (success) {
      Navigator.of(context).pop(true);
    }
  }

  bool listEquals(List<dynamic>? a, List<dynamic>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('아이템 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(_originalData['imageUrl'], height: 200),
            const SizedBox(height: 16),
            ..._fields.map(_buildAutoField),

            const SizedBox(height: 16),
            if (_isLoadingWardrobes)
              const Center(child: CircularProgressIndicator())
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedWardrobeId,
                  decoration: const InputDecoration(
                    labelText: '옷장 선택',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      enabled: false,
                      child: SizedBox.shrink(),
                    ),
                    ..._wardrobes.map((w) {
                      return DropdownMenuItem(value: w.id, child: Text(w.name));
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedWardrobeId = value!;
                    });
                  },
                ),
              ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await _submitUpdate();
              },
              child: const Text('수정하기'),
            ),
          ],
        ),
      ),
    );
  }
}
