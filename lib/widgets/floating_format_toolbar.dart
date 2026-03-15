import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../services/image_service.dart';

/// Floating formatting toolbar that appears above text selection
/// Matches Medium/Notion style with rounded floating bar design
class FloatingFormatToolbar extends StatefulWidget {
  final quill.QuillController controller;
  final VoidCallback? onImageInserted;

  const FloatingFormatToolbar({
    super.key,
    required this.controller,
    this.onImageInserted,
  });

  @override
  State<FloatingFormatToolbar> createState() => _FloatingFormatToolbarState();
}

class _FloatingFormatToolbarState extends State<FloatingFormatToolbar>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  bool _isVisible = false;
  final Offset _toolbarPosition = Offset.zero;

  // Available fonts
  final List<String> _fonts = [
    'Roboto',
    'Poppins',
    'Montserrat',
    'Lora', // Serif
    'Caveat', // Handwriting
  ];

  String _selectedFont = 'Roboto';

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
    _listenToSelection();
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

  void _listenToSelection() {
    widget.controller.addListener(_handleSelectionChange);
  }

  void _handleSelectionChange() {
    final selection = widget.controller.selection;

    // Show toolbar if:
    // 1. Text is selected (selection is not collapsed)
    // 2. Or cursor is active (we'll check focus in the parent widget)
    if (!selection.isCollapsed &&
        selection.baseOffset != selection.extentOffset) {
      _showToolbar();
    } else {
      _hideToolbar();
    }
  }

  void _showToolbar() {
    if (_isVisible) return;

    _isVisible = true;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController.forward();
  }

  void _hideToolbar() {
    if (!_isVisible) return;

    _isVisible = false;
    _animationController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Positioned(
        top: _calculateToolbarPosition().dy,
        left: _calculateToolbarPosition().dx,
        child: AnimatedBuilder(
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
            attribute: quill.Attribute.bold,
            tooltip: 'Bold',
          ),

          // Italic
          _buildFormatButton(
            icon: Icons.format_italic,
            attribute: quill.Attribute.italic,
            tooltip: 'Italic',
          ),

          // Underline
          _buildFormatButton(
            icon: Icons.format_underline,
            attribute: quill.Attribute.underline,
            tooltip: 'Underline',
          ),

          _buildDivider(),

          // Link
          _buildLinkButton(),

          _buildDivider(),

          // Text Color
          _buildColorPicker(),

          _buildDivider(),

          // Alignment buttons
          _buildAlignmentButtons(),

          _buildDivider(),

          // Insert Image
          _buildImageButton(),
        ],
      ),
    );
  }

  Widget _buildFontDropdown() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFont,
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
              setState(() => _selectedFont = font);
              widget.controller.formatSelection(
                quill.Attribute.fromKeyValue('font', font),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required quill.Attribute attribute,
    required String tooltip,
  }) {
    final isActive = widget.controller
        .getSelectionStyle()
        .attributes
        .containsKey(attribute.key);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          widget.controller.formatSelection(
            isActive ? quill.Attribute.clone(attribute, null) : attribute,
          );
          setState(() {});
        },
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

  Widget _buildLinkButton() {
    return Tooltip(
      message: 'Insert Link',
      child: InkWell(
        onTap: _showLinkDialog,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.link,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    final currentColor = widget.controller
            .getSelectionStyle()
            .attributes['color']
            ?.value as String? ??
        '#000000';

    return PopupMenuButton<Color>(
      tooltip: 'Text Color',
      offset: const Offset(0, -10),
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
                  color:
                      Color(int.parse(currentColor.replaceFirst('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
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
      onSelected: (color) {
        final hexColor = '#${color.value.toRadixString(16).substring(2)}';
        widget.controller.formatSelection(
          quill.Attribute.fromKeyValue('color', hexColor),
        );
      },
    );
  }

  Widget _buildAlignmentButtons() {
    return Row(
      children: [
        _buildAlignButton(
            Icons.format_align_left, quill.Attribute.leftAlignment),
        _buildAlignButton(
            Icons.format_align_center, quill.Attribute.centerAlignment),
        _buildAlignButton(
            Icons.format_align_right, quill.Attribute.rightAlignment),
      ],
    );
  }

  Widget _buildAlignButton(IconData icon, quill.Attribute attribute) {
    final isActive = widget.controller
        .getSelectionStyle()
        .attributes
        .containsKey(attribute.key);

    return InkWell(
      onTap: () {
        widget.controller.formatSelection(attribute);
        setState(() {});
      },
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

  void _showLinkDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert Link'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter URL',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final url = textController.text;
              if (url.isNotEmpty) {
                widget.controller.formatSelection(
                  quill.Attribute.fromKeyValue('link', url),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Insert'),
          ),
        ],
      ),
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
                  _insertImage(imagePath);
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
                  _insertImage(imagePath);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _insertImage(String imagePath) {
    final index = widget.controller.selection.baseOffset;
    widget.controller.document.insert(index, quill.BlockEmbed.image(imagePath));
    widget.controller.moveCursorToPosition(index + 1);
    widget.onImageInserted?.call();
  }

  Offset _calculateToolbarPosition() {
    try {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return const Offset(20, 100);

      final selection = widget.controller.selection;
      if (selection.isCollapsed) return const Offset(20, 100);

      // Get screen size
      final screenSize = MediaQuery.of(context).size;

      // Calculate position (simplified - you may need to enhance this)
      double x = 20;
      double y = 100;

      // Clamp to screen bounds
      x = math.max(20,
          math.min(x, screenSize.width - 520)); // 520 = toolbar width + padding
      y = math.max(60, math.min(y, screenSize.height - 150));

      return Offset(x, y);
    } catch (e) {
      return const Offset(20, 100);
    }
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
    widget.controller.removeListener(_handleSelectionChange);
    _hideToolbar();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget doesn't render anything directly
    // It manages the overlay
    return const SizedBox.shrink();
  }
}
