import 'package:flutter/material.dart';

class InputFocusProvider with ChangeNotifier {
  final FocusNode inputFocusNode = FocusNode();

  void unfocus() {
    inputFocusNode.unfocus();
  }

  void disableFocus() {
    inputFocusNode.canRequestFocus = false;
  }

  void enableFocus() {
    inputFocusNode.canRequestFocus = true;
  }

  @override
  void dispose() {
    inputFocusNode.dispose();
    super.dispose();
  }
}
