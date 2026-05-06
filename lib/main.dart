import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'models/event_model.dart';
import 'models/participant_model.dart';

// Application entry point initializing Hive and ProviderScope
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  Hive.registerAdapter(EventModelAdapter());
  Hive.registerAdapter(ParticipantModelAdapter());
  
  await Hive.openBox<EventModel>('events');
  await Hive.openBox<ParticipantModel>('participants');
  
  runApp(
    const ProviderScope(
      child: EventPassApp(),
    ),
  );
}
