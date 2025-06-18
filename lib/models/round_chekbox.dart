import 'package:flutter/material.dart';

class RoundCheckboxTile extends StatelessWidget {
  final bool isChecked;
  final String label;
  final VoidCallback onChanged;
  final EdgeInsetsGeometry padding;

  const RoundCheckboxTile({
    super.key,
    required this.isChecked,
    required this.label,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: padding,
      leading: InkWell(
        onTap: onChanged,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isChecked
                      ? const Color.fromARGB(255, 122, 255, 89)
                      : Colors.grey,
              width: 2,
            ),
            color:
                isChecked
                    ? const Color.fromARGB(255, 122, 255, 89)
                    : Colors.transparent,
          ),
          child:
              isChecked
                  ? const Center(
                    child: Icon(
                      Icons.check,
                      size: 14,
                      color: Color.fromARGB(255, 13, 52, 3),
                    ),
                  )
                  : null,
        ),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onChanged,
    );
  }
}
