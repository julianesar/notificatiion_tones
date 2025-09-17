import 'package:flutter/material.dart';
import '../../core/theme/icon_colors.dart';

class PlayStopButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback? onPressed;
  final double size;
  final double? iconSize;
  final double borderRadius;

  const PlayStopButton({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    this.onPressed,
    this.size = 40,
    this.iconSize,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.iconPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? SizedBox(
                  key: const ValueKey('loading'),
                  width: (iconSize ?? size * 0.5),
                  height: (iconSize ?? size * 0.5),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.iconPrimary,
                  ),
                )
              : Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  key: ValueKey(isPlaying ? 'stop' : 'play'),
                  color: context.iconPrimary,
                  size: iconSize ?? size * 0.5,
                ),
        ),
      ),
    );
  }
}