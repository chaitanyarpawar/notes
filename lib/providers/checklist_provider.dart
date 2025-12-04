import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist_item.dart';
// Removed sqflite-based service to reduce app size. Using SharedPreferences for persistence across platforms.

class ChecklistProvider extends ChangeNotifier {
  List<ChecklistItem> _items = [];
  bool _isLoading = false;

  List<ChecklistItem> get items => _items;
  bool get isLoading => _isLoading;

  // Load checklist items for a specific note
  Future<void> loadChecklistItems(String noteId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use SharedPreferences-based storage on all platforms to avoid heavy sqflite dependency
      _items = await _loadChecklistItemsWeb(noteId);
      debugPrint(
          '📋 ChecklistProvider: Loaded ${_items.length} items for note $noteId');
    } catch (e) {
      debugPrint('❌ ChecklistProvider: Error loading items: $e');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Web-compatible storage methods
  Future<List<ChecklistItem>> _loadChecklistItemsWeb(String noteId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'checklist_$noteId';
    final itemsJson = prefs.getString(key);

    if (itemsJson == null) return [];

    final List<dynamic> itemsList = json.decode(itemsJson);
    return itemsList.map((item) => ChecklistItem.fromJson(item)).toList();
  }

  Future<void> _saveChecklistItemsWeb(
      String noteId, List<ChecklistItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'checklist_$noteId';
    final itemsJson = json.encode(items.map((item) => item.toJson()).toList());
    await prefs.setString(key, itemsJson);
  }

  // Add a new checklist item
  Future<ChecklistItem?> addChecklistItem(String noteId, String text) async {
    try {
      final item = ChecklistItem(
        noteId: noteId,
        text: text,
        isChecked: false,
      );

      // Generate a simple ID using timestamp
      final id = DateTime.now().millisecondsSinceEpoch;
      final newItem = item.copyWith(id: id);
      _items.add(newItem);
      await _saveChecklistItemsWeb(noteId, _items);
      notifyListeners();
      debugPrint('✅ ChecklistProvider: Added item with ID $id');
      return newItem;
    } catch (e) {
      debugPrint('❌ ChecklistProvider: Error adding item: $e');
      return null;
    }
  }

  // Update checklist item text
  Future<bool> updateChecklistItemText(int id, String text) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) return false;

      final noteId = _items[index].noteId;

      _items[index] = _items[index].copyWith(text: text);
      await _saveChecklistItemsWeb(noteId, _items);

      notifyListeners();
      debugPrint('✅ ChecklistProvider: Updated item text for ID $id');
      return true;
    } catch (e) {
      debugPrint('❌ ChecklistProvider: Error updating item text: $e');
      return false;
    }
  }

  // Update checklist item text without triggering UI rebuild (to prevent text field focus issues)
  Future<bool> updateChecklistItemTextSilent(int id, String text) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) return false;

      final noteId = _items[index].noteId;

      _items[index] = _items[index].copyWith(text: text);
      await _saveChecklistItemsWeb(noteId, _items);

      // Don't call notifyListeners() to prevent UI rebuild while typing
      debugPrint('✅ ChecklistProvider: Updated item text silently for ID $id');
      return true;
    } catch (e) {
      debugPrint('❌ ChecklistProvider: Error updating item text silently: $e');
      return false;
    }
  }

  // Update checklist item status
  Future<bool> updateChecklistItemStatus(int id, bool isChecked) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) return false;

      final noteId = _items[index].noteId;

      _items[index] = _items[index].copyWith(isChecked: isChecked);
      await _saveChecklistItemsWeb(noteId, _items);

      notifyListeners();
      debugPrint(
          '✅ ChecklistProvider: Updated item status for ID $id to $isChecked');
      return true;
    } catch (e) {
      debugPrint('❌ ChecklistProvider: Error updating item status: $e');
      return false;
    }
  }

  // Delete checklist item
  Future<bool> deleteChecklistItem(int id) async {
    try {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) return false;

      final noteId = _items[index].noteId;

      _items.removeWhere((item) => item.id == id);
      await _saveChecklistItemsWeb(noteId, _items);

      notifyListeners();
      debugPrint('✅ ChecklistProvider: Deleted item with ID $id');
      return true;
    } catch (e) {
      debugPrint('❌ ChecklistProvider: Error deleting item: $e');
      return false;
    }
  }

  // Delete all checklist items for a note
  Future<bool> deleteAllChecklistItems(String noteId) async {
    try {
      _items.removeWhere((item) => item.noteId == noteId);
      await _saveChecklistItemsWeb(noteId, _items);

      notifyListeners();
      debugPrint('✅ ChecklistProvider: Deleted all items for note $noteId');
      return true;
    } catch (e) {
      debugPrint('❌ ChecklistProvider: Error deleting all items: $e');
      return false;
    }
  }

  // Get completion stats
  int get completedCount => _items.where((item) => item.isChecked).length;
  int get totalCount => _items.length;
  double get completionPercentage =>
      _items.isEmpty ? 0.0 : completedCount / totalCount;

  // Clear all items (for state reset)
  void clearItems() {
    _items = [];
    notifyListeners();
  }
}
