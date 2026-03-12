import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_responsive_builder/the_responsive_builder.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dark,

      primaryColor: Colors.white12,
      cardColor: AppColors.light.withOpacity(0.7),
      dividerColor: Colors.white,
      hintColor: Colors.white,
      secondaryHeaderColor: AppColors.light,
      shadowColor: Colors.white,
      splashColor: Colors.white,
      canvasColor: Colors.grey.shade900,
    focusColor: Colors.white10,


    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStatePropertyAll(Colors.white),
        iconSize: WidgetStatePropertyAll(30)
      )
    ),
    textTheme: TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 24.sp,
      height: 1.5,
      fontWeight: FontWeight.bold,
    ),
     displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      height: 1.4,
     color: AppColors.light
    ),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 17.sp,
      fontWeight: FontWeight.bold,
     color: Colors.white
    ),

    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14.sp,
      fontWeight: FontWeight.bold,
     color: AppColors.light.withOpacity(0.8)
    
    ),

    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 13.sp,
      fontWeight: FontWeight.bold,
     color: AppColors.light.withOpacity(0.8)
    
    ),
      labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 17.sp,
      fontWeight: FontWeight.w500,
     color: AppColors.light.withOpacity(0.95)
    
    ),
    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
     color: AppColors.light.withOpacity(0.95)
    
    ),

  )
    );
  }

  static final light = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: Colors.white,
    hintColor: Colors.black,
    dividerColor: Colors.black,
    cardColor: AppColors.dark.withOpacity(0.9),
    canvasColor: Colors.grey.withOpacity(0.1),
    shadowColor: Colors.black,
     splashColor: Colors.black,
     focusColor: Colors.grey,
      secondaryHeaderColor: AppColors.dark,
      buttonTheme: ButtonThemeData(),
      iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconColor: WidgetStatePropertyAll(Colors.black),
        iconSize: WidgetStatePropertyAll(30)
      )
    ),
     textTheme: TextTheme(
    displayLarge: GoogleFonts.plusJakartaSans(
      fontSize: 24.sp,
      height: 1.5,
      fontWeight: FontWeight.bold,
    ),

    
     displayMedium: GoogleFonts.plusJakartaSans(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      height: 1.4,
     color: AppColors.dark
    ),
    displaySmall: GoogleFonts.plusJakartaSans(
      fontSize: 17.sp,
      fontWeight: FontWeight.bold,
     color: AppColors.dark
    ),

    labelMedium: GoogleFonts.plusJakartaSans(
      fontSize: 14.sp,
      fontWeight: FontWeight.bold,
     color: AppColors.dark.withOpacity(0.8)
    
    ),

     

    labelSmall: GoogleFonts.plusJakartaSans(
      fontSize: 13.sp,
      fontWeight: FontWeight.bold,
     color: AppColors.dark.withOpacity(0.8)
    
    ),
      labelLarge: GoogleFonts.plusJakartaSans(
      fontSize: 17.sp,
      fontWeight: FontWeight.w500,
     color: AppColors.dark.withOpacity(0.95)
    
    ),

    bodySmall: GoogleFonts.plusJakartaSans(
      fontSize: 15.sp,
      fontWeight: FontWeight.w500,
     color: AppColors.light.withOpacity(0.95)
    
    ),

  )
    
  );


}



class AppColors {
  static const Color primary = Color(0xFF8E2DE2);
  static const Color light = Color.fromARGB(255, 219, 215, 215);
  static const Color dark = Color(0xFF100C08);
  static const Color accent = Color(0xFF4A00E0);
}




    //  Color(0xFF8E2DE2),
    //           Color(0xFF4A00E0),



const _themeKey = 'theme_mode';

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey);

    if (index != null) {
      state = ThemeMode.values[index];
    }
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  void setLight() {
    state = ThemeMode.light;
    _saveTheme(state);
  }

  void setDark() {
    state = ThemeMode.dark;
    _saveTheme(state);
  }

  void setSystem() {
    state = ThemeMode.system;
    _saveTheme(state);
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>(
  (ref) => ThemeController(),
);


