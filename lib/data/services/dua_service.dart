import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/dua.dart';

class DuaService {
  Future<List<Dua>> loadDuas() async {
    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/data/duas.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      // Convert each JSON item to a Dua object
      return jsonData.map((item) => Dua.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error loading duas from JSON: $e');
      // Return empty list or throw exception based on your error handling preference
      return [];
    }
  }
  
  Future<List<Dua>> loadAllahNames() async {
    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/data/allah_names.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      // Convert each JSON item to a Dua object with special category
      return jsonData.map((item) {
        final Map<String, dynamic> duaData = {
          ...item,
          'category': 'allah_names',
        };
        return Dua.fromJson(duaData);
      }).toList();
    } catch (e) {
      debugPrint('Error loading Allah names from JSON: $e');
      return [];
    }
  }
}
