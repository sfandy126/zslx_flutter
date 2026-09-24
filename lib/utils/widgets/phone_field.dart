import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

class MDPhoneField extends StatefulWidget {
  const MDPhoneField({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<MDPhoneField> createState() => _MDPhoneFieldState();
}

class _MDPhoneFieldState extends State<MDPhoneField> {
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
      keyboardType: TextInputType.phone,
      cursorColor: AppColors.theme,
      inputFormatters: [LengthLimitingTextInputFormatter(11)],
      decoration: InputDecoration(
        hintText: '请输入手机号',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 24, right: 12),
          child: Text(
            '+86',
            style: TextStyle(
              color: AppColors.theme,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
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
