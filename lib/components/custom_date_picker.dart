import 'package:flutter/material.dart';
import 'package:attendkh/utils/theme/theme.dart';

Future<DateTime?> showCustomDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    builder: (context, child) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            onSurface: isDark ? AppColors.textPrimaryDark : AppColors.grey900,
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 10,
          ),
          datePickerTheme: DatePickerThemeData(
            headerBackgroundColor: AppColors.primary,
            headerForegroundColor: Colors.white,
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            dayStyle: const TextStyle(fontWeight: FontWeight.w600),
            todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
              cancelButtonStyle: TextButton.styleFrom(
                foregroundColor: isDark ? AppColors.grey300 : AppColors.grey600,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        child: child!,
      );
    },
  );
}
