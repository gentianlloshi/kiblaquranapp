import 'package:flutter/material.dart';

class AppTheme {
  // Konstantet e ngjyrave
  static const Color primaryColor = Color(0xFF42A5F5); // Blu e çelët
  static const Color secondaryColor = Color(0xFF4CAF50); // E gjelbër
  static const Color textColor = Color(0xFF212121); // E zezë e errët
  static const Color secondaryTextColor = Color(0xFF757575); // Gri e errët
  static const Color backgroundColor = Color(0xFFFFFFFF); // E bardhë
  static const Color accentColor = Color(0xFF1976D2); // Blu e errët

  // Konstantet e ngjyrave për temën e errët
  static const Color darkPrimaryColor = Color(0xFF1976D2); // Blu e errët
  static const Color darkSecondaryColor = Color(0xFF388E3C); // E gjelbër e errët
  static const Color darkTextColor = Color(0xFFEEEEEE); // E bardhë e errët
  static const Color darkSecondaryTextColor = Color(0xFFBDBDBD); // Gri e çelët
  static const Color darkBackgroundColor = Color(0xFF121212); // E zezë
  static const Color darkAccentColor = Color(0xFF64B5F6); // Blu e çelët

  // Madhësitë e fontit
  static const double fontSizeSmall = 12.0;
  static const double fontSizeNormal = 14.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeExtraLarge = 24.0;

  // Faktorët e shkallëzimit të fontit
  static const double fontScaleSmall = 0.8;
  static const double fontScaleNormal = 1.0;
  static const double fontScaleLarge = 1.2;
  static const double fontScaleExtraLarge = 1.5;

  // Tema e çelët
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: backgroundColor,
    ),
    scaffoldBackgroundColor: backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryTextColor,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: fontSizeLarge * 1.5,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: fontSizeLarge,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSizeNormal,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeNormal,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: fontSizeSmall,
        color: secondaryTextColor,
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      buttonColor: primaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    iconTheme: const IconThemeData(
      color: primaryColor,
      size: 24,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0E0E0),
      thickness: 1,
    ),
  );

  // Tema e errët
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: darkPrimaryColor,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkSecondaryColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      surface: darkBackgroundColor,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: darkAccentColor,
      unselectedItemColor: darkSecondaryTextColor,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: fontSizeLarge * 1.5,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      displayMedium: TextStyle(
        fontSize: fontSizeLarge,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      displaySmall: TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: fontSizeMedium,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: fontSizeNormal,
        color: darkTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: fontSizeNormal,
        color: darkTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: fontSizeSmall,
        color: darkSecondaryTextColor,
      ),
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      buttonColor: darkPrimaryColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkAccentColor,
      ),
    ),
    iconTheme: const IconThemeData(
      color: darkAccentColor,
      size: 24,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF424242),
      thickness: 1,
    ),
  );

  // Metoda për të aplikuar shkallëzimin e fontit në temë
  static ThemeData getThemeWithFontScale(ThemeData baseTheme, double fontScale) {
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.copyWith(
        displayLarge: baseTheme.textTheme.displayLarge?.copyWith(
          fontSize: fontSizeLarge * 1.5 * fontScale,
        ),
        displayMedium: baseTheme.textTheme.displayMedium?.copyWith(
          fontSize: fontSizeLarge * fontScale,
        ),
        displaySmall: baseTheme.textTheme.displaySmall?.copyWith(
          fontSize: fontSizeMedium * fontScale,
        ),
        headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
          fontSize: fontSizeMedium * fontScale,
        ),
        titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
          fontSize: fontSizeMedium * fontScale,
        ),
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          fontSize: fontSizeNormal * fontScale,
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          fontSize: fontSizeNormal * fontScale,
        ),
        bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
          fontSize: fontSizeSmall * fontScale,
        ),
      ),
    );
  }
}
