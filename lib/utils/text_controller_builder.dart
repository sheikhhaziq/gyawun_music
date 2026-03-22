import 'package:flutter/material.dart';

class TextControllerBuilder extends StatefulWidget {
  final String? initialText;
  final Widget Function(BuildContext context, TextEditingController controller)
      builder;

  const TextControllerBuilder({
    super.key,
    this.initialText,
    required this.builder,
  });

  @override
  State<TextControllerBuilder> createState() => _TextControllerBuilderState();
}

class _TextControllerBuilderState extends State<TextControllerBuilder> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller);
  }
}
