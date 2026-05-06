import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/checkin_provider.dart';
import '../models/participant_model.dart';
import '../widgets/participant_tile.dart';
import '../widgets/empty_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LogsScreen extends ConsumerStatefulWidget {
  final String eventId;
  const LogsScreen({super.key, required this.eventId});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _newestFirst = true;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = val.toLowerCase());
    });
  }

  void _exportLogs() {
    final participants = ref.read(checkinProvider(widget.eventId));
    final checkedIn = participants.where((p) => p.isCheckedIn).toList();
    
    final summary = checkedIn.map((p) => '${p.name} (${p.id}) - ${p.checkInTime}').join('\n');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Export Logs', style: AppTextStyles.titleLarge),
        content: SingleChildScrollView(
          child: SelectableText(
            summary.isEmpty ? 'No data to export' : summary,
            style: AppTextStyles.mono.copyWith(color: AppColors.textPrimary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summary));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  String _getDateHeader(DateTime? date) {
    if (date == null) return 'Unknown';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);
    
    if (checkDate == today) return 'Today';
    if (checkDate == yesterday) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(checkDate);
  }

  @override
  Widget build(BuildContext context) {
    final participants = ref.watch(checkinProvider(widget.eventId));
    
    var filtered = participants.where((p) => p.isCheckedIn && (p.name.toLowerCase().contains(_searchQuery) || p.id.toLowerCase().contains(_searchQuery))).toList();

    filtered.sort((a, b) {
      if (a.checkInTime == null || b.checkInTime == null) return 0;
      return _newestFirst ? b.checkInTime!.compareTo(a.checkInTime!) : a.checkInTime!.compareTo(b.checkInTime!);
    });

    // Group by date
    final Map<String, List<ParticipantModel>> grouped = {};
    for (var p in filtered) {
      final header = _getDateHeader(p.checkInTime);
      grouped.putIfAbsent(header, () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportLogs,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search by name or ID',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${filtered.length} Results', style: AppTextStyles.bodyMedium),
                InkWell(
                  onTap: () => setState(() => _newestFirst = !_newestFirst),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_newestFirst ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(_newestFirst ? 'Newest first' : 'Oldest first', key: ValueKey(_newestFirst), style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.event_note,
                    title: 'No logs found',
                    subtitle: 'Check-in participants to see them appear in the logs here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: grouped.keys.length,
                    itemBuilder: (ctx, i) {
                      final date = grouped.keys.elementAt(i);
                      final items = grouped[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(date, style: AppTextStyles.labelSmall),
                          ),
                          Card(
                            child: Column(
                              children: [
                                for (int j = 0; j < items.length; j++) ...[
                                  ParticipantTile(participant: items[j]),
                                  if (j < items.length - 1) const Divider(height: 1, indent: 72, color: AppColors.border),
                                ]
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
