import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../utils/constants.dart';

class HiveService {
  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(NoteAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(NoteColorAdapter());
      }

      // Open boxes
      await Hive.openBox<Note>(AppConstants.notesBox);
      await Hive.openBox(AppConstants.settingsBox);
    } catch (e) {
      // Hive initialization error (print removed for production)
      rethrow;
    }
  }

  static Future<void> clearAllData() async {
    await Hive.box<Note>(AppConstants.notesBox).clear();
    await Hive.box(AppConstants.settingsBox).clear();
  }

  static Future<void> close() async {
    await Hive.close();
  }
}
