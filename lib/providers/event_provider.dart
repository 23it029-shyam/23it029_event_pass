import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/local_storage_service.dart';

final storageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final eventsProvider = StateNotifierProvider<EventsNotifier, List<EventModel>>((ref) {
  return EventsNotifier(ref.read(storageServiceProvider));
});

class EventsNotifier extends StateNotifier<List<EventModel>> {
  final LocalStorageService _storageService;

  EventsNotifier(this._storageService) : super([]) {
    loadEvents();
  }

  void loadEvents() {
    state = _storageService.getAllEvents();
  }

  Future<void> addEvent(EventModel event) async {
    await _storageService.saveEvent(event);
    loadEvents();
  }

  Future<void> deleteEvent(String id) async {
    await _storageService.deleteEvent(id);
    loadEvents();
  }
}
