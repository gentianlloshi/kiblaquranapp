import 'ayah.dart';

class Surah {
  final int number;
  final String name;
  final String englishName;
  final List<Ayah> ayahs;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.ayahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    List<Ayah> ayahsList = [];
    if (json['ayahs'] != null) {
      ayahsList = List<Ayah>.from(
        json['ayahs'].map((ayah) => Ayah.fromJson(ayah)),
      );
    }

    return Surah(
      number: json['number'],
      name: json['name'],
      englishName: json['englishName'],
      ayahs: ayahsList,
    );
  }
}
