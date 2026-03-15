import 'dart:convert';

enum ColumnType { text, number }

class SheetColumn {
  final String id;
  final String name;
  final ColumnType type;

  SheetColumn({
    required this.id,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
    };
  }

  factory SheetColumn.fromJson(Map<String, dynamic> json) {
    return SheetColumn(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] == 'number' ? ColumnType.number : ColumnType.text,
    );
  }
}

class SheetRow {
  final String id;
  final Map<String, String> cells; // columnId -> value

  SheetRow({
    required this.id,
    required this.cells,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cells': cells,
    };
  }

  factory SheetRow.fromJson(Map<String, dynamic> json) {
    return SheetRow(
      id: json['id'] as String,
      cells: Map<String, String>.from(json['cells'] as Map),
    );
  }

  SheetRow copyWith({Map<String, String>? cells}) {
    return SheetRow(
      id: id,
      cells: cells ?? this.cells,
    );
  }
}

class SheetData {
  final List<SheetColumn> columns;
  final List<SheetRow> rows;
  final bool hasTotal;
  final String? totalLabel;
  final String? currencySymbol;

  SheetData({
    required this.columns,
    required this.rows,
    this.hasTotal = true,
    this.totalLabel = 'Total',
    this.currencySymbol = '₹',
  });

  double calculateTotal() {
    double total = 0;
    final numberColumns = columns.where((col) => col.type == ColumnType.number).toList();
    
    if (numberColumns.isEmpty) return 0;
    
    // Calculate sum of the last number column
    final lastNumberColumn = numberColumns.last;
    
    for (var row in rows) {
      final value = row.cells[lastNumberColumn.id];
      if (value != null && value.isNotEmpty) {
        total += double.tryParse(value) ?? 0;
      }
    }
    
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'columns': columns.map((col) => col.toJson()).toList(),
      'rows': rows.map((row) => row.toJson()).toList(),
      'hasTotal': hasTotal,
      'totalLabel': totalLabel,
      'currencySymbol': currencySymbol,
    };
  }

  factory SheetData.fromJson(Map<String, dynamic> json) {
    return SheetData(
      columns: (json['columns'] as List)
          .map((col) => SheetColumn.fromJson(col as Map<String, dynamic>))
          .toList(),
      rows: (json['rows'] as List)
          .map((row) => SheetRow.fromJson(row as Map<String, dynamic>))
          .toList(),
      hasTotal: json['hasTotal'] as bool? ?? true,
      totalLabel: json['totalLabel'] as String? ?? 'Total',
      currencySymbol: json['currencySymbol'] as String? ?? '₹',
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory SheetData.fromJsonString(String jsonString) {
    return SheetData.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  SheetData copyWith({
    List<SheetColumn>? columns,
    List<SheetRow>? rows,
    bool? hasTotal,
    String? totalLabel,
    String? currencySymbol,
  }) {
    return SheetData(
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      hasTotal: hasTotal ?? this.hasTotal,
      totalLabel: totalLabel ?? this.totalLabel,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}
