import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_text_field.dart';

class EventSetupScreen extends ConsumerStatefulWidget {
  const EventSetupScreen({super.key});

  @override
  ConsumerState<EventSetupScreen> createState() => _EventSetupScreenState();
}

class _EventSetupScreenState extends ConsumerState<EventSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final newEvent = EventModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        dateTime: _selectedDate!,
        maxCapacity: int.parse(_capacityController.text.trim()),
      );

      ref.read(eventsProvider.notifier).addEvent(newEvent);

      _nameController.clear();
      _capacityController.clear();
      setState(() => _selectedDate = null);

      context.go('/dashboard/${newEvent.id}');
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a date and time'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _confirmDelete(String id) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.only(bottom: 32.0, top: 12, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Delete Event', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text('Are you sure? This will delete all check-in logs for this event.', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                ref.read(eventsProvider.notifier).deleteEvent(id);
                Navigator.pop(ctx);
              },
              child: const Text('Delete Event'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EventPass', style: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontSize: 20)),
                  Text('Manage your events', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primaryLight, fontSize: 12)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create New Event', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _nameController,
                              labelText: 'Event Name',
                              leadingIcon: const Icon(Icons.event, color: AppColors.textSecondary),
                              validator: (val) => val == null || val.length < 3 ? 'Minimum 3 characters' : null,
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: _pickDateTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _selectedDate == null
                                          ? Text('Select Date & Time', style: AppTextStyles.bodyMedium)
                                          : Chip(
                                              label: Text(DateFormat('MMM dd, yyyy - h:mm a').format(_selectedDate!), style: const TextStyle(color: AppColors.primaryDark)),
                                              backgroundColor: AppColors.primaryLight,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _capacityController,
                              labelText: 'Max Capacity',
                              keyboardType: TextInputType.number,
                              leadingIcon: const Icon(Icons.people, color: AppColors.textSecondary),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Required';
                                final number = int.tryParse(val);
                                if (number == null || number < 1) return 'Min 1';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryDark],
                                ),
                              ),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: _submit,
                                child: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Your Events', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (events.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_busy, size: 72, color: AppColors.primaryLight),
                    const SizedBox(height: 16),
                    Text('No events yet', style: AppTextStyles.titleLarge.copyWith(fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Create your first event above', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final event = events[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.go('/dashboard/${event.id}'),
                          onLongPress: () => _confirmDelete(event.id),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Text(
                                    event.name.isNotEmpty ? event.name[0].toUpperCase() : '?',
                                    style: AppTextStyles.displayLarge.copyWith(fontSize: 20, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(event.name, style: AppTextStyles.listTitle),
                                      const SizedBox(height: 4),
                                      Text(DateFormat('EEE, MMM d · h:mm a').format(event.dateTime), style: AppTextStyles.bodyMedium),
                                    ],
                                  ),
                                ),
                                Chip(
                                  label: Text('${event.maxCapacity}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                                  backgroundColor: AppColors.primaryLight,
                                  avatar: const Icon(Icons.people, size: 16, color: AppColors.primary),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, color: AppColors.border),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: events.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
