import 'package:flutter/material.dart';
import '../models/text_format.dart';
import '../services/text_format_service.dart';

/// Extended TextEditingController that manages formatted text
class FormattedTextController extends TextEditingController {
  FormattedTextDocument _document;
  bool _isUpdating = false;

  FormattedTextController({
    String? text,
    FormattedTextDocument? document,
  })  : _document = document ?? FormattedTextDocument.fromPlainText(text ?? ''),
        super(text: document?.plainText ?? text ?? '');

  FormattedTextDocument get document => _document;

  /// Update the document (used when applying formatting)
  void updateDocument(FormattedTextDocument newDocument) {
    if (_isUpdating) return; // Prevent recursive calls

    _isUpdating = true;
    try {
      _document = newDocument;
      
      // Debug: Print what we're updating
      debugPrint('updateDocument: plainText="${newDocument.plainText}", spans=${newDocument.spans.length}');
      for (var span in newDocument.spans) {
        debugPrint('  new span: ${span.start}-${span.end}, bold=${span.style.bold}, italic=${span.style.italic}, underline=${span.style.underline}');
      }
      
      // Update the plain text if it changed
      if (text != newDocument.plainText) {
        super.text = newDocument.plainText;
      }
      notifyListeners();
    } finally {
      _isUpdating = false;
    }
  }

  /// Apply formatting to current selection
  void applyFormatting(TextFormatStyle style) {
    if (selection.start == selection.end) return;

    final newDocument = TextFormatService.applyFormatting(
      document: _document,
      selection: selection,
      style: style,
    );
    updateDocument(newDocument);
  }

  /// Toggle bold for current selection
  void toggleBold() {
    final currentStyle = TextFormatService.getFormatForSelection(
      document: _document,
      selection: selection,
    );

    applyFormatting(currentStyle.copyWith(bold: !currentStyle.bold));
  }

  /// Toggle italic for current selection
  void toggleItalic() {
    final currentStyle = TextFormatService.getFormatForSelection(
      document: _document,
      selection: selection,
    );

    applyFormatting(currentStyle.copyWith(italic: !currentStyle.italic));
  }

  /// Toggle underline for current selection
  void toggleUnderline() {
    final currentStyle = TextFormatService.getFormatForSelection(
      document: _document,
      selection: selection,
    );

    applyFormatting(currentStyle.copyWith(underline: !currentStyle.underline));
  }

  /// Set font family for current selection
  void setFontFamily(String fontFamily) {
    final currentStyle = TextFormatService.getFormatForSelection(
      document: _document,
      selection: selection,
    );

    applyFormatting(currentStyle.copyWith(fontFamily: fontFamily));
  }

  /// Set color for current selection
  void setColor(Color color) {
    final currentStyle = TextFormatService.getFormatForSelection(
      document: _document,
      selection: selection,
    );

    applyFormatting(currentStyle.copyWith(color: color));
  }

  /// Set text alignment
  void setAlignment(TextAlign alignment) {
    final newDocument = TextFormatService.setAlignment(
      document: _document,
      alignment: alignment,
    );
    updateDocument(newDocument);
  }

  /// Get current style at selection
  TextFormatStyle getCurrentStyle() {
    return TextFormatService.getFormatForSelection(
      document: _document,
      selection: selection,
    );
  }

  /// Clear all formatting
  void clearFormatting() {
    final newDocument = TextFormatService.clearFormatting(document: _document);
    updateDocument(newDocument);
  }

  /// Save to JSON
  String toJson() {
    return _document.toJson();
  }

  /// Load from JSON
  void loadFromJson(String json) {
    try {
      final doc = FormattedTextDocument.fromJson(json);
      _document = doc;
      text = doc.plainText;
      notifyListeners();
    } catch (e) {
      print('Error loading formatted text: $e');
    }
  }

  @override
  set text(String newText) {
    // Check if text actually changed to avoid unnecessary updates
    if (_document.plainText == newText) {
      super.text = newText;
      return;
    }

    if (_isUpdating) {
      super.text = newText;
      return; // Prevent recursive calls but still update super
    }

    _isUpdating = true;
    try {
      // Update document's plain text
      final newDocument = TextFormatService.updateText(
        document: _document,
        newText: newText,
      );
      _document = newDocument;
      super.text = newText;
    } finally {
      _isUpdating = false;
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    
    // Only sync document if text was changed externally (not through updateDocument)
    if (!_isUpdating && _document.plainText != text) {
      // Text changed externally, recreate document preserving valid spans
      _document = FormattedTextDocument(
        plainText: text,
        spans: _document.spans.where((s) => s.end <= text.length).toList(),
        globalAlignment: _document.globalAlignment,
      );
    }
    
    // Debug: Print formatting info
    debugPrint('buildTextSpan: text length=${text.length}, spans=${_document.spans.length}');
    for (var span in _document.spans) {
      debugPrint('  span: ${span.start}-${span.end}, bold=${span.style.bold}, italic=${span.style.italic}, underline=${span.style.underline}');
    }
    
    // Build rich text with formatting
    return TextFormatService.buildTextSpan(
      document: _document,
      baseStyle: baseStyle,
    );
  }
}
