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

  // Rich text content stored as Quill Delta JSON
  // When this is set, it takes precedence over plain 'content'
  @HiveField(11)
  String? contentDelta;

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

  // Optional reminder timestamp; null means no reminder set
  @HiveField(9)
  DateTime? reminderTime;

  // Optional stored notification ID used for canceling scheduled reminders
  @HiveField(10)
  int? notificationId;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.contentDelta,
    this.color = NoteColor.yellow,
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.category = 'Personal',
    this.reminderTime,
    this.notificationId,
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
    String? contentDelta,
    bool clearContentDelta = false,
    NoteColor? color,
    bool? isPinned,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    DateTime? reminderTime,
    bool clearReminder = false,
    int? notificationId,
    bool clearNotificationId = false,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      contentDelta:
          clearContentDelta ? null : (contentDelta ?? this.contentDelta),
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      reminderTime: clearReminder ? null : (reminderTime ?? this.reminderTime),
      notificationId:
          clearNotificationId ? null : (notificationId ?? this.notificationId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'contentDelta': contentDelta,
      'color': color.index,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'category': category,
      'reminderTime': reminderTime?.millisecondsSinceEpoch,
      'notificationId': notificationId,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      contentDelta: json['contentDelta'] as String?,
      color: NoteColor.values[json['color']],
      isPinned: json['isPinned'],
      isArchived: json['isArchived'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      category: json['category'] ?? 'Personal',
      reminderTime: json['reminderTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['reminderTime'])
          : null,
      notificationId: json['notificationId'] as int?,
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
