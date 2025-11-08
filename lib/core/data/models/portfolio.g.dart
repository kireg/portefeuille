// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portfolio.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PortfolioAdapter extends TypeAdapter<Portfolio> {
  @override
  final int typeId = 0;

  @override
  Portfolio read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Portfolio(
      id: (fields[1] as String?) ??
          'portfolio-${DateTime.now().millisecondsSinceEpoch}',
      name: (fields[2] as String?) ?? 'Mon Portefeuille',
      institutions: (fields[0] as List).cast<Institution>(),
    );
  }

  @override
  void write(BinaryWriter writer, Portfolio obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.institutions)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PortfolioAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
