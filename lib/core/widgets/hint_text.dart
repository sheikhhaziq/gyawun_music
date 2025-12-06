import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

class HintText extends StatefulWidget {
  const HintText({super.key, required this.text, this.color, this.backgroundColor});

  final String text;
  final Color? color;
  final Color? backgroundColor;

  @override
  State<HintText> createState() => _HintTextState();
}

class _HintTextState extends State<HintText> with SingleTickerProviderStateMixin {
  bool isVisible = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: isVisible
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: widget.backgroundColor,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.text,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: widget.color),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isVisible = false;
                        });
                      },
                      icon: const Icon(FluentIcons.dismiss_24_filled),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
