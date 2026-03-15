import 'dart:convert';
import 'sheet_template.dart';

enum TemplateType { text, sheet }

/// Represents a note template that users can use to create notes quickly
class NoteTemplate {
  final String id;
  final String title;
  final String content;
  final String category;
  final bool isBuiltIn; // true for app built-in templates, false for user-created
  final DateTime createdAt;
  final TemplateType templateType;
  final SheetData? sheetData; // Only for sheet templates

  NoteTemplate({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'Personal',
    this.isBuiltIn = false,
    DateTime? createdAt,
    this.templateType = TemplateType.text,
    this.sheetData,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Copy with modifications
  NoteTemplate copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    bool? isBuiltIn,
    DateTime? createdAt,
    TemplateType? templateType,
    SheetData? sheetData,
  }) {
    return NoteTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      templateType: templateType ?? this.templateType,
      sheetData: sheetData ?? this.sheetData,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'templateType': templateType.toString().split('.').last,
      'sheetData': sheetData?.toJson(),
    };
  }

  /// Create from JSON
  factory NoteTemplate.fromJson(Map<String, dynamic> json) {
    return NoteTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String? ?? 'Personal',
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      templateType: json['templateType'] == 'sheet' 
          ? TemplateType.sheet 
          : TemplateType.text,
      sheetData: json['sheetData'] != null 
          ? SheetData.fromJson(json['sheetData'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON string
  factory NoteTemplate.fromJsonString(String jsonString) {
    return NoteTemplate.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
