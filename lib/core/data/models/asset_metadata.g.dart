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
      priceCurrency: fields[5] as String? ?? 'EUR', // Valeur par défaut
      estimatedAnnualYield: fields[2] as double,
      lastUpdated: fields[3] as DateTime?,
      isManualYield: fields[4] as bool,
      syncStatus:
          fields[6] as SyncStatus? ?? SyncStatus.never, // Valeur par défaut
      lastSyncAttempt: fields[7] as DateTime?,
      syncErrorMessage: fields[8] as String?,
      isin: fields[9] as String?,
      assetTypeDetailed: fields[10] as String?,
      lastSyncSource: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AssetMetadata obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.priceCurrency)
      ..writeByte(6)
      ..write(obj.syncStatus)
      ..writeByte(7)
      ..write(obj.lastSyncAttempt)
      ..writeByte(8)
      ..write(obj.syncErrorMessage)
      ..writeByte(9)
      ..write(obj.isin)
      ..writeByte(10)
      ..write(obj.assetTypeDetailed)
      ..writeByte(11)
      ..write(obj.lastSyncSource);
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
