import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repository.dart';

class QuranDiagnosticScreen extends StatefulWidget {
  final QuranRepository quranRepository;

  const QuranDiagnosticScreen({
    super.key,
    required this.quranRepository,
  });

  @override
  State<QuranDiagnosticScreen> createState() => _QuranDiagnosticScreenState();
}

class _QuranDiagnosticScreenState extends State<QuranDiagnosticScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _diagnosticResults = {};
  String _mainIssue = "Running diagnostics...";
  String _solution = "";

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    try {
      setState(() {
        _isLoading = true;
        _mainIssue = "Running diagnostics...";
      });

      final results = await widget.quranRepository.runComprehensiveDiagnostics();

      String issue = "Unknown issue";
      String solution = "Please contact support.";

      switch(results['diagnosis']) {
        case 'MISSING_ASSET_FILES':
          issue = "Missing Asset Files";
          solution = "Required Quran data files are missing from your app's assets.\n\n"
              "Make sure the following files exist in assets/data/ directory and are correctly included in pubspec.yaml:\n"
              "• arabic_quran.json\n"
              "• sq_ahmeti.json\n"
              "• sq_mehdiu.json\n"
              "• sq_nahi.json\n"
              "• transliterations.json";
          break;
        case 'JSON_FORMAT_ERROR':
          issue = "Invalid JSON Format";
          solution = "Your Quran data files exist but have incorrect format.\n\n"
              "Each JSON file should have a top-level 'quran' key containing an array of surah objects.\n\n"
              "Check the JSON structure and fix any formatting errors.";
          break;
        case 'DATA_LOADED':
          issue = "Data appears to be loaded correctly";
          solution = "Your Quran files are loading, but specific surahs might have issues. "
              "Check that each surah in your JSON files has the correct structure with all required fields.";
          break;
      }

      setState(() {
        _isLoading = false;
        _diagnosticResults = results;
        _mainIssue = issue;
        _solution = solution;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mainIssue = "Error during diagnostics";
        _solution = "An unexpected error occurred: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Troubleshooter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
            tooltip: 'Run diagnostics again',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Issue summary card
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: _getColorForIssue(_mainIssue),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Main Issue:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _mainIssue,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Recommended Solution:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_solution),
                        ],
                      ),
                    ),
                  ),

                  // Diagnostic details
                  const Text(
                    'Diagnostic Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDiagnosticDetails(),
                ],
              ),
            ),
    );
  }

  Widget _buildDiagnosticDetails() {
    if (_diagnosticResults.isEmpty) {
      return const Text('No diagnostic data available.');
    }

    final assetResults = _diagnosticResults['assets'] as Map<String, dynamic>?;
    final serviceStatus = _diagnosticResults['service_status'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Asset files check
        const Text('Asset Files Check:', style: TextStyle(fontWeight: FontWeight.bold)),
        if (assetResults != null) ...[
          for (final key in assetResults.keys)
            if (key.startsWith('exists_'))
              Text('${key.substring(7)}: ${assetResults[key] ? '✅ Found' : '❌ Missing'}'),
        ] else
          const Text('Asset check results not available'),

        const SizedBox(height: 16),

        // Service status
        const Text('Quran Service Status:', style: TextStyle(fontWeight: FontWeight.bold)),
        if (serviceStatus != null) ...[
          Text('Arabic Quran loaded: ${serviceStatus['arabic_quran_loaded'] ? '✅ Yes' : '❌ No'}'),
          Text('Number of surahs available: ${serviceStatus['arabic_surah_count']}'),
          Text('Has loading errors: ${serviceStatus['has_error'] ? '❌ Yes' : '✅ No'}'),
          if (serviceStatus['has_error'] == true)
            Text('Error message: ${serviceStatus['error_message']}'),
        ] else
          const Text('Service status not available'),
      ],
    );
  }

  Color _getColorForIssue(String issue) {
    if (issue.contains('Missing')) {
      return Colors.red.shade100;
    } else if (issue.contains('Invalid')) {
      return Colors.orange.shade100;
    } else if (issue.contains('correctly')) {
      return Colors.green.shade100;
    } else {
      return Colors.blue.shade100;
    }
  }
}
