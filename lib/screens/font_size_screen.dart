import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class FontSizeScreen extends StatelessWidget {
  const FontSizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Color(0xFF1A1A2E)),
                ),
              ),
              const SizedBox(height: 24),

              // Large title
              const Text(
                'Select Font Size',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the text size that suits you best',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 32),

              // Options
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return Column(
                    children: [
                      _FontSizeCard(
                        label: 'Small',
                        subtitle: 'Compact · More content on screen',
                        scale: 0.85,
                        accentColor: const Color(0xFF34C759),
                        previewSize: 14,
                        selected: themeProvider.fontScale <= 0.90,
                        onTap: () {
                          themeProvider.setFontScale(0.85);
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 14),
                      _FontSizeCard(
                        label: 'Medium',
                        subtitle: 'Default · Balanced readability',
                        scale: 1.0,
                        accentColor: const Color(0xFFFF9500),
                        previewSize: 18,
                        selected: themeProvider.fontScale > 0.90 &&
                            themeProvider.fontScale < 1.08,
                        onTap: () {
                          themeProvider.setFontScale(1.0);
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 14),
                      _FontSizeCard(
                        label: 'Large',
                        subtitle: 'Comfortable · Easy to read',
                        scale: 1.15,
                        accentColor: const Color(0xFFFF3B30),
                        previewSize: 22,
                        selected: themeProvider.fontScale >= 1.08 &&
                            themeProvider.fontScale < 1.25,
                        onTap: () {
                          themeProvider.setFontScale(1.15);
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 14),
                      _FontSizeCard(
                        label: 'Extra Large',
                        subtitle: 'Accessibility · Maximum clarity',
                        scale: 1.30,
                        accentColor: const Color(0xFF9B59B6),
                        previewSize: 27,
                        selected: themeProvider.fontScale >= 1.25,
                        onTap: () {
                          themeProvider.setFontScale(1.30);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FontSizeCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final double scale;
  final Color accentColor;
  final double previewSize;
  final bool selected;
  final VoidCallback onTap;

  const _FontSizeCard({
    required this.label,
    required this.subtitle,
    required this.scale,
    required this.accentColor,
    required this.previewSize,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored left border
              Container(
                width: 5,
                color: accentColor,
              ),

              // Content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Row(
                    children: [
                      // Icon chip with "A" preview
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              fontSize: previewSize,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Label + subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Selected indicator / arrow
                      if (selected)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 15),
                        )
                      else
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.grey.shade400, size: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
