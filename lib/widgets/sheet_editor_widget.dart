import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/sheet_template.dart';
import 'package:uuid/uuid.dart';

class SheetEditorWidget extends StatefulWidget {
  final SheetData sheetData;
  final Function(SheetData) onChanged;
  final bool readOnly;

  const SheetEditorWidget({
    super.key,
    required this.sheetData,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<SheetEditorWidget> createState() => _SheetEditorWidgetState();
}

class _SheetEditorWidgetState extends State<SheetEditorWidget> {
  late SheetData _currentData;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _currentData = widget.sheetData;
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var row in _currentData.rows) {
      for (var column in _currentData.columns) {
        final key = '${row.id}_${column.id}';
        _controllers[key] = TextEditingController(
          text: row.cells[column.id] ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateCell(String rowId, String columnId, String value) {
    final updatedRows = _currentData.rows.map((row) {
      if (row.id == rowId) {
        final newCells = Map<String, String>.from(row.cells);
        newCells[columnId] = value;
        return row.copyWith(cells: newCells);
      }
      return row;
    }).toList();

    setState(() {
      _currentData = _currentData.copyWith(rows: updatedRows);
    });
    widget.onChanged(_currentData);
  }

  void _addRow() {
    // Limit to maximum 5 rows
    if (_currentData.rows.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 5 rows allowed'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newRow = SheetRow(
      id: const Uuid().v4(),
      cells: {
        for (var column in _currentData.columns) column.id: '',
      },
    );

    // Initialize controllers for new row
    for (var column in _currentData.columns) {
      final key = '${newRow.id}_${column.id}';
      _controllers[key] = TextEditingController();
    }

    setState(() {
      _currentData = _currentData.copyWith(
        rows: [..._currentData.rows, newRow],
      );
    });
    widget.onChanged(_currentData);
  }

  void _deleteRow(String rowId) {
    // Remove controllers for this row
    for (var column in _currentData.columns) {
      final key = '${rowId}_${column.id}';
      _controllers[key]?.dispose();
      _controllers.remove(key);
    }

    setState(() {
      _currentData = _currentData.copyWith(
        rows: _currentData.rows.where((row) => row.id != rowId).toList(),
      );
    });
    widget.onChanged(_currentData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _currentData.calculateTotal();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: _currentData.columns.map((column) {
                return Expanded(
                  flex: column.type == ColumnType.text ? 3 : 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      column.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      textAlign: column.type == ColumnType.number 
                          ? TextAlign.center 
                          : TextAlign.left,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Table Rows
          ..._currentData.rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isEven = index % 2 == 0;

            return Container(
              decoration: BoxDecoration(
                color: isEven 
                    ? theme.colorScheme.surface 
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              child: Row(
                children: [
                  ..._currentData.columns.map((column) {
                    final key = '${row.id}_${column.id}';
                    return Expanded(
                      flex: column.type == ColumnType.text ? 3 : 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: TextField(
                          controller: _controllers[key],
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(8),
                            isDense: true,
                          ),
                          textAlign: column.type == ColumnType.number 
                              ? TextAlign.right 
                              : TextAlign.left,
                          keyboardType: column.type == ColumnType.number
                              ? const TextInputType.numberWithOptions(decimal: true)
                              : TextInputType.text,
                          inputFormatters: column.type == ColumnType.number
                              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                              : null,
                          onChanged: (value) {
                            _updateCell(row.id, column.id, value);
                          },
                          readOnly: widget.readOnly,
                          style: TextStyle(
                            fontSize: 15,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }),
                  if (!widget.readOnly)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _deleteRow(row.id),
                      color: Colors.red[400],
                      tooltip: 'Delete row',
                    ),
                ],
              ),
            );
          }),

          // Add Row Button
          if (!widget.readOnly)
            InkWell(
              onTap: _currentData.rows.length >= 5 ? null : _addRow,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _currentData.rows.length >= 5
                        ? Colors.grey.withOpacity(0.3)
                        : theme.colorScheme.primary.withOpacity(0.3),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                  color: _currentData.rows.length >= 5
                      ? Colors.grey.withOpacity(0.1)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentData.rows.length >= 5
                          ? Icons.block
                          : Icons.add_circle_outline,
                      color: _currentData.rows.length >= 5
                          ? Colors.grey
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentData.rows.length >= 5
                          ? 'Maximum Rows Reached (5/5)'
                          : 'Add Row (${_currentData.rows.length}/5)',
                      style: TextStyle(
                        color: _currentData.rows.length >= 5
                            ? Colors.grey
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Total Section
          if (_currentData.hasTotal)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentData.totalLabel ?? 'Total Due',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_currentData.currencySymbol ?? '₹'} ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
