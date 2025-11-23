// lib/features/00_app/providers/portfolio_provider.dart

import 'package:flutter/material.dart';
import 'dart:convert'; // Pour jsonEncode
import 'package:portefeuille/core/data/services/backup_service.dart';
import 'package:portefeuille/core/data/models/account.dart';
import 'package:portefeuille/core/data/models/asset.dart';
import 'package:portefeuille/core/data/models/asset_metadata.dart';
import 'package:portefeuille/core/data/models/institution.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';
import 'package:portefeuille/core/data/models/savings_plan.dart';
import 'package:portefeuille/core/data/models/sync_log.dart';
import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';
import 'package:portefeuille/core/data/services/api_service.dart';
import 'package:portefeuille/features/00_app/providers/settings_provider.dart';
import 'package:portefeuille/features/00_app/models/background_activity.dart';
import 'package:portefeuille/features/00_app/services/demo_data_service.dart';
import 'package:portefeuille/features/00_app/services/hydration_service.dart';
import 'package:portefeuille/features/00_app/services/migration_service.dart';
import 'package:portefeuille/features/00_app/services/sync_service.dart';
import 'package:portefeuille/features/00_app/services/transaction_service.dart';
import 'package:portefeuille/features/00_app/services/institution_service.dart';
import 'package:portefeuille/features/00_app/services/history_reconstruction_service.dart';
import 'package:uuid/uuid.dart';

part 'portfolio_parts/portfolio_state.dart';
part 'portfolio_parts/portfolio_management.dart';
part 'portfolio_parts/portfolio_sync.dart';
part 'portfolio_parts/portfolio_institutions.dart';
part 'portfolio_parts/portfolio_assets.dart';

class PortfolioProvider extends PortfolioState
    with
        PortfolioManagement,
        PortfolioSync,
        PortfolioInstitutions,
        PortfolioAssets {
  PortfolioProvider({
    required super.repository,
    required super.apiService,
    super.uuid,
  }) {
    loadAllPortfolios();
  }
}