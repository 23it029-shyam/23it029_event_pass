import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'local_storage_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final LocalStorageService _storageService = LocalStorageService();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Function(int)? onSyncComplete;

  void initialize(BuildContext context) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _syncData();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> _syncData() async {
    final pendingParticipants = _storageService.getPendingSyncParticipants();
    if (pendingParticipants.isEmpty) return;

    // Mock cloud upload
    // FirebaseFirestore.instance.collection('participants').add(...)
    
    await Future.delayed(const Duration(seconds: 1)); // Simulate network request

    int syncedCount = 0;
    for (var p in pendingParticipants) {
      final updated = p.copyWith(syncedToCloud: true);
      await _storageService.updateParticipant(updated);
      syncedCount++;
    }

    if (syncedCount > 0 && onSyncComplete != null) {
      onSyncComplete!(syncedCount);
    }
  }
}
