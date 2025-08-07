import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/language_service.dart';
import '../utils/translation_validator.dart';
import '../utils/language_helper.dart';
import '../utils/desktop_constants.dart';

/// Developer screen for validating and managing translations
/// Only available in debug mode
class DevTranslationScreen extends StatefulWidget {
  const DevTranslationScreen({super.key});

  @override
  State<DevTranslationScreen> createState() => _DevTranslationScreenState();
}

class _DevTranslationScreenState extends State<DevTranslationScreen>
    with TickerProviderStateMixin {
  bool _isValidating = false;
  bool _isLoadingProgress = false;
  ValidationReport? _validationReport;
  Map<String, TranslationStatus>? _progressReport;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _validateTranslations(),
      _loadProgressReport(),
    ]);
  }

  Future<void> _validateTranslations() async {
    setState(() {
      _isValidating = true;
    });

    try {
      final report = await TranslationValidator.validateTranslations();
      setState(() {
        _validationReport = report;
      });

      // Print report to console for development
      TranslationValidator.printReport(report);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }

  Future<void> _loadProgressReport() async {
    setState(() {
      _isLoadingProgress = true;
    });

    try {
      final progress = await LanguageHelper.getTranslationProgress();
      setState(() {
        _progressReport = progress;
      });

      // Print progress to console
      LanguageHelper.printProgressReport(progress);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, langService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Translation Developer Tools',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            elevation: 2,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadInitialData,
                tooltip: 'Refresh All Data',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Validation', icon: Icon(Icons.check_circle)),
                Tab(text: 'Progress', icon: Icon(Icons.analytics)),
                Tab(text: 'Tools', icon: Icon(Icons.build)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildValidationTab(),
              _buildProgressTab(),
              _buildToolsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValidationTab() {
    return SingleChildScrollView(
      padding: DesktopConstants.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildValidationHeader(),
          const SizedBox(height: 16),
          if (_isValidating) _buildLoadingCard('Validating translations...'),
          if (_validationReport != null && !_isValidating)
            _buildValidationResults(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: DesktopConstants.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressHeader(),
          const SizedBox(height: 16),
          if (_isLoadingProgress) _buildLoadingCard('Loading progress data...'),
          if (_progressReport != null && !_isLoadingProgress)
            _buildProgressResults(),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    return SingleChildScrollView(
      padding: DesktopConstants.contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolsHeader(),
          const SizedBox(height: 16),
          _buildLanguageTemplateCard(),
          const SizedBox(height: 16),
          _buildExportImportCard(),
          const SizedBox(height: 16),
          _buildCommonLanguagesCard(),
        ],
      ),
    );
  }

  Widget _buildValidationHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Translation Validation',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Validates translation completeness, parameter consistency, and identifies missing or extra keys across all supported languages.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isValidating ? null : _validateTranslations,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Validation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Translation Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Shows completion status and statistics for all supported languages.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Colors.orange[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Translation Tools',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Utilities for managing translations, generating templates, and adding new languages.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationResults() {
    final report = _validationReport!;

    return Column(
      children: [
        // Status Card
        Card(
          color: report.isValid ? Colors.green[50] : Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  report.isValid ? Icons.check_circle : Icons.error,
                  color: report.isValid ? Colors.green[600] : Colors.red[600],
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.isValid ? 'All Valid' : 'Issues Found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: report.isValid
                              ? Colors.green[800]
                              : Colors.red[800],
                        ),
                      ),
                      Text(
                        report.summary,
                        style: TextStyle(
                          color: report.isValid
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Issues Details
        if (report.hasIssues) ...[
          if (report.errors.isNotEmpty) _buildErrorsCard(report.errors),
          if (report.missingKeys.isNotEmpty)
            _buildMissingKeysCard(report.missingKeys),
          if (report.extraKeys.isNotEmpty)
            _buildExtraKeysCard(report.extraKeys),
          if (report.emptyKeys.isNotEmpty)
            _buildEmptyKeysCard(report.emptyKeys),
          if (report.parameterMismatches.isNotEmpty)
            _buildParameterMismatchesCard(report.parameterMismatches),
        ],
      ],
    );
  }

  Widget _buildProgressResults() {
    final progress = _progressReport!;

    return Column(
      children: progress.entries.map((entry) {
        final languageCode = entry.key;
        final status = entry.value;
        final config = LanguageHelper.commonLanguages[languageCode];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status.completionPercentage),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          languageCode.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config?.nativeName ?? languageCode.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            status.statusDescription,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(status.completionPercentage * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: _getStatusColor(status.completionPercentage),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: status.completionPercentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                      _getStatusColor(status.completionPercentage)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${status.translatedKeys}/${status.totalKeys} keys translated',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (status.missingKeys.isNotEmpty ||
                    status.emptyKeys.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (status.missingKeys.isNotEmpty)
                        Chip(
                          label: Text('${status.missingKeys.length} missing'),
                          backgroundColor: Colors.orange[100],
                          labelStyle: TextStyle(
                              color: Colors.orange[800], fontSize: 11),
                        ),
                      if (status.emptyKeys.isNotEmpty)
                        Chip(
                          label: Text('${status.emptyKeys.length} empty'),
                          backgroundColor: Colors.red[100],
                          labelStyle:
                              TextStyle(color: Colors.red[800], fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 1.0) return Colors.green[600]!;
    if (percentage >= 0.8) return Colors.blue[600]!;
    if (percentage >= 0.5) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  Widget _buildErrorsCard(List<String> errors) {
    return _buildIssueCard(
      'Errors',
      Icons.error,
      Colors.red,
      errors.map((e) => Text(e, style: const TextStyle(fontSize: 12))).toList(),
    );
  }

  Widget _buildMissingKeysCard(Map<String, List<String>> missingKeys) {
    return _buildIssueCard(
      'Missing Keys',
      Icons.key_off,
      Colors.orange,
      missingKeys.entries.map((entry) {
        return ExpansionTile(
          title: Text('${entry.key} (${entry.value.length} keys)'),
          children: entry.value
              .take(10)
              .map(
                (key) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(key,
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace')),
                  ),
                ),
              )
              .toList(),
        );
      }).toList(),
    );
  }

  Widget _buildExtraKeysCard(Map<String, List<String>> extraKeys) {
    return _buildIssueCard(
      'Extra Keys',
      Icons.add_circle,
      Colors.blue,
      extraKeys.entries.map((entry) {
        return ExpansionTile(
          title: Text('${entry.key} (${entry.value.length} keys)'),
          children: entry.value
              .take(10)
              .map(
                (key) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(key,
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace')),
                  ),
                ),
              )
              .toList(),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyKeysCard(Map<String, List<String>> emptyKeys) {
    return _buildIssueCard(
      'Empty Keys',
      Icons.remove_circle,
      Colors.purple,
      emptyKeys.entries.map((entry) {
        return ExpansionTile(
          title: Text('${entry.key} (${entry.value.length} keys)'),
          children: entry.value
              .take(10)
              .map(
                (key) => Padding(
                  padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(key,
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace')),
                  ),
                ),
              )
              .toList(),
        );
      }).toList(),
    );
  }

  Widget _buildParameterMismatchesCard(
      Map<String, Map<String, ParameterMismatch>> mismatches) {
    return _buildIssueCard(
      'Parameter Mismatches',
      Icons.warning,
      Colors.amber,
      mismatches.entries.map((entry) {
        return ExpansionTile(
          title: Text('${entry.key} (${entry.value.length} mismatches)'),
          children: entry.value.entries.map((mismatch) {
            final key = mismatch.key;
            final params = mismatch.value;
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                  Text('  Reference: {${params.reference.join(', ')}}',
                      style: const TextStyle(
                          fontSize: 10, fontFamily: 'monospace')),
                  Text('  Target: {${params.target.join(', ')}}',
                      style: const TextStyle(
                          fontSize: 10, fontFamily: 'monospace')),
                ],
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildIssueCard(
      String title, IconData icon, MaterialColor color, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: color[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTemplateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate Language Template',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a template file for a new language based on the English reference.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showLanguageTemplateDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Generate Template'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportImportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export / Import',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Export translations for external editing or import completed translations.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _exportTranslations(),
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _importTranslations(),
                  icon: const Icon(Icons.upload),
                  label: const Text('Import'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonLanguagesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Common Languages',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Quick setup for commonly requested languages.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  LanguageHelper.commonLanguages.values.take(10).map((config) {
                return ActionChip(
                  label: Text('${config.nativeName} (${config.code})'),
                  onPressed: () => _setupLanguage(config),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String languageCode = '';
        return AlertDialog(
          title: const Text('Generate Language Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Language Code (e.g., es, fr, de)',
                  hintText: 'Enter ISO 639-1 language code',
                ),
                onChanged: (value) => languageCode = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (languageCode.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _generateLanguageTemplate(languageCode);
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateLanguageTemplate(String languageCode) async {
    try {
      final template =
          await LanguageHelper.generateLanguageTemplate(languageCode);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Template generated for $languageCode with ${template.keys.length} keys',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportTranslations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _importTranslations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality would be implemented here'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _setupLanguage(LanguageConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Setup ${config.nativeName}'),
        content: Text(
            'Would you like to generate a template for ${config.nativeName} (${config.code})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateLanguageTemplate(config.code);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}
