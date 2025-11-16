// lib/core/data/services/sync_log_export_service.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';

class SyncLogExportService {
  /// Exporte les logs de synchronisation en CSV
  static String logsToCSV(List<SyncLog> logs) {
    final buffer = StringBuffer();

    // En-têtes
    buffer.writeln('Horodatage,Ticker,Statut,Message,Source API');

    // Données
    for (final log in logs) {
      final timestamp = log.timestamp.toIso8601String();
      final ticker = _escapeCsv(log.ticker);
      final status = log.status.displayName;
      final message = _escapeCsv(log.message);
      final source = _escapeCsv(log.source ?? 'N/A');

      buffer.writeln('$timestamp,$ticker,$status,$message,$source');
    }

    return buffer.toString();
  }

  /// Échappe les caractères spéciaux CSV
  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Sauvegarde les logs dans un fichier et retourne le chemin
  static Future<String> saveLogsToFile(List<SyncLog> logs) async {
    final csv = logsToCSV(logs);

    // Obtenir le répertoire de téléchargement
    final directory = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();

    // Créer un nom de fichier avec timestamp
    final now = DateTime.now();
    final filename =
        'sync_logs_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

    final file = File('${directory.path}/$filename');
    await file.writeAsString(csv);

    return file.path;
  }
}
