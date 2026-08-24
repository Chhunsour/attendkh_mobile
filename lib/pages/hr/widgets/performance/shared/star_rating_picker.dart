import 'package:flutter/material.dart';
import 'package:mpg_hr_mobile_app/l10n/app_localizations.dart';
import 'package:mpg_hr_mobile_app/utils/theme/theme.dart';

class StarRatingPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const StarRatingPicker({super.key, required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.overallRatingPrefix.replaceAll(': ', ''),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey600,
                ),
              ),
              Text(
                rating > 0 ? '$rating / 5' : l10n.notRated,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: rating > 0 ? AppColors.warning : AppColors.grey400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFilled = starValue <= rating;
              return GestureDetector(
                onTap: () => onChanged(starValue == rating ? 0 : starValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFilled ? AppColors.warning : AppColors.grey400,
                    size: 28,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
