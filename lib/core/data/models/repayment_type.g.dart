// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repayment_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepaymentTypeAdapter extends TypeAdapter<RepaymentType> {
  @override
  final int typeId = 14;

  @override
  RepaymentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepaymentType.InFine;
      case 1:
        return RepaymentType.MonthlyInterest;
      case 2:
        return RepaymentType.Amortizing;
      default:
        return RepaymentType.InFine;
    }
  }

  @override
  void write(BinaryWriter writer, RepaymentType obj) {
    switch (obj) {
      case RepaymentType.InFine:
        writer.writeByte(0);
        break;
      case RepaymentType.MonthlyInterest:
        writer.writeByte(1);
        break;
      case RepaymentType.Amortizing:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepaymentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
