import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/event_provider.dart';
import '../providers/checkin_provider.dart';
import '../widgets/crowd_indicator.dart';
import '../widgets/stat_card.dart';
import '../widgets/participant_tile.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final String eventId;

  const DashboardScreen({super.key, required this.eventId});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.read(checkinProvider(widget.eventId).notifier).loadParticipants();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.read(checkinProvider(widget.eventId).notifier).loadParticipants();
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final event = events.firstWhere((e) => e.id == widget.eventId, orElse: () => throw Exception('Event not found'));
    final participants = ref.watch(checkinProvider(widget.eventId));
    
    final checkedInCount = participants.where((p) => p.isCheckedIn).length;
    final remainingCount = event.maxCapacity - checkedInCount;
    final pendingSyncCount = participants.where((p) => !p.syncedToCloud).length;

    final recentCheckins = participants.where((p) => p.isCheckedIn).toList()
      ..sort((a, b) => b.checkInTime?.compareTo(a.checkInTime ?? DateTime.now()) ?? 0);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.go('/checkin/${widget.eventId}'),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Check In', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              actions: [
                ActionChip(
                  label: Text(
                    pendingSyncCount == 0 ? 'Synced' : 'Pending $pendingSyncCount',
                    style: TextStyle(color: pendingSyncCount == 0 ? AppColors.success : AppColors.warning),
                  ),
                  avatar: Icon(
                    pendingSyncCount == 0 ? Icons.cloud_done : Icons.cloud_upload,
                    size: 16,
                    color: pendingSyncCount == 0 ? AppColors.success : AppColors.warning,
                  ),
                  backgroundColor: Colors.white,
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => context.go('/logs/${widget.eventId}'),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                title: Text(
                  event.name,
                  style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 24),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.calendar_today, 'Date', DateFormat('EEEE, MMM dd, yyyy').format(event.dateTime)),
                          const Divider(height: 24, color: AppColors.border),
                          _buildInfoRow(Icons.access_time, 'Time', DateFormat('hh:mm a').format(event.dateTime)),
                          const Divider(height: 24, color: AppColors.border),
                          _buildInfoRow(Icons.people, 'Max Capacity', '${event.maxCapacity} participants'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: StatCard(title: 'Registered', value: '${participants.length}', icon: Icons.how_to_reg)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(title: 'Checked In', value: '$checkedInCount', color: AppColors.secondary, icon: Icons.check_circle_outline)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(title: 'Remaining', value: '${remainingCount < 0 ? 0 : remainingCount}', color: remainingCount <= 0 ? AppColors.danger : null, icon: Icons.person_add_disabled)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CrowdIndicator(checkedIn: checkedInCount, maxCapacity: event.maxCapacity),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Check-ins', style: AppTextStyles.titleLarge),
                      TextButton(
                        onPressed: () => context.go('/logs/${widget.eventId}'),
                        child: const Text('View all →'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recentCheckins.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Text('No check-ins yet', style: AppTextStyles.bodyMedium),
                      ),
                    )
                  else
                    ...recentCheckins.take(5).map((p) => ParticipantTile(participant: p, showBorder: false)),
                  const SizedBox(height: 80), // space for FAB
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        Text(value, style: AppTextStyles.listTitle),
      ],
    );
  }
}
