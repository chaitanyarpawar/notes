// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      color: fields[3] as NoteColor,
      isPinned: fields[4] as bool,
      isArchived: fields[5] as bool,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      category: fields[8] as String,
      reminderTime: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.isPinned)
      ..writeByte(5)
      ..write(obj.isArchived)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.reminderTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteColorAdapter extends TypeAdapter<NoteColor> {
  @override
  final int typeId = 1;

  @override
  NoteColor read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NoteColor.yellow;
      case 1:
        return NoteColor.blue;
      case 2:
        return NoteColor.purple;
      case 3:
        return NoteColor.pink;
      case 4:
        return NoteColor.green;
      case 5:
        return NoteColor.orange;
      default:
        return NoteColor.yellow;
    }
  }

  @override
  void write(BinaryWriter writer, NoteColor obj) {
    switch (obj) {
      case NoteColor.yellow:
        writer.writeByte(0);
        break;
      case NoteColor.blue:
        writer.writeByte(1);
        break;
      case NoteColor.purple:
        writer.writeByte(2);
        break;
      case NoteColor.pink:
        writer.writeByte(3);
        break;
      case NoteColor.green:
        writer.writeByte(4);
        break;
      case NoteColor.orange:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteColorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
