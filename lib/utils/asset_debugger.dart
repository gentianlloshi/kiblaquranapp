// A utility class to debug and verify asset loading issues
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

class AssetDebugger {
  static const String _logTag = 'AssetDebugger';

  /// Check if an asset exists and can be loaded
  static Future<bool> assetExists(String path) async {
    try {
      await rootBundle.load(path);
      developer.log('✅ Asset found: $path', name: _logTag);
      return true;
    } catch (e) {
      developer.log('❌ Asset missing: $path', name: _logTag, error: e);
      return false;
    }
  }

  /// Check content of a text asset
  static Future<String> checkTextAsset(String path) async {
    try {
      final content = await rootBundle.loadString(path);
      developer.log('✅ Asset loaded: $path (${content.length} characters)', name: _logTag);

      if (content.isEmpty) {
        developer.log('⚠️ Warning: Asset is empty: $path', name: _logTag);
        return "ERROR: Empty file";
      }

      // Check if it's likely JSON by looking at the first character
      if (content.trim().startsWith('{') || content.trim().startsWith('[')) {
        developer.log('✅ Likely valid JSON format', name: _logTag);
      } else {
        developer.log('⚠️ Warning: Content may not be valid JSON', name: _logTag);
      }

      // Return first 100 characters for inspection
      return content.length > 100
          ? "${content.substring(0, 100)}..."
          : content;
    } catch (e) {
      developer.log('❌ Failed to load asset: $path', name: _logTag, error: e);
      return "ERROR: $e";
    }
  }

  /// Checks all Quran data assets and returns a diagnostic report
  static Future<Map<String, dynamic>> checkQuranAssets() async {
    final report = <String, dynamic>{};

    // Asset paths to check
    final quranAssets = [
      'assets/data/arabic_quran.json',
      'assets/data/sq_ahmeti.json',
      'assets/data/sq_mehdiu.json',
      'assets/data/sq_nahi.json',
      'assets/data/transliterations.json',
    ];

    // Check existence
    for (final path in quranAssets) {
      report['exists_${path.split('/').last}'] = await assetExists(path);
    }

    // Check content samples
    for (final path in quranAssets) {
      if (report['exists_${path.split('/').last}'] == true) {
        report['sample_${path.split('/').last}'] = await checkTextAsset(path);
      }
    }

    // Overall assessment
    report['all_assets_exist'] = !report.values.any((v) => v is bool && v == false);
    report['diagnosis'] = report['all_assets_exist']
        ? "All asset files exist. Check JSON format and content structure."
        : "Some required asset files are missing. Make sure all files are properly copied to the assets/data directory.";

    developer.log('📊 Asset Check Report: $report', name: _logTag);
    return report;
  }
}
