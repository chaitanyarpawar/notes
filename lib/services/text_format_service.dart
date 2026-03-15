import 'package:flutter/material.dart';
import '../models/text_format.dart';

/// Service for managing text formatting
class TextFormatService {
  /// Apply formatting to a text selection
  static FormattedTextDocument applyFormatting({
    required FormattedTextDocument document,
    required TextSelection selection,
    required TextFormatStyle style,
  }) {
    if (selection.start == selection.end) {
      return document; // No selection
    }

    // Remove overlapping spans for the selected range
    final cleanedSpans = _removeOverlappingSpans(
      document.spans,
      selection.start,
      selection.end,
    );

    // Add new span
    final newSpan = FormattedTextSpan(
      start: selection.start,
      end: selection.end,
      style: style,
    );

    return FormattedTextDocument(
      plainText: document.plainText,
      spans: [...cleanedSpans, newSpan],
      globalAlignment: document.globalAlignment,
    );
  }

  /// Update text content while preserving formatting where possible
  static FormattedTextDocument updateText({
    required FormattedTextDocument document,
    required String newText,
  }) {
    if (newText == document.plainText) {
      return document;
    }

    // If text is shorter, trim spans
    if (newText.length < document.plainText.length) {
      final validSpans =
          document.spans.where((span) => span.end <= newText.length).toList();
      return FormattedTextDocument(
        plainText: newText,
        spans: validSpans,
        globalAlignment: document.globalAlignment,
      );
    }

    // Text is longer or same, keep all spans
    return FormattedTextDocument(
      plainText: newText,
      spans: document.spans,
      globalAlignment: document.globalAlignment,
    );
  }

  /// Get the formatting at a specific position
  static TextFormatStyle? getFormatAtPosition({
    required FormattedTextDocument document,
    required int position,
  }) {
    for (var span in document.spans) {
      if (position >= span.start && position < span.end) {
        return span.style;
      }
    }
    return null;
  }

  /// Get the formatting for a selection (returns most common style)
  static TextFormatStyle getFormatForSelection({
    required FormattedTextDocument document,
    required TextSelection selection,
  }) {
    if (selection.start == selection.end) {
      return getFormatAtPosition(
            document: document,
            position: selection.start,
          ) ??
          TextFormatStyle();
    }

    // Find spans that overlap with selection
    final overlappingSpans = document.spans.where((span) {
      return span.start < selection.end && span.end > selection.start;
    }).toList();

    if (overlappingSpans.isEmpty) {
      return TextFormatStyle();
    }

    // Merge styles (if multiple, take the most common attributes)
    bool isBold = false;
    bool isItalic = false;
    bool isUnderline = false;
    String? fontFamily;
    Color? color;

    for (var span in overlappingSpans) {
      if (span.style.bold) isBold = true;
      if (span.style.italic) isItalic = true;
      if (span.style.underline) isUnderline = true;
      fontFamily ??= span.style.fontFamily;
      color ??= span.style.color;
    }

    return TextFormatStyle(
      bold: isBold,
      italic: isItalic,
      underline: isUnderline,
      fontFamily: fontFamily,
      color: color,
    );
  }

  /// Build TextSpan tree from formatted document
  static TextSpan buildTextSpan({
    required FormattedTextDocument document,
    required TextStyle baseStyle,
  }) {
    if (document.spans.isEmpty) {
      return TextSpan(
        text: document.plainText,
        style: baseStyle,
      );
    }

    // Sort spans by start position
    final sortedSpans = List<FormattedTextSpan>.from(document.spans)
      ..sort((a, b) => a.start.compareTo(b.start));

    List<TextSpan> children = [];
    int currentPos = 0;

    for (var span in sortedSpans) {
      // Add unformatted text before this span
      if (currentPos < span.start) {
        children.add(TextSpan(
          text: document.plainText.substring(currentPos, span.start),
          style: baseStyle,
        ));
      }

      // Add formatted span
      final formattedStyle = baseStyle.copyWith(
        fontWeight: span.style.bold ? FontWeight.bold : null,
        fontStyle: span.style.italic ? FontStyle.italic : null,
        decoration: span.style.underline ? TextDecoration.underline : null,
        fontFamily: span.style.fontFamily,
        color: span.style.color,
      );

      children.add(TextSpan(
        text: document.plainText.substring(span.start, span.end),
        style: formattedStyle,
      ));

      currentPos = span.end;
    }

    // Add remaining unformatted text
    if (currentPos < document.plainText.length) {
      children.add(TextSpan(
        text: document.plainText.substring(currentPos),
        style: baseStyle,
      ));
    }

    return TextSpan(children: children, style: baseStyle);
  }

  /// Remove overlapping spans in a range
  static List<FormattedTextSpan> _removeOverlappingSpans(
    List<FormattedTextSpan> spans,
    int start,
    int end,
  ) {
    return spans.where((span) {
      // Keep spans that don't overlap with the new range
      return span.end <= start || span.start >= end;
    }).toList();
  }

  /// Set global alignment
  static FormattedTextDocument setAlignment({
    required FormattedTextDocument document,
    required TextAlign alignment,
  }) {
    return FormattedTextDocument(
      plainText: document.plainText,
      spans: document.spans,
      globalAlignment: alignment,
    );
  }

  /// Clear all formatting
  static FormattedTextDocument clearFormatting({
    required FormattedTextDocument document,
  }) {
    return FormattedTextDocument(
      plainText: document.plainText,
      spans: [],
      globalAlignment: TextAlign.left,
    );
  }
}
