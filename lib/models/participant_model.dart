import 'package:hive/hive.dart';

class ParticipantModel {
  final String id;
  final String name;
  final String eventId;
  final bool isCheckedIn;
  final DateTime? checkInTime;
  final bool syncedToCloud;

  ParticipantModel({
    required this.id,
    required this.name,
    required this.eventId,
    required this.isCheckedIn,
    this.checkInTime,
    required this.syncedToCloud,
  });

  ParticipantModel copyWith({
    String? id,
    String? name,
    String? eventId,
    bool? isCheckedIn,
    DateTime? checkInTime,
    bool? syncedToCloud,
  }) {
    return ParticipantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      eventId: eventId ?? this.eventId,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInTime: checkInTime ?? this.checkInTime,
      syncedToCloud: syncedToCloud ?? this.syncedToCloud,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'eventId': eventId,
      'isCheckedIn': isCheckedIn,
      'checkInTime': checkInTime?.toIso8601String(),
      'syncedToCloud': syncedToCloud,
    };
  }

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'],
      name: json['name'],
      eventId: json['eventId'],
      isCheckedIn: json['isCheckedIn'],
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      syncedToCloud: json['syncedToCloud'] ?? false,
    );
  }
}

class ParticipantModelAdapter extends TypeAdapter<ParticipantModel> {
  @override
  final int typeId = 1;

  @override
  ParticipantModel read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final eventId = reader.readString();
    final isCheckedIn = reader.readBool();
    final checkInTimeMillis = reader.readInt();
    final syncedToCloud = reader.readBool();
    
    return ParticipantModel(
      id: id,
      name: name,
      eventId: eventId,
      isCheckedIn: isCheckedIn,
      checkInTime: checkInTimeMillis == -1 ? null : DateTime.fromMillisecondsSinceEpoch(checkInTimeMillis),
      syncedToCloud: syncedToCloud,
    );
  }

  @override
  void write(BinaryWriter writer, ParticipantModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.eventId);
    writer.writeBool(obj.isCheckedIn);
    writer.writeInt(obj.checkInTime?.millisecondsSinceEpoch ?? -1);
    writer.writeBool(obj.syncedToCloud);
  }
}
