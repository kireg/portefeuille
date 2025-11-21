// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio_value_history_point.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PortfolioValueHistoryPointAdapter
    extends TypeAdapter<PortfolioValueHistoryPoint> {
  @override
  final int typeId = 20;

  @override
  PortfolioValueHistoryPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PortfolioValueHistoryPoint(
      date: fields[0] as DateTime,
      value: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, PortfolioValueHistoryPoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortfolioValueHistoryPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
