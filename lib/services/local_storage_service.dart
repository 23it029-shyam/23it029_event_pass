import 'package:hive/hive.dart';
import '../models/event_model.dart';
import '../models/participant_model.dart';

class LocalStorageService {
  static const String _eventsBoxName = 'events';
  static const String _participantsBoxName = 'participants';

  Box<EventModel> get _eventsBox => Hive.box<EventModel>(_eventsBoxName);
  Box<ParticipantModel> get _participantsBox => Hive.box<ParticipantModel>(_participantsBoxName);

  // Events
  Future<void> saveEvent(EventModel event) async {
    await _eventsBox.put(event.id, event);
  }

  EventModel? getEvent(String id) {
    return _eventsBox.get(id);
  }

  List<EventModel> getAllEvents() {
    return _eventsBox.values.toList();
  }

  Future<void> deleteEvent(String id) async {
    await _eventsBox.delete(id);
    
    // Cascade delete participants
    final participantsToDelete = _participantsBox.values.where((p) => p.eventId == id).map((p) => p.id).toList();
    for (final pId in participantsToDelete) {
      await _participantsBox.delete(pId);
    }
  }

  // Participants
  Future<void> saveParticipant(ParticipantModel participant) async {
    await _participantsBox.put(participant.id, participant);
  }

  ParticipantModel? getParticipant(String id) {
    return _participantsBox.get(id);
  }

  List<ParticipantModel> getParticipantsByEvent(String eventId) {
    return _participantsBox.values.where((p) => p.eventId == eventId).toList();
  }

  Future<void> updateParticipant(ParticipantModel participant) async {
    await _participantsBox.put(participant.id, participant);
  }

  List<ParticipantModel> getPendingSyncParticipants() {
    return _participantsBox.values.where((p) => !p.syncedToCloud).toList();
  }

  int getCheckedInCount(String eventId) {
    return _participantsBox.values.where((p) => p.eventId == eventId && p.isCheckedIn).length;
  }
}
