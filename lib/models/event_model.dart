import 'package:hive/hive.dart';

class EventModel {
  final String id;
  final String name;
  final DateTime dateTime;
  final int maxCapacity;

  EventModel({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.maxCapacity,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dateTime': dateTime.toIso8601String(),
      'maxCapacity': maxCapacity,
    };
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      name: json['name'],
      dateTime: DateTime.parse(json['dateTime']),
      maxCapacity: json['maxCapacity'],
    );
  }
}

class EventModelAdapter extends TypeAdapter<EventModel> {
  @override
  final int typeId = 0;

  @override
  EventModel read(BinaryReader reader) {
    return EventModel(
      id: reader.readString(),
      name: reader.readString(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      maxCapacity: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, EventModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeInt(obj.dateTime.millisecondsSinceEpoch);
    writer.writeInt(obj.maxCapacity);
  }
}
