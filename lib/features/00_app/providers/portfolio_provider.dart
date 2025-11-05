import 'package:flutter/material.dart';
import 'package:portefeuille/core/data/models/portfolio.dart';

import 'package:portefeuille/core/data/repositories/portfolio_repository.dart';

class PortfolioProvider extends ChangeNotifier {
  final PortfolioRepository _repository;
  Portfolio? _portfolio;

  Portfolio? get portfolio => _portfolio;

  // Le Repository est maintenant requis lors de la création du Provider
  PortfolioProvider({required PortfolioRepository repository})
      : _repository = repository {
    _loadPortfolio();
  }

  void _loadPortfolio() {
    // On utilise le repository pour charger
    _portfolio = _repository.loadPortfolio();
    // notifyListeners() n'est pas nécessaire ici, car le constructeur
    // est appelé avant que quiconque n'écoute.
  }

  void createDemoPortfolio() {
    // On utilise le repository
    _portfolio = _repository.createDemoPortfolio();
    notifyListeners();
  }

  void createEmptyPortfolio() {
    // On utilise le repository
    _portfolio = _repository.createEmptyPortfolio();
    notifyListeners();
  }

  void updatePortfolio(Portfolio portfolio) {
    _portfolio = portfolio;
    // On utilise le repository
    _repository.savePortfolio(_portfolio!);
    notifyListeners();
  }

  void clearPortfolio() {
    _portfolio = null;
    // On utilise le repository
    _repository.clearPortfolio();
    notifyListeners();
  }

// _savePortfolio() et _getDemoData() sont supprimés
// car c'est le travail du Repository.
}
