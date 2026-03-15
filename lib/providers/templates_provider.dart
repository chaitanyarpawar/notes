import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/note_template.dart';
import '../models/sheet_template.dart';
import 'package:uuid/uuid.dart';

class TemplatesProvider with ChangeNotifier {
  List<NoteTemplate> _userTemplates = [];
  List<NoteTemplate> _builtInTemplates = [];

  List<NoteTemplate> get userTemplates => _userTemplates;
  List<NoteTemplate> get builtInTemplates => _builtInTemplates;
  List<NoteTemplate> get allTemplates =>
      [..._builtInTemplates, ..._userTemplates];

  TemplatesProvider() {
    _initializeBuiltInTemplates();
    loadTemplates();
  }

  /// Initialize built-in templates
  void _initializeBuiltInTemplates() {
    _builtInTemplates = [
      // 🛒 Daily Use Sheet Templates
      NoteTemplate(
        id: 'builtin_grocery',
        title: '🛒 Grocery List',
        content: '',
        category: 'Daily Use',
        isBuiltIn: true,
        templateType: TemplateType.sheet,
        sheetData: SheetData(
          columns: [
            SheetColumn(id: 'item', name: 'Item', type: ColumnType.text),
            SheetColumn(id: 'quantity', name: 'Qty', type: ColumnType.text),
            SheetColumn(id: 'price', name: 'Price', type: ColumnType.number),
          ],
          rows: [
            SheetRow(
                id: const Uuid().v4(),
                cells: {'item': 'Milk', 'quantity': '1 L', 'price': '60'}),
          ],
          hasTotal: true,
          totalLabel: 'Total',
          currencySymbol: '₹',
        ),
      ),
      NoteTemplate(
        id: 'builtin_expense_tracker',
        title: '📊 Monthly Expense Tracker',
        content: '',
        category: 'Finance',
        isBuiltIn: true,
        templateType: TemplateType.sheet,
        sheetData: SheetData(
          columns: [
            SheetColumn(
                id: 'category', name: 'Category', type: ColumnType.text),
            SheetColumn(
                id: 'description', name: 'Description', type: ColumnType.text),
            SheetColumn(id: 'amount', name: 'Amount', type: ColumnType.number),
          ],
          rows: [
            SheetRow(id: const Uuid().v4(), cells: {
              'category': 'Food',
              'description': 'Groceries',
              'amount': '2000'
            }),
          ],
          hasTotal: true,
          totalLabel: 'Total Expenses',
          currencySymbol: '₹',
        ),
      ),

      // 📝 Text Templates (Daily Use)
      NoteTemplate(
        id: 'builtin_daily_planner',
        title: '📅 Daily Planner',
        content: '''Daily Planner

Date: 

🌅 Morning (6 AM - 12 PM):
• 
• 
• 

🌞 Afternoon (12 PM - 6 PM):
• 
• 
• 

🌙 Evening (6 PM - 12 AM):
• 
• 
• 

Priority Tasks:
⭐ 
⭐ 
⭐ 

Notes:


Tomorrow's Prep:
• 
• ''',
        category: 'Daily Use',
        isBuiltIn: true,
        templateType: TemplateType.text,
      ),
      NoteTemplate(
        id: 'builtin_study_notes',
        title: '📚 Study Notes',
        content: '''Study Notes

Subject: 
Topic: 
Date: 

Key Concepts:
• 
• 
• 

Important Points:
📌 
📌 
📌 

Formulas/Definitions:


Questions to Review:
❓ 
❓ 
❓ 

Practice Problems:
• 
• 
• 

References:
- 
- ''',
        category: 'Daily Use',
        isBuiltIn: true,
        templateType: TemplateType.text,
      ),
      NoteTemplate(
        id: 'builtin_medicine_log',
        title: '💊 Medicine Reminder Log',
        content: '''Medicine Reminder Log

Patient Name: 

Morning:
• Medicine 1: _____ (Time: _____)
• Medicine 2: _____ (Time: _____)

Afternoon:
• Medicine 1: _____ (Time: _____)
• Medicine 2: _____ (Time: _____)

Evening:
• Medicine 1: _____ (Time: _____)
• Medicine 2: _____ (Time: _____)

Night:
• Medicine 1: _____ (Time: _____)
• Medicine 2: _____ (Time: _____)

Notes:
- Take with food/water
- Doctor's instructions:
- Side effects to watch:

Refill Date: 
Doctor Contact: ''',
        category: 'Daily Use',
        isBuiltIn: true,
        templateType: TemplateType.text,
      ),

      // 💰 Finance Sheet Templates
      NoteTemplate(
        id: 'builtin_monthly_budget',
        title: '💰 Monthly Budget',
        content: '',
        category: 'Finance',
        isBuiltIn: true,
        templateType: TemplateType.sheet,
        sheetData: SheetData(
          columns: [
            SheetColumn(
                id: 'category', name: 'Category', type: ColumnType.text),
            SheetColumn(id: 'budget', name: 'Budget', type: ColumnType.number),
            SheetColumn(id: 'actual', name: 'Actual', type: ColumnType.number),
          ],
          rows: [
            SheetRow(id: const Uuid().v4(), cells: {
              'category': 'Rent',
              'budget': '15000',
              'actual': '15000'
            }),
          ],
          hasTotal: true,
          totalLabel: 'Total Budget',
          currencySymbol: '₹',
        ),
      ),
      NoteTemplate(
        id: 'builtin_emi_tracker',
        title: '📅 EMI Tracker',
        content: '',
        category: 'Finance',
        isBuiltIn: true,
        templateType: TemplateType.sheet,
        sheetData: SheetData(
          columns: [
            SheetColumn(id: 'loan', name: 'Loan Type', type: ColumnType.text),
            SheetColumn(id: 'emi', name: 'EMI Amount', type: ColumnType.number),
            SheetColumn(id: 'due', name: 'Due Date', type: ColumnType.text),
          ],
          rows: [
            SheetRow(
                id: const Uuid().v4(),
                cells: {'loan': 'Home Loan', 'emi': '12000', 'due': '5th'}),
          ],
          hasTotal: true,
          totalLabel: 'Total EMI',
          currencySymbol: '₹',
        ),
      ),

      // 🏢 Business Sheet Templates
      NoteTemplate(
        id: 'builtin_customer_list',
        title: '🏢 Customer List',
        content: '',
        category: 'Business',
        isBuiltIn: true,
        templateType: TemplateType.sheet,
        sheetData: SheetData(
          columns: [
            SheetColumn(
                id: 'name', name: 'Customer Name', type: ColumnType.text),
            SheetColumn(id: 'contact', name: 'Contact', type: ColumnType.text),
            SheetColumn(id: 'email', name: 'Email', type: ColumnType.text),
          ],
          rows: [
            SheetRow(id: const Uuid().v4(), cells: {
              'name': 'John Doe',
              'contact': '9876543210',
              'email': 'john@example.com'
            }),
          ],
          hasTotal: false,
        ),
      ),
      NoteTemplate(
        id: 'builtin_payment_due',
        title: '💳 Payment Due List',
        content: '',
        category: 'Business',
        isBuiltIn: true,
        templateType: TemplateType.sheet,
        sheetData: SheetData(
          columns: [
            SheetColumn(
                id: 'customer', name: 'Customer', type: ColumnType.text),
            SheetColumn(id: 'amount', name: 'Amount', type: ColumnType.number),
            SheetColumn(
                id: 'due_date', name: 'Due Date', type: ColumnType.text),
          ],
          rows: [
            SheetRow(id: const Uuid().v4(), cells: {
              'customer': 'ABC Company',
              'amount': '25000',
              'due_date': '15 Mar'
            }),
          ],
          hasTotal: true,
          totalLabel: 'Total Due',
          currencySymbol: '₹',
        ),
      ),

      // Additional Text Templates
      NoteTemplate(
        id: 'builtin_journal',
        title: '📓 Daily Journal',
        content: '''Daily Journal

Date: 

Mood: 

Today's Highlights:
- 
- 
- 

Thoughts:


Grateful For:
- 
- 
- ''',
        category: 'Daily Use',
        isBuiltIn: true,
        templateType: TemplateType.text,
      ),
      NoteTemplate(
        id: 'builtin_ideas',
        title: '💡 Ideas & Brainstorming',
        content: '''Ideas & Brainstorming

Topic: 

Ideas:
💡 
💡 
💡 

Next Steps:
• 
• 

Notes:
''',
        category: 'Daily Use',
        isBuiltIn: true,
        templateType: TemplateType.text,
      ),
    ];
  }

