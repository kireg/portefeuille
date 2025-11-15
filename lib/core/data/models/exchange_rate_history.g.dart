// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exchange_rate_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExchangeRateHistoryAdapter extends TypeAdapter<ExchangeRateHistory> {
  @override
  final int typeId = 11;

  @override
  ExchangeRateHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExchangeRateHistory(
      pair: fields[0] as String,
      date: fields[1] as DateTime,
      rate: fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ExchangeRateHistory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.pair)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.rate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExchangeRateHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
