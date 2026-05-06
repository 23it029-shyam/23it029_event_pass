import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/participant_model.dart';
import '../services/local_storage_service.dart';
import 'event_provider.dart';

final checkinProvider = StateNotifierProvider.family<CheckinNotifier, List<ParticipantModel>, String>((ref, eventId) {
  return CheckinNotifier(eventId, ref.read(storageServiceProvider));
});

class CheckinNotifier extends StateNotifier<List<ParticipantModel>> {
  final String eventId;
  final LocalStorageService _storageService;

  CheckinNotifier(this.eventId, this._storageService) : super([]) {
    loadParticipants();
  }

  void loadParticipants() {
    state = _storageService.getParticipantsByEvent(eventId);
  }

  Future<String?> checkInParticipant({required String participantId, required String participantName}) async {
    final event = _storageService.getEvent(eventId);
    if (event == null) return "Event not found";

    final existing = state.where((p) => p.id == participantId).toList();
    if (existing.isNotEmpty && existing.first.isCheckedIn) {
      return "Already checked in";
    }

    if (state.where((p) => p.isCheckedIn).length >= event.maxCapacity) {
      return "Event at full capacity";
    }

    final participant = existing.isNotEmpty
        ? existing.first.copyWith(
            isCheckedIn: true,
            checkInTime: DateTime.now(),
            syncedToCloud: false,
          )
        : ParticipantModel(
            id: participantId.isEmpty ? const Uuid().v4() : participantId,
            name: participantName,
            eventId: eventId,
            isCheckedIn: true,
            checkInTime: DateTime.now(),
            syncedToCloud: false,
          );

    await _storageService.saveParticipant(participant);
    loadParticipants();
    return null; // success
  }
}
