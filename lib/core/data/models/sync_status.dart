// lib/core/data/models/sync_status.dart

import 'package:hive/hive.dart';

part 'sync_status.g.dart';

/// Statut de synchronisation d'un actif
@HiveType(typeId: 12)
enum SyncStatus {
  @HiveField(0)
  synced, // Synchronisé avec succès

  @HiveField(1)
  error, // Erreur lors de la synchronisation

  @HiveField(2)
  manual, // Prix saisi manuellement (pas de synchro auto)

  @HiveField(3)
  never, // Jamais synchronisé (nouveau)

  @HiveField(4)
  unsyncable, // Non synchronisable (ex: fonds en euros)
}

extension SyncStatusExtension on SyncStatus {
  /// Nom d'affichage du statut
  String get displayName {
    switch (this) {
      case SyncStatus.synced:
        return 'Synchronisé';
      case SyncStatus.error:
        return 'Erreur';
      case SyncStatus.manual:
        return 'Manuel';
      case SyncStatus.never:
        return 'Non synchronisé';
      case SyncStatus.unsyncable:
        return 'Non synchronisable';
    }
  }

  /// Icône représentant le statut
  String get icon {
    switch (this) {
      case SyncStatus.synced:
        return '✅';
      case SyncStatus.error:
        return '⚠️';
      case SyncStatus.manual:
        return '✏️';
      case SyncStatus.never:
        return '⭕';
      case SyncStatus.unsyncable:
        return '🚫';
    }
  }

  /// Couleur associée (pour les badges)
  String get colorName {
    switch (this) {
      case SyncStatus.synced:
        return 'green';
      case SyncStatus.error:
        return 'red';
      case SyncStatus.manual:
        return 'blue';
      case SyncStatus.never:
        return 'grey';
      case SyncStatus.unsyncable:
        return 'grey';
    }
  }
}
