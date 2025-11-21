// lib/core/data/services/sync_log_export_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; // Pour l'export cross-platform
import 'package:portefeuille/core/data/models/sync_log.dart';
import 'package:portefeuille/core/data/models/sync_status.dart';

class SyncLogExportService {
  /// Génère le CSV
  static String logsToCSV(List<SyncLog> logs) {
    final buffer = StringBuffer();
    buffer.writeln('Horodatage,Ticker,Statut,Message,Source API');

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

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Exporte les logs (Téléchargement sur Web, Partage sur Mobile)
  static Future<void> exportLogs(List<SyncLog> logs) async {
    final csvContent = logsToCSV(logs);
    final now = DateTime.now();
    final filename = 'sync_logs_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

    if (kIsWeb) {
      // --- VERSION WEB ---
      // Sur le web, on crée un XFile à partir des bytes et on "partage"
      // ce qui déclenche le téléchargement du fichier par le navigateur.
      final bytes = utf8.encode(csvContent);
      final xFile = XFile.fromData(
        Uint8List.fromList(bytes),
        mimeType: 'text/csv',
        name: filename,
      );

      // shareXFiles sur le web déclenche le téléchargement
      await Share.shareXFiles([xFile], subject: 'Export Logs Portefeuille');

    } else {
      // --- VERSION MOBILE / DESKTOP ---
      // On écrit dans un fichier temporaire puis on lance la sheet de partage native
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvContent);

      final xFile = XFile(file.path);

      // Ouvre la boite de dialogue native (Sauvegarder dans Fichiers, Email, Airdrop...)
      await Share.shareXFiles([xFile], subject: 'Export Logs Portefeuille');
    }
  }
}