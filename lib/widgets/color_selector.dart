import 'package:flutter/material.dart';
import '../models/note.dart';
import '../utils/app_theme.dart';

class ColorSelector extends StatelessWidget {
  final NoteColor selectedColor;
  final Function(NoteColor) onColorSelected;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: NoteColor.values.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final color = NoteColor.values[index];
          final colorValue = AppTheme.getNoteColor(color, isDark);
          final isSelected = color == selectedColor;

          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: colorValue,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
