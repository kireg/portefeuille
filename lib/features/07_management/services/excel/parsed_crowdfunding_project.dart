import 'package:portefeuille/core/data/models/repayment_type.dart';

class ParsedCrowdfundingProject {
  final String projectName;
  final String platform;
  final DateTime? investmentDate;
  final double investedAmount;
  final double yieldPercent;
  final int durationMonths;
  final int? minDurationMonths;
  final int? maxDurationMonths;
  final RepaymentType repaymentType;
  final String? city;
  final String country;
  final String? riskRating;

  ParsedCrowdfundingProject({
    required this.projectName,
    required this.platform,
    this.investmentDate,
    required this.investedAmount,
    required this.yieldPercent,
    required this.durationMonths,
    this.minDurationMonths,
    this.maxDurationMonths,
    required this.repaymentType,
    this.city,
    this.country = 'France',
    this.riskRating,
  });

  @override
  String toString() {
    return 'ParsedCrowdfundingProject(name: $projectName, amount: $investedAmount, yield: $yieldPercent%, duration: $durationMonths m, type: $repaymentType)';
  }
}
