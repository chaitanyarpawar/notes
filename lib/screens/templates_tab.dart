import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/templates_provider.dart';
import '../models/note_template.dart';

class TemplatesTab extends StatelessWidget {
  const TemplatesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TemplatesProvider>(
      builder: (context, templatesProvider, child) {
        final builtInTemplates = templatesProvider.builtInTemplates;
        final userTemplates = templatesProvider.userTemplates;

        // Group built-in templates by category
        final dailyUseTemplates = builtInTemplates.where((t) => t.category == 'Daily Use').toList();
        final financeTemplates = builtInTemplates.where((t) => t.category == 'Finance').toList();
        final businessTemplates = builtInTemplates.where((t) => t.category == 'Business').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Built-in Templates Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Built-in Templates',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Icon(Icons.auto_awesome, color: Colors.orange[700], size: 22),
              ],
            ),
            const SizedBox(height: 20),

            // Daily Use Category
            if (dailyUseTemplates.isNotEmpty) ...[
              _buildCategoryHeader('Daily Use', Icons.calendar_today, Colors.blue),
              const SizedBox(height: 8),
              ...dailyUseTemplates.map((template) => _buildTemplateCard(
                    context,
                    template,
                    templatesProvider,
                  )),
              const SizedBox(height: 20),
            ],

            // Finance Category
            if (financeTemplates.isNotEmpty) ...[
              _buildCategoryHeader('Finance', Icons.account_balance_wallet, Colors.green),
              const SizedBox(height: 8),
              ...financeTemplates.map((template) => _buildTemplateCard(
                    context,
                    template,
                    templatesProvider,
                  )),
              const SizedBox(height: 20),
            ],

            // Business Category
            if (businessTemplates.isNotEmpty) ...[
              _buildCategoryHeader('Business', Icons.business_center, Colors.purple),
              const SizedBox(height: 8),
              ...businessTemplates.map((template) => _buildTemplateCard(
                    context,
                    template,
                    templatesProvider,
                  )),
              const SizedBox(height: 20),
            ],

            if (builtInTemplates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No built-in templates available',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    NoteTemplate template,
    TemplatesProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _useTemplate(context, template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  template.templateType == TemplateType.sheet
                      ? Icons.table_chart
                      : (template.isBuiltIn ? Icons.auto_awesome : Icons.description),
                  color: const Color(0xFFFF9500),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              if (!template.isBuiltIn)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteTemplate(context, template, provider);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _useTemplate(BuildContext context, NoteTemplate template) {
    // Create a new note with template content
    if (template.templateType == TemplateType.sheet) {
      // Navigate to note editor with sheet data
      context.push(
        '/note/new',
        extra: {
          'category': template.category,
          'isSheetTemplate': true,
          'sheetData': template.sheetData,
          'templateTitle': template.title,
        },
      );
    } else {
      // Navigate to note editor with text template
      context.push(
        '/note/new?category=${template.category}&templateContent=${Uri.encodeComponent(template.content)}&templateTitle=${Uri.encodeComponent(template.title)}',
      );
    }
  }

  void _createNewTemplate(BuildContext context) {
    // Navigate to note editor to create a template
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Template'),
        content: const Text(
          'Create a new note that will be saved as a template for future use.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/note/new?isTemplate=true');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9500),
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteTemplate(
    BuildContext context,
    NoteTemplate template,
    TemplatesProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Delete template "${template.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTemplate(template.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
