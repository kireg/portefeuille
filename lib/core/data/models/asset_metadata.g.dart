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
      priceCurrency: fields[5] as String?,
      estimatedAnnualYield: fields[2] as double,
      lastUpdated: fields[3] as DateTime?,
      isManualYield: fields[4] as bool,
      syncStatus: fields[6] as SyncStatus?,
      lastSyncAttempt: fields[7] as DateTime?,
      syncErrorMessage: fields[8] as String?,
      isin: fields[9] as String?,
      assetTypeDetailed: fields[10] as String?,
      lastSyncSource: fields[11] as String?,
      projectName: fields[13] as String?,
      location: fields[14] as String?,
      minDuration: fields[15] as int?,
      targetDuration: fields[16] as int?,
      maxDuration: fields[17] as int?,
      expectedYield: fields[18] as double?,
      repaymentType: fields[19] as RepaymentType?,
      riskRating: fields[20] as String?,
      latitude: fields[21] as double?,
      longitude: fields[22] as double?,
      pendingPrice: fields[23] as double?,
      pendingPriceCurrency: fields[24] as String?,
      pendingPriceSource: fields[25] as String?,
      pendingPriceDate: fields[26] as DateTime?,
    )..apiErrors = (fields[12] as Map?)?.cast<String, String>();
  }

  @override
  void write(BinaryWriter writer, AssetMetadata obj) {
    writer
      ..writeByte(27)
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
      ..write(obj.lastSyncSource)
      ..writeByte(12)
      ..write(obj.apiErrors)
      ..writeByte(13)
      ..write(obj.projectName)
      ..writeByte(14)
      ..write(obj.location)
      ..writeByte(15)
      ..write(obj.minDuration)
      ..writeByte(16)
      ..write(obj.targetDuration)
      ..writeByte(17)
      ..write(obj.maxDuration)
      ..writeByte(18)
      ..write(obj.expectedYield)
      ..writeByte(19)
      ..write(obj.repaymentType)
      ..writeByte(20)
      ..write(obj.riskRating)
      ..writeByte(21)
      ..write(obj.latitude)
      ..writeByte(22)
      ..write(obj.longitude)
      ..writeByte(23)
      ..write(obj.pendingPrice)
      ..writeByte(24)
      ..write(obj.pendingPriceCurrency)
      ..writeByte(25)
      ..write(obj.pendingPriceSource)
      ..writeByte(26)
      ..write(obj.pendingPriceDate);
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
