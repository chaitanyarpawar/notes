import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String) onChanged;
  final VoidCallback onClear;

  const CustomSearchBar({
    super.key,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onClear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final outlineColor = isDark ? Colors.white12 : Colors.black12;
    const focusColor = Color(0xFFFF9500);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final iconColor = isDark ? Colors.white70 : Colors.grey.shade600;
    return SizedBox(
      height: 50,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: TextStyle(color: textColor),
        cursorColor: isDark ? Colors.white70 : Colors.black54,
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? const Color(0xFF1F1F1F) : surface,
          hintText: 'Search notes...',
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: Icon(Icons.search, color: iconColor),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(Icons.clear, color: iconColor),
                  onPressed: _clearSearch,
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: outlineColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: outlineColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: focusColor, width: 1.5),
          ),
        ),
      ),
    );
  }
}
