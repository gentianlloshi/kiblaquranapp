class Dua {
  final String id;
  final String title;
  final String category;
  final String? subcategory; // For morning/evening duas
  final String arabicText;
  final String transliteration;
  final String translation;
  final String reference;   // Source reference (e.g., Bukhari, Muslim, Quran)
  final String? audioUrl;   // URL to audio file (null if not available)
  final String? surah;      // Optional field for Quran verses
  final String? verse;      // Optional field for Quran verses

  Dua({
    required this.id,
    required this.title,
    required this.category,
    this.subcategory,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
    required this.reference,
    this.audioUrl,
    this.surah,
    this.verse,
  });

  // Factory constructor to create a Dua object from JSON
  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      subcategory: json['subcategory'],
      arabicText: json['arabic_text'],
      transliteration: json['transliteration'],
      translation: json['translation'],
      reference: json['reference'],
      audioUrl: json['audio_url'],
      surah: json['surah'],
      verse: json['verse'],
    );
  }

  // Convert a Dua object to a JSON object
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'subcategory': subcategory,
      'arabic_text': arabicText,
      'transliteration': transliteration,
      'translation': translation,
      'reference': reference,
      'audio_url': audioUrl,
      'surah': surah,
      'verse': verse,
    };
  }
}
