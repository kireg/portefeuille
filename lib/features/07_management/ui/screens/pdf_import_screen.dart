import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:portefeuille/features/07_management/services/pdf_import_service.dart';
import 'package:portefeuille/core/ui/theme/app_dimens.dart';
import 'package:portefeuille/core/ui/widgets/primitives/app_button.dart';

class PdfImportScreen extends StatefulWidget {
  const PdfImportScreen({super.key});

  @override
  State<PdfImportScreen> createState() => _PdfImportScreenState();
}

class _PdfImportScreenState extends State<PdfImportScreen> {
  final _pdfService = PdfImportService();
  List<ImportedTransaction> _extractedTransactions = [];
  bool _isLoading = false;
  String? _fileName;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isLoading = true;
        _fileName = result.files.single.name;
      });

      final file = File(result.files.single.path!);
      final transactions = await _pdfService.extractTransactions(file);

      setState(() {
        _extractedTransactions = transactions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import PDF')),
      body: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          children: [
            AppButton(
              label: 'Sélectionner un PDF',
              onPressed: _pickPdf,
              icon: Icons.upload_file,
            ),
            if (_fileName != null) ...[
              const SizedBox(height: AppDimens.paddingM),
              Text('Fichier: $_fileName'),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(AppDimens.paddingL),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: AppDimens.paddingL),
            Expanded(
              child: _extractedTransactions.isEmpty && !_isLoading && _fileName != null
                  ? const Center(child: Text("Aucune transaction trouvée."))
                  : ListView.builder(
                      itemCount: _extractedTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = _extractedTransactions[index];
                        return Card(
                          child: ListTile(
                            title: Text('${tx.type} ${tx.ticker}'),
                            subtitle: Text('${tx.quantity} @ ${tx.price} ${tx.currency}'),
                            trailing: Text(tx.date.toString().split(' ')[0]),
                          ),
                        );
                      },
                    ),
            ),
            if (_extractedTransactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppDimens.paddingL),
                child: AppButton(
                  label: 'Valider l\'import',
                  onPressed: () {
                    // TODO: Implement validation logic (Select Account -> Add to Provider)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité de validation à venir')),
                    );
                  },
                  icon: Icons.check,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
