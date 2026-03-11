import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class TypingMarkdown extends StatefulWidget {
  final String text;
  final Duration speed;
  final TextTheme textTheme;
  final VoidCallback? onCompleted;
  const TypingMarkdown({
    super.key,
    required this.text,
    required this.textTheme,
    this.onCompleted,
    this.speed = const Duration(milliseconds: 5),
  });

  @override
  State<TypingMarkdown> createState() => _TypingMarkdownState();
}

class _TypingMarkdownState extends State<TypingMarkdown> {
  String _displayText = '';
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: _displayText,
      styleSheet: MarkdownStyleSheet(
        p: widget.textTheme.displayMedium,
        strong: widget.textTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}



