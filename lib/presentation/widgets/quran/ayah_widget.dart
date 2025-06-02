import 'package:flutter/material.dart';

class AyahWidget extends StatelessWidget {
  final int ayahNumber;
  final String arabicText;
  final String translationText;
  final String transliterationText;
  final Function(int, int, String, String)? onShare;
  final int? surahNumber;
  final Function(int, int)? onPlayAudio;
  final Function(int, int)? onToggleFavorite;
  final bool showArabic;
  final bool showTransliteration;
  final bool showTranslation;

  const AyahWidget({
    super.key,
    required this.ayahNumber,
    required this.arabicText,
    required this.translationText,
    required this.transliterationText,
    this.onShare,
    this.surahNumber,
    this.onPlayAudio,
    this.onToggleFavorite,
    this.showArabic = true,
    this.showTransliteration = true,
    this.showTranslation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  child: Text(ayahNumber.toString()),
                ),
                Row(
                  children: [
                    if (onPlayAudio != null && surahNumber != null)
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => onPlayAudio!(surahNumber!, ayahNumber),
                        tooltip: 'Play Audio',
                      ),
                    if (onToggleFavorite != null && surahNumber != null)
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () => onToggleFavorite!(surahNumber!, ayahNumber),
                        tooltip: 'Add to Favorites',
                      ),
                    if (onShare != null)
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () => onShare!(
                          surahNumber ?? 0,
                          ayahNumber,
                          arabicText,
                          translationText,
                        ),
                        tooltip: 'Share',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (showArabic && arabicText.isNotEmpty) ...[
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  arabicText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: 'ScheherazadeNew',
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (showTransliteration && transliterationText.isNotEmpty) ...[
              Text(
                transliterationText,
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (showTranslation) ...[
              Text(
                translationText,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
