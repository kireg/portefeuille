// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 7;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      accountId: fields[1] as String,
      type: fields[2] as TransactionType,
      date: fields[3] as DateTime,
      amount: fields[8] as double,
      assetTicker: fields[4] as String?,
      assetName: fields[5] as String?,
      quantity: fields[6] as double?,
      price: fields[7] as double?,
      priceCurrency: fields[12] as String?,
      exchangeRate: fields[13] as double?,
      fees: fields[9] as double,
      notes: fields[10] as String,
      assetType: fields[11] as AssetType?,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.assetTicker)
      ..writeByte(5)
      ..write(obj.assetName)
      ..writeByte(6)
      ..write(obj.quantity)
      ..writeByte(7)
      ..write(obj.price)
      ..writeByte(8)
      ..write(obj.amount)
      ..writeByte(9)
      ..write(obj.fees)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.assetType)
      ..writeByte(12)
      ..write(obj.priceCurrency)
      ..writeByte(13)
      ..write(obj.exchangeRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
