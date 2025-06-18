import 'package:flutter/material.dart';

class CoordinationDropdown extends StatefulWidget {
  final List<String> options;
  final String selected;
  final Function(String) onChanged;

  const CoordinationDropdown({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<CoordinationDropdown> createState() => _CoordinationDropdownState();
}

class _CoordinationDropdownState extends State<CoordinationDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isDropdownOpen = false;

  void _toggleDropdown() {
    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isDropdownOpen = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isDropdownOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    const double spacingFromButton = 19;

    return OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _removeOverlay,
                  behavior: HitTestBehavior.translucent,
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: offset.dx,
                top:
                    offset.dy -
                    (widget.options.length * 44.0 - spacingFromButton),
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  offset: Offset(
                    0,
                    -((widget.options.length * 44.0) - spacingFromButton),
                  ),
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 8.0,
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children:
                            widget.options.map((type) {
                              final isSelected = widget.selected == type;
                              return ChoiceChip(
                                label: Text(
                                  type,
                                  style: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.black
                                            : Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (_) {
                                  widget.onChanged(type);
                                  _removeOverlay();
                                },
                                selectedColor: const Color.fromARGB(
                                  255,
                                  122,
                                  255,
                                  89,
                                ),
                                backgroundColor: Colors.grey[400],
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -2,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: Container(
          width: 92,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[350],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              widget.selected,
              style: const TextStyle(color: Colors.black, fontSize: 12.5),
            ),
          ),
        ),
      ),
    );
  }
}
