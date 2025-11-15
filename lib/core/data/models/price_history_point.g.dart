// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_history_point.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceHistoryPointAdapter extends TypeAdapter<PriceHistoryPoint> {
  @override
  final int typeId = 10;

  @override
  PriceHistoryPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceHistoryPoint(
      ticker: fields[0] as String,
      date: fields[1] as DateTime,
      price: fields[2] as double,
      currency: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PriceHistoryPoint obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.ticker)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceHistoryPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
