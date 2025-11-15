// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetMetadataAdapter extends TypeAdapter<AssetMetadata> {
  @override
  final int typeId = 9;

  @override
  AssetMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetMetadata(
      ticker: fields[0] as String,
      currentPrice: fields[1] as double,
      priceCurrency: fields[5] as String,
      estimatedAnnualYield: fields[2] as double,
      lastUpdated: fields[3] as DateTime?,
      isManualYield: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AssetMetadata obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.ticker)
      ..writeByte(1)
      ..write(obj.currentPrice)
      ..writeByte(2)
      ..write(obj.estimatedAnnualYield)
      ..writeByte(3)
      ..write(obj.lastUpdated)
      ..writeByte(4)
      ..write(obj.isManualYield)
      ..writeByte(5)
      ..write(obj.priceCurrency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
