import 'package:flutter/material.dart';

import '../app_colors.dart';

class MDTextField extends StatefulWidget {
  const MDTextField({
    required this.controller,
    required this.onChanged,
    this.hintText = '请输入内容',
    this.obscureText = false,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final bool obscureText;

  @override
  State<MDTextField> createState() => _MDTextFieldState();
}

class _MDTextFieldState extends State<MDTextField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      focusNode: _focusNode,
      onTapOutside: (_) => _focusNode.unfocus(),
      obscureText: widget.obscureText,
      cursorColor: AppColors.theme,
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: !_focusNode.hasFocus || widget.controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.clear, size: 15),
                color: AppColors.content,
              ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.fromLTRB(10, 14, 24, 14),
      ),
    );
  }

  void _handleControllerChanged() {
    setState(() {});
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
  }
}
