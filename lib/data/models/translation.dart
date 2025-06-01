import 'surah.dart';

class Translation {
  final String translatorId;
  final Map<String, Surah> surahs;

  Translation({
    required this.translatorId,
    required this.surahs,
  });
}
