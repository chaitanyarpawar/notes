import 'package:flutter/material.dart';

/// Keyboard accessory toolbar that sits above the keyboard
/// Provides quick access to formatting and input options
class KeyboardToolbar extends StatelessWidget {
  final VoidCallback? onTextFormat;
  final VoidCallback? onEmoji;

  const KeyboardToolbar({
    super.key,
    this.onTextFormat,
    this.onEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[100],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),

          // Text Format (Aa)
          _buildToolbarButton(
            context: context,
            label: 'Aa',
            onTap: onTextFormat,
            isText: true,
          ),

          // Emoji
          _buildToolbarButton(
            context: context,
            icon: Icons.emoji_emotions_outlined,
            onTap: onEmoji,
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required BuildContext context,
    IconData? icon,
    String? label,
    VoidCallback? onTap,
    bool isText = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: isText
                ? Text(
                    label!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  )
                : Icon(
                    icon,
                    size: 24,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
          ),
        ),
      ),
    );
  }
}
