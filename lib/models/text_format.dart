import 'dart:convert';
import 'package:flutter/material.dart';

/// Represents a span of text with formatting
class FormattedTextSpan {
  final int start;
  final int end;
  final TextFormatStyle style;

  FormattedTextSpan({
    required this.start,
    required this.end,
    required this.style,
  });

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'style': style.toJson(),
      };

  factory FormattedTextSpan.fromJson(Map<String, dynamic> json) {
    return FormattedTextSpan(
      start: json['start'] as int,
      end: json['end'] as int,
      style: TextFormatStyle.fromJson(json['style'] as Map<String, dynamic>),
    );
  }
}

/// Text formatting styles
class TextFormatStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final String? fontFamily;
  final Color? color;
  final TextAlign? alignment;

  TextFormatStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.fontFamily,
    this.color,
    this.alignment,
  });

  TextFormatStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    String? fontFamily,
    Color? color,
    TextAlign? alignment,
  }) {
    return TextFormatStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      fontFamily: fontFamily ?? this.fontFamily,
      color: color ?? this.color,
      alignment: alignment ?? this.alignment,
    );
  }

  Map<String, dynamic> toJson() => {
        'bold': bold,
        'italic': italic,
        'underline': underline,
        'fontFamily': fontFamily,
        'color': color?.value,
        'alignment': alignment?.index,
      };

  factory TextFormatStyle.fromJson(Map<String, dynamic> json) {
    return TextFormatStyle(
      bold: json['bold'] as bool? ?? false,
      italic: json['italic'] as bool? ?? false,
      underline: json['underline'] as bool? ?? false,
      fontFamily: json['fontFamily'] as String?,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      alignment: json['alignment'] != null
          ? TextAlign.values[json['alignment'] as int]
          : null,
    );
  }
}

/// Document with formatted text
class FormattedTextDocument {
  final String plainText;
  final List<FormattedTextSpan> spans;
  final TextAlign globalAlignment;

  FormattedTextDocument({
    required this.plainText,
    this.spans = const [],
    this.globalAlignment = TextAlign.left,
  });

  String toJson() {
    return jsonEncode({
      'plainText': plainText,
      'spans': spans.map((s) => s.toJson()).toList(),
      'globalAlignment': globalAlignment.index,
    });
  }

  factory FormattedTextDocument.fromJson(String jsonStr) {
    try {
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      return FormattedTextDocument(
        plainText: json['plainText'] as String? ?? '',
        spans: (json['spans'] as List<dynamic>?)
                ?.map((s) =>
                    FormattedTextSpan.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        globalAlignment: json['globalAlignment'] != null
            ? TextAlign.values[json['globalAlignment'] as int]
            : TextAlign.left,
      );
    } catch (e) {
      // If parsing fails, return empty document
      return FormattedTextDocument(plainText: '');
    }
  }

  /// Create from plain text
  factory FormattedTextDocument.fromPlainText(String text) {
    return FormattedTextDocument(plainText: text);
  }
}
