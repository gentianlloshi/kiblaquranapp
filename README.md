# Kibla Quran App

A comprehensive Islamic prayer application in Albanian language with Qibla direction, prayer times, duas, mosque finder, and Quran reader functionality.

## Features

- **Qibla Direction**: Find the direction of the Kaaba from your current location
  - Works offline with fallback to default Albanian location
  - Compass calibration for accurate readings
- **Prayer Times**: Get accurate prayer times based on your location with notifications
  - Multiple calculation methods supported
  - Automatic fallback to Albanian location when GPS unavailable
- **Duas (Islamic Supplications)**: Collection of Islamic supplications in Albanian
- **Mosque Finder**: Locate nearby mosques using Google Maps integration
- **Quran Reader**: Read the Quran with Arabic text, transliteration, and translation
  - Audio playback of individual verses
  - Sequential surah playback with auto-scrolling and highlighting
  - Favorite marking functionality
  - Share verses with others
  - Toggle display options (Arabic, transliteration, translation)
  - Advanced transliteration with proper diacritical marks
  - Multiple Albanian translations supported

## Recent Updates

### Version 1.3.0 (June 2025)
- **Enhanced Quran Audio Playback**: Added sequential surah playback with auto-scrolling
- **Improved Audio Experience**: Fixed audio playback issues and added better transitions
- **UI Enhancements**: Added highlighting for currently playing ayah
- **Localization Updates**: Complete Albanian localization for all Quran features

### Version 1.2.0 (June 2025)
- **Complete Albanian Localization**: All UI elements now available in Albanian
- **Enhanced Transliteration**: Improved Arabic transliteration with proper diacritical marks
- **Resilient Location Services**: Added fallback mechanisms for location-based features
- **UI Improvements**: Fixed bottom navigation bar display issues
- **Error Handling**: Better handling of edge cases and missing data
- **Performance Optimizations**: Improved app loading and response times

## Technology Stack

The application is built with Flutter and follows a clean architecture approach with:

- **State Management**: Provider pattern and Flutter Bloc
- **Navigation**: Go Router
- **Local Storage**: Shared Preferences, SQLite, Path Provider
- **Geolocation & Compass**: Geolocator, Flutter Compass, Geocoding
- **Maps**: Google Maps Flutter
- **Islamic-specific packages**: Hijri (Islamic calendar), Adhan (Prayer calculations)
- **Notifications**: Flutter Local Notifications
- **Media**: Audio Players, Just Audio, Share Plus
- **UI Components**: Flutter SVG, Cached Network Image, Shimmer, Flutter Spinkit

## Project Structure

```
lib/
├── config/         # App configuration, themes, routes
├── data/           # Data layer
│   ├── models/     # Data models
│   ├── repositories/ # Repository classes
│   └── services/   # Service classes
├── presentation/   # UI layer
│   ├── screens/    # App screens
│   ├── widgets/    # Reusable widgets
│   └── providers/  # State management
└── utils/          # Utility classes including translations
```

## Getting Started

1. Ensure you have Flutter installed on your machine
2. Clone the repository
3. Install dependencies:
   ```
   flutter pub get
   ```
4. Run the app:
   ```
   flutter run
   ```

## Building Release

To build a release APK:

```
flutter build apk --release
```

The release APK will be available at `build/app/outputs/flutter-apk/app-release.apk`.

## Languages

The application supports:
- Albanian (primary)
- English (partial support)

## License

[Add appropriate license information]
