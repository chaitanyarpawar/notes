import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late NoteColor color;

  @HiveField(4)
  late bool isPinned;

  @HiveField(5)
  late bool isArchived;

  @HiveField(6)
  late DateTime createdAt;

  @HiveField(7)
  late DateTime updatedAt;

  @HiveField(8)
  late String category;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.color = NoteColor.yellow,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.category = 'Personal',
  });

  String get moodEmoji {
    switch (color) {
      case NoteColor.yellow:
        return '😊';
      case NoteColor.blue:
        return '😌';
      case NoteColor.purple:
        return '💡';
      case NoteColor.pink:
        return '❤️';
      case NoteColor.green:
        return '📘';
      case NoteColor.orange:
        return '⭐';
    }
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteColor? color,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color.index,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'category': category,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      color: NoteColor.values[json['color']],
      isPinned: json['isPinned'],
      isArchived: json['isArchived'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      category: json['category'] ?? 'Personal',
    );
  }
}

@HiveType(typeId: 1)
enum NoteColor {
  @HiveField(0)
  yellow,

  @HiveField(1)
  blue,

  @HiveField(2)
  purple,

  @HiveField(3)
  pink,

  @HiveField(4)
  green,

  @HiveField(5)
  orange,
}
