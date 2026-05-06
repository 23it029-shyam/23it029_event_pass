import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CrowdIndicator extends StatelessWidget {
  final int checkedIn;
  final int maxCapacity;

  const CrowdIndicator({
    super.key,
    required this.checkedIn,
    required this.maxCapacity,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = maxCapacity == 0 ? 0 : checkedIn / maxCapacity;
    final double safeRatio = ratio > 1.0 ? 1.0 : ratio;
    final double percentage = safeRatio * 100;

    Color color;
    String status;

    if (percentage <= 60) {
      color = AppColors.success;
      status = 'Safe';
    } else if (percentage <= 85) {
      color = AppColors.warning;
      status = 'Moderate';
    } else {
      color = AppColors.danger;
      status = 'Critical';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Crowd Status', style: AppTextStyles.listTitle),
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: percentage),
                  builder: (context, value, _) => Text(
                    '${value.toStringAsFixed(1)}%',
                    style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Base segmented track
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 60, child: Container(decoration: const BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.horizontal(left: Radius.circular(6))))),
                          Expanded(flex: 25, child: Container(color: AppColors.warning)),
                          Expanded(flex: 15, child: Container(decoration: const BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.horizontal(right: Radius.circular(6))))),
                        ],
                      ),
                    ),
                    // Animated sliding thumb
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: safeRatio),
                      builder: (context, value, _) {
                        return Positioned(
                          left: value * constraints.maxWidth - 6 < 0 ? 0 : (value * constraints.maxWidth - 12 > constraints.maxWidth - 12 ? constraints.maxWidth - 12 : value * constraints.maxWidth - 6),
                          top: -2,
                          child: Container(
                            width: 12,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.textPrimary, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: AppTextStyles.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
