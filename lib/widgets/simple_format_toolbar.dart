import 'package:flutter/material.dart';
import '../models/text_format.dart';
import '../services/image_service.dart';

/// Simplified floating formatting toolbar for custom rich text
/// Appears above text selection with rounded bar design
class SimpleFormatToolbar extends StatefulWidget {
  final TextSelection selection;
  final TextFormatStyle currentStyle;
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onUnderline;
  final Function(Color) onColorChange;
  final Function(String) onFontChange;
  final Function(TextAlign) onAlignmentChange;
  final Function(String) onImageInsert;
  final Offset? selectionPosition;

  const SimpleFormatToolbar({
    super.key,
    required this.selection,
    required this.currentStyle,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
    required this.onColorChange,
    required this.onFontChange,
    required this.onAlignmentChange,
    required this.onImageInsert,
    this.selectionPosition,
  });

  @override
  State<SimpleFormatToolbar> createState() => _SimpleFormatToolbarState();
}

class _SimpleFormatToolbarState extends State<SimpleFormatToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  // Available fonts
  final List<String> _fonts = [
    'Roboto',
    'Poppins',
    'Montserrat',
    'Lora',
    'Caveat',
  ];

  // Text colors
  final List<Color> _textColors = [
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 50,
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[850]
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildToolbarContent(),
        ),
      ),
    );
  }

  Widget _buildToolbarContent() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Font Dropdown
          _buildFontDropdown(),
          _buildDivider(),

          // Bold
          _buildFormatButton(
            icon: Icons.format_bold,
            isActive: widget.currentStyle.bold,
            onTap: widget.onBold,
            tooltip: 'Bold',
          ),

          // Italic
          _buildFormatButton(
            icon: Icons.format_italic,
            isActive: widget.currentStyle.italic,
            onTap: widget.onItalic,
            tooltip: 'Italic',
          ),

          // Underline
          _buildFormatButton(
            icon: Icons.format_underline,
            isActive: widget.currentStyle.underline,
            onTap: widget.onUnderline,
            tooltip: 'Underline',
          ),

          _buildDivider(),

          // Text Color
          _buildColorPicker(),

          _buildDivider(),

          // Alignment buttons
          _buildAlignmentButtons(),
        ],
      ),
    );
  }

  Widget _buildFontDropdown() {
    final selectedFont = widget.currentStyle.fontFamily ?? 'Roboto';

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _fonts.contains(selectedFont) ? selectedFont : 'Roboto',
          isDense: true,
          items: _fonts.map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(
                font,
                style: TextStyle(
                  fontFamily: font,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
          onChanged: (font) {
            if (font != null) {
              widget.onFontChange(font);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).primaryColor.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isActive
                ? Theme.of(context).primaryColor
                : Theme.of(context).iconTheme.color,
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final currentColor = widget.currentStyle.color ?? Colors.black;

    return PopupMenuButton<Color>(
      tooltip: 'Text Color',
      offset: const Offset(0, -10),
      itemBuilder: (context) {
        return _textColors.map((color) {
          return PopupMenuItem<Color>(
            value: color,
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
                const SizedBox(width: 12),
                Text(_getColorName(color)),
              ],
            ),
          );
        }).toList();
      },
      onSelected: widget.onColorChange,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.format_color_text, size: 20),
            Positioned(
              bottom: 6,
              child: Container(
                width: 16,
                height: 3,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlignmentButtons() {
    return Row(
      children: [
        _buildAlignButton(Icons.format_align_left, TextAlign.left),
        _buildAlignButton(Icons.format_align_center, TextAlign.center),
        _buildAlignButton(Icons.format_align_right, TextAlign.right),
      ],
    );
  }

  Widget _buildAlignButton(IconData icon, TextAlign alignment) {
    final isActive = widget.currentStyle.alignment == alignment;

    return InkWell(
      onTap: () => widget.onAlignmentChange(alignment),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).primaryColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive
              ? Theme.of(context).primaryColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }

  Widget _buildImageButton() {
    return Tooltip(
      message: 'Insert Image',
      child: InkWell(
        onTap: _showImagePicker,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.image,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey[300],
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Insert Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await ImageService().pickImageFromCamera();
                if (imagePath != null) {
                  widget.onImageInsert(imagePath);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final imagePath = await ImageService().pickImageFromGallery();
                if (imagePath != null) {
                  widget.onImageInsert(imagePath);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getColorName(Color color) {
    if (color == Colors.black) return 'Black';
    if (color == Colors.red) return 'Red';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    return 'Color';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
