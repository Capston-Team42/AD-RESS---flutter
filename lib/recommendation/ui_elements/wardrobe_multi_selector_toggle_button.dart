import 'package:chat_v0/models/round_chekbox.dart';
import 'package:chat_v0/providers/wardobe_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WardrobeSelectorToggleButton extends StatefulWidget {
  final List<String> selectedWardrobeIds;
  final bool useBasicWardrobe;
  final void Function(List<String>, bool) onSelectionChanged;

  const WardrobeSelectorToggleButton({
    super.key,
    required this.selectedWardrobeIds,
    required this.useBasicWardrobe,
    required this.onSelectionChanged,
  });

  @override
  State<WardrobeSelectorToggleButton> createState() =>
      _WardrobeSelectorToggleButtonState();
}

class _WardrobeSelectorToggleButtonState
    extends State<WardrobeSelectorToggleButton> {
  final GlobalKey _buttonKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  late Set<String> selectedIds;
  late bool useBasicWardrobe;

  @override
  void initState() {
    super.initState();
    selectedIds = widget.selectedWardrobeIds.toSet();
    useBasicWardrobe = widget.useBasicWardrobe;
  }

  bool _hasInitialized = false;

  void _showPopup() {
    final RenderBox buttonBox =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset position = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final wardrobes = context.read<WardrobeProvider>().wardrobes;

    if (!_hasInitialized) {
      selectedIds = wardrobes.map((w) => w.id).toSet();
      _hasInitialized = true;
    }
    const double popupHeight = 300;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: _hidePopup,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Positioned(
                left: position.dx,
                top: position.dy - popupHeight - 3,
                child: Material(
                  borderRadius: BorderRadius.circular(8),
                  child: StatefulBuilder(
                    builder: (context, setStateOverlay) {
                      return Container(
                        width: 190,
                        height: popupHeight,
                        constraints: const BoxConstraints(maxHeight: 300),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            Center(
                              child: Text(
                                "사용할 옷장 선택",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Divider(
                              thickness: 1,
                              color: Color.fromARGB(255, 228, 228, 228),
                            ),
                            // 쇼핑몰 의류 사용
                            RoundCheckboxTile(
                              isChecked: useBasicWardrobe,
                              label: "쇼핑몰 의류",
                              onChanged: () {
                                useBasicWardrobe = !useBasicWardrobe;
                                setStateOverlay(() {});
                                widget.onSelectionChanged(
                                  selectedIds.toList(),
                                  useBasicWardrobe,
                                );
                              },
                            ),
                            Divider(
                              thickness: 1,
                              color: Color.fromARGB(255, 228, 228, 228),
                            ),
                            // 옷장 모두 선택
                            RoundCheckboxTile(
                              isChecked: selectedIds.length == wardrobes.length,
                              label: "전체 옷장",
                              onChanged: () {
                                final allSelected =
                                    selectedIds.length == wardrobes.length;
                                if (allSelected) {
                                  selectedIds.clear();
                                } else {
                                  selectedIds =
                                      wardrobes.map((w) => w.id).toSet();
                                }
                                setStateOverlay(() {});
                                widget.onSelectionChanged(
                                  selectedIds.toList(),
                                  useBasicWardrobe,
                                );
                              },
                            ),
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  child: Divider(
                                    thickness: 1,
                                    color: Color.fromARGB(255, 228, 228, 228),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    "옷장 목록",
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(
                                    thickness: 1,
                                    color: Color.fromARGB(255, 228, 228, 228),
                                  ),
                                ),
                              ],
                            ),
                            // 개별 옷장들
                            ...wardrobes.map(
                              (w) => RoundCheckboxTile(
                                isChecked: selectedIds.contains(w.id),
                                label: w.name ?? "(이름 없음)",
                                onChanged: () {
                                  if (selectedIds.contains(w.id)) {
                                    selectedIds.remove(w.id);
                                  } else {
                                    selectedIds.add(w.id);
                                  }
                                  setStateOverlay(() {});
                                  widget.onSelectionChanged(
                                    selectedIds.toList(),
                                    useBasicWardrobe,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hidePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: _buttonKey,
      onPressed: () {
        if (_overlayEntry == null) {
          _showPopup();
        } else {
          _hidePopup();
        }
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        minimumSize: Size.zero,
        padding: const EdgeInsets.all(6),
        backgroundColor: Colors.grey,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      child: const Icon(Icons.dataset_linked_outlined, size: 18),
    );
  }
}
