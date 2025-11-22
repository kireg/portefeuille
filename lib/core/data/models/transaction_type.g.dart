// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionTypeAdapter extends TypeAdapter<TransactionType> {
  @override
  final int typeId = 6;

  @override
  TransactionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionType.Deposit;
      case 1:
        return TransactionType.Withdrawal;
      case 2:
        return TransactionType.Buy;
      case 3:
        return TransactionType.Sell;
      case 4:
        return TransactionType.Dividend;
      case 5:
        return TransactionType.Interest;
      case 6:
        return TransactionType.Fees;
      case 8:
        return TransactionType.CapitalRepayment;
      case 9:
        return TransactionType.EarlyRepayment;
      default:
        return TransactionType.Deposit;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionType obj) {
    switch (obj) {
      case TransactionType.Deposit:
        writer.writeByte(0);
        break;
      case TransactionType.Withdrawal:
        writer.writeByte(1);
        break;
      case TransactionType.Buy:
        writer.writeByte(2);
        break;
      case TransactionType.Sell:
        writer.writeByte(3);
        break;
      case TransactionType.Dividend:
        writer.writeByte(4);
        break;
      case TransactionType.Interest:
        writer.writeByte(5);
        break;
      case TransactionType.Fees:
        writer.writeByte(6);
        break;
      case TransactionType.CapitalRepayment:
        writer.writeByte(8);
        break;
      case TransactionType.EarlyRepayment:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
