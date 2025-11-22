import 'package:hive/hive.dart';

part 'repayment_type.g.dart';

@HiveType(typeId: 14)
enum RepaymentType {
  @HiveField(0)
  InFine, // Capital + Intérêts à la fin

  @HiveField(1)
  MonthlyInterest, // Intérêts mensuels, Capital à la fin

  @HiveField(2)
  Amortizing, // Capital + Intérêts mensuels
}

extension RepaymentTypeExtension on RepaymentType {
  String get displayName {
    switch (this) {
      case RepaymentType.InFine:
        return 'In Fine';
      case RepaymentType.MonthlyInterest:
        return 'Intérêts Mensuels';
      case RepaymentType.Amortizing:
        return 'Amortissable';
    }
  }
}
