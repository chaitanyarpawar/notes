import 'package:flutter/material.dart';
import '../controllers/formatted_text_controller.dart';

/// TextField with rich text formatting support
/// Shows floating toolbar on text selection
class FormattedTextField extends StatefulWidget {
  final FormattedTextController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final TextStyle? style;
  final TextStyle? hintStyle;
  final int? maxLines;
  final bool expands;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Function(String)? onImageInserted;
  final InputDecoration? decoration;
  final TextAlignVertical? textAlignVertical;

  const FormattedTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.style,
    this.hintStyle,
    this.maxLines,
    this.expands = false,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.sentences,
    this.onImageInserted,
    this.decoration,
    this.textAlignVertical,
  });

  @override
  State<FormattedTextField> createState() => _FormattedTextFieldState();
}

class _FormattedTextFieldState extends State<FormattedTextField> {
  // Floating toolbar disabled - use bottom sheet formatting dialog instead

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      style: widget.style,
      maxLines: widget.maxLines,
      expands: widget.expands,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      textAlign: widget.controller.document.globalAlignment,
      textAlignVertical: widget.textAlignVertical,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            hintStyle: widget.hintStyle,
            border: InputBorder.none,
          ),
    );
  }
}
