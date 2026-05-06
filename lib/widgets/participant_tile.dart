import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/participant_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ParticipantTile extends StatelessWidget {
  final ParticipantModel participant;
  final bool showBorder;

  const ParticipantTile({
    super.key,
    required this.participant,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final checkInTime = participant.checkInTime != null
        ? DateFormat('h:mm a').format(participant.checkInTime!)
        : '--:--';

    final initials = participant.name.trim().isNotEmpty
        ? participant.name.trim().split(' ').take(2).map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').join()
        : '?';

    // Generate a unique gradient based on name hash
    final hash = participant.name.hashCode;
    final colorOptions = [
      [AppColors.primary, AppColors.secondary],
      [AppColors.secondary, AppColors.success],
      [AppColors.warning, AppColors.danger],
      [AppColors.primaryDark, AppColors.primary],
    ];
    final gradientColors = colorOptions[hash.abs() % colorOptions.length];

    Widget content = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(initials, style: AppTextStyles.avatarInitials),
      ),
      title: Text(participant.name, style: AppTextStyles.listTitle),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(participant.id, style: AppTextStyles.mono),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: participant.isCheckedIn ? AppColors.success.withOpacity(0.1) : AppColors.textSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (participant.isCheckedIn) ...[
                  const Icon(Icons.check, size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                ],
                Text(
                  participant.isCheckedIn ? 'Checked In' : 'Pending',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: participant.isCheckedIn ? AppColors.success : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(checkInTime, style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
        ],
      ),
    );

    if (showBorder) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: content,
      );
    }

    return content;
  }
}
