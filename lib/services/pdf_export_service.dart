import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sheet_template.dart';

class PdfExportService {
  /// Generate PDF from sheet data
  static Future<File> generateSheetPdf({
    required SheetData sheetData,
    required String title,
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    // Get current date
    final now = DateTime.now();
    final dateStr = '${now.day} ${_getMonthName(now.month)} ${now.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Watermark
              pw.Positioned.fill(
                child: pw.Center(
                  child: pw.Transform.rotate(
                    angle: -0.5, // Diagonal angle
                    child: pw.Opacity(
                      opacity: 0.1,
                      child: pw.Text(
                        'PebbleNote',
                        style: pw.TextStyle(
                          fontSize: 80,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 2, color: PdfColors.grey800),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        subtitle,
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Date: $dateStr',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Table Header
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange100,
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Row(
                  children: sheetData.columns.map((column) {
                    return pw.Expanded(
                      flex: column.type == ColumnType.text ? 3 : 2,
                      child: pw.Text(
                        column.name,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                        textAlign: column.type == ColumnType.number
                            ? pw.TextAlign.center
                            : pw.TextAlign.left,
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Table Rows
              ...sheetData.rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final isEven = index % 2 == 0;

                return pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.white : PdfColors.grey100,
                    border: const pw.Border(
                      left: pw.BorderSide(color: PdfColors.grey400),
                      right: pw.BorderSide(color: PdfColors.grey400),
                      bottom: pw.BorderSide(color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Row(
                    children: sheetData.columns.map((column) {
                      final value = row.cells[column.id] ?? '';
                      return pw.Expanded(
                        flex: column.type == ColumnType.text ? 3 : 2,
                        child: pw.Text(
                          value,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey800,
                          ),
                          textAlign: column.type == ColumnType.number
                              ? pw.TextAlign.right
                              : pw.TextAlign.left,
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),

              // Total Section
              if (sheetData.hasTotal) ...[
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        sheetData.totalLabel ?? 'Total',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '${sheetData.currencySymbol ?? '₹'} ${sheetData.calculateTotal().toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Footer
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by PebbleNote',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
            ],
          );
        },
      ),
    );

    // Save to temporary file
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/sheet_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Export and share PDF
  static Future<void> exportAndSharePdf({
    required SheetData sheetData,
    required String title,
    String? subtitle,
  }) async {
    try {
      final file = await generateSheetPdf(
        sheetData: sheetData,
        title: title,
        subtitle: subtitle,
      );

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Shared from PebbleNote',
        subject: title,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Preview and print PDF
  static Future<void> previewAndPrintPdf({
    required SheetData sheetData,
    required String title,
    String? subtitle,
  }) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.day} ${_getMonthName(now.month)} ${now.year}';

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final pdf = pw.Document();

          pdf.addPage(
            pw.Page(
              pageFormat: format,
              margin: const pw.EdgeInsets.all(32),
              build: (pw.Context context) {
                return pw.Stack(
                  children: [
                    // Watermark
                    pw.Positioned.fill(
                      child: pw.Center(
                        child: pw.Transform.rotate(
                          angle: -0.5, // Diagonal angle
                          child: pw.Opacity(
                            opacity: 0.1,
                            child: pw.Text(
                              'PebbleNote',
                              style: pw.TextStyle(
                                fontSize: 80,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Main content
                    pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header
                    pw.Container(
                      padding: const pw.EdgeInsets.only(bottom: 16),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(width: 2, color: PdfColors.grey800),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            title,
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey900,
                            ),
                          ),
                          if (subtitle != null) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              subtitle,
                              style: const pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'Date: $dateStr',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 20),

                    // Table Header
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange100,
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Row(
                        children: sheetData.columns.map((column) {
                          return pw.Expanded(
                            flex: column.type == ColumnType.text ? 3 : 2,
                            child: pw.Text(
                              column.name,
                              style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                              textAlign: column.type == ColumnType.number
                                  ? pw.TextAlign.center
                                  : pw.TextAlign.left,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Table Rows
                    ...sheetData.rows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      final isEven = index % 2 == 0;

                      return pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: isEven ? PdfColors.white : PdfColors.grey100,
                          border: const pw.Border(
                            left: pw.BorderSide(color: PdfColors.grey400),
                            right: pw.BorderSide(color: PdfColors.grey400),
                            bottom: pw.BorderSide(color: PdfColors.grey300),
                          ),
                        ),
                        child: pw.Row(
                          children: sheetData.columns.map((column) {
                            final value = row.cells[column.id] ?? '';
                            return pw.Expanded(
                              flex: column.type == ColumnType.text ? 3 : 2,
                              child: pw.Text(
                                value,
                                style: const pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColors.grey800,
                                ),
                                textAlign: column.type == ColumnType.number
                                    ? pw.TextAlign.right
                                    : pw.TextAlign.left,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),

                    // Total Section
                    if (sheetData.hasTotal) ...[
                      pw.SizedBox(height: 16),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.orange,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              sheetData.totalLabel ?? 'Total',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                            pw.Text(
                              '${sheetData.currencySymbol ?? '₹'} ${sheetData.calculateTotal().toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Footer
                    pw.Spacer(),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Generated by PebbleNote',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          'Page ${context.pageNumber} of ${context.pagesCount}',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                  ],
                );
              },
            ),
          );

          return pdf.save();
        },
        name: '${title.replaceAll(' ', '_')}.pdf',
      );
    } catch (e) {
      rethrow;
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
