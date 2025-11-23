part of '../portfolio_provider.dart';

abstract class PortfolioState extends ChangeNotifier {
  final PortfolioRepository _repository;
  final ApiService _apiService;
  final Uuid _uuid;

  // Services
  late final MigrationService _migrationService;
  late final SyncService _syncService;
  late final TransactionService _transactionService;
  late final HydrationService _hydrationService;
  late final DemoDataService _demoDataService;
  late final BackupService _backupService;
  late final InstitutionService _institutionService;
  late final HistoryReconstructionService _historyService;

  // Settings
  SettingsProvider? _settingsProvider;
  bool _isFirstSettingsUpdate = true;

  // État
  List<Portfolio> _portfolios = [];
  Portfolio? _activePortfolio;
  bool _isLoading = true;
  BackgroundActivity _activity = const Idle();
  String? _syncMessage;
  
  // Cache pour optimisation O(1)
  final Map<String, Asset> _assetMap = {};

  // Getters - État brut
  List<Portfolio> get portfolios => _portfolios;
  Portfolio? get activePortfolio => _activePortfolio;
  bool get isLoading => _isLoading;
  BackgroundActivity get activity => _activity;
  bool get isProcessingInBackground => _activity.isActive;
  String? get syncMessage => _syncMessage;
  Map<String, AssetMetadata> get allMetadata =>
      _repository.getAllAssetMetadata();
  InstitutionService get institutionService => _institutionService;

  PortfolioState({
    required PortfolioRepository repository,
    required ApiService apiService,
    Uuid? uuid,
  })  : _repository = repository,
        _apiService = apiService,
        _uuid = uuid ?? const Uuid() {
    // Initialisation des services
    _migrationService = MigrationService(repository: _repository, uuid: _uuid);
    _historyService = HistoryReconstructionService();
    _syncService = SyncService(
      repository: _repository,
      apiService: _apiService,
      uuid: _uuid,
    );
    _transactionService = TransactionService(repository: _repository);
    _hydrationService = HydrationService(
      repository: _repository,
      apiService: _apiService,
    );
    _demoDataService = DemoDataService(repository: _repository, uuid: _uuid);
    _backupService = BackupService();
    _institutionService = InstitutionService();
    _institutionService.loadInstitutions(); // Chargement asynchrone (fire & forget)
  }

  // Abstract methods for cross-mixin communication
  Future<void> refreshData();
  Future<void> savePortfolio(Portfolio portfolio);
  void _rebuildAssetMap();
  Future<void> loadAllPortfolios();
  void _setActivity(BackgroundActivity activity) {
    _activity = activity;
  }
}
