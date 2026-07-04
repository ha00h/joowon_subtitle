import 'package:flutter/material.dart';

/// 찬양 검색 입력창 (전역 조작 단축키 범위 밖에서 사용)
class OperatorSearchField extends StatefulWidget {
  const OperatorSearchField({
    required this.onChanged,
    this.initialValue = '',
    super.key,
  });

  final ValueChanged<String> onChanged;
  final String initialValue;

  @override
  State<OperatorSearchField> createState() => _OperatorSearchFieldState();
}

class _OperatorSearchFieldState extends State<OperatorSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant OperatorSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.value = _controller.value.copyWith(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        hintText: '찬양 검색 (번호·제목·띄어쓰기)',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      enableSuggestions: false,
      onChanged: widget.onChanged,
    );
  }
}
