
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyIcon extends StatefulWidget {
  final String text;
  const CopyIcon({super.key, required this.text});

  @override
  State<CopyIcon> createState() => CopyIconState();
}

class CopyIconState extends State<CopyIcon> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: widget.text));
        setState(() => _copied = true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _copied = false);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _copied ? Icons.check_rounded : Icons.copy_outlined,
          key: ValueKey(_copied),
          size: 18,
          color: theme.hintColor,
        ),
      ),
    );
  }
}

class LikeButton extends StatefulWidget {
  const LikeButton({super.key});
  @override
  State<LikeButton> createState() => LikeButtonState();
}

class LikeButtonState extends State<LikeButton> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _liked = !_liked),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
          key: ValueKey(_liked),
          size: 18,
          color: theme.hintColor,
        ),
      ),
    );
  }
}

class DisLikeButton extends StatefulWidget {
  const DisLikeButton({super.key});
  @override
  State<DisLikeButton> createState() => DisLikeButtonState();
}

class DisLikeButtonState extends State<DisLikeButton> {
  bool _disliked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => setState(() => _disliked = !_disliked),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _disliked ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
          key: ValueKey(_disliked),
          size: 18,
          color: theme.hintColor,
        ),
      ),
    );
  }
}