  /// Load user templates from storage
  Future<void> loadTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = prefs.getString('user_templates');

      if (templatesJson != null) {
        final List<dynamic> decoded = jsonDecode(templatesJson);
        _userTemplates = decoded
            .map((item) => NoteTemplate.fromJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading templates: $e');
    }
  }

  /// Save user templates to storage
  Future<void> _saveTemplates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final templatesJson = jsonEncode(
        _userTemplates.map((t) => t.toJson()).toList(),
      );
      await prefs.setString('user_templates', templatesJson);
    } catch (e) {
      debugPrint('Error saving templates: $e');
    }
  }

  /// Add a new user template
  Future<void> addTemplate(NoteTemplate template) async {
    _userTemplates.add(template);
    notifyListeners();
    await _saveTemplates();
  }

  /// Delete a user template
  Future<void> deleteTemplate(String templateId) async {
    _userTemplates.removeWhere((t) => t.id == templateId);
    notifyListeners();
    await _saveTemplates();
  }

  /// Get template by ID
  NoteTemplate? getTemplateById(String id) {
    try {
      return allTemplates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Update a user template
  Future<void> updateTemplate(NoteTemplate template) async {
    final index = _userTemplates.indexWhere((t) => t.id == template.id);
    if (index != -1) {
      _userTemplates[index] = template;
      notifyListeners();
      await _saveTemplates();
    }
  }
}
