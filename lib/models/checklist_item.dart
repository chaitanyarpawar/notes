class ChecklistItem {
  final int? id;
  final String noteId;
  final String text;
  final bool isChecked;
  final String? textDelta; // Rich text content as Quill Delta JSON

  ChecklistItem({
    this.id,
    required this.noteId,
    required this.text,
    required this.isChecked,
    this.textDelta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'noteId': noteId,
      'text': text,
      'isChecked': isChecked ? 1 : 0,
      'textDelta': textDelta,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id']?.toInt(),
      noteId: map['noteId'] ?? '',
      text: map['text'] ?? '',
      isChecked: (map['isChecked'] ?? 0) == 1,
      textDelta: map['textDelta'] as String?,
    );
  }

  // JSON serialization for compatibility
  Map<String, dynamic> toJson() => toMap();

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      noteId: json['noteId'],
      text: json['text'],
      isChecked: json['isChecked'] == 1,
      textDelta: json['textDelta'] as String?,
    );
  }

  ChecklistItem copyWith({
    int? id,
    String? noteId,
    String? text,
    bool? isChecked,
    String? textDelta,
    bool clearTextDelta = false,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      text: text ?? this.text,
      isChecked: isChecked ?? this.isChecked,
      textDelta: clearTextDelta ? null : (textDelta ?? this.textDelta),
    );
  }

  @override
  String toString() {
    return 'ChecklistItem{id: $id, noteId: $noteId, text: $text, isChecked: $isChecked}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChecklistItem &&
        other.id == id &&
        other.noteId == noteId &&
        other.text == text &&
        other.isChecked == isChecked;
  }

  @override
  int get hashCode {
    return id.hashCode ^ noteId.hashCode ^ text.hashCode ^ isChecked.hashCode;
  }
}
