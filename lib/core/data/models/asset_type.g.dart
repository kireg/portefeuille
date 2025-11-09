// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetTypeAdapter extends TypeAdapter<AssetType> {
  @override
  final int typeId = 8;

  @override
  AssetType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AssetType.Stock;
      case 1:
        return AssetType.ETF;
      case 2:
        return AssetType.Crypto;
      case 3:
        return AssetType.Bond;
      case 4:
        return AssetType.Other;
      case 5:
        return AssetType.Cash;
      default:
        return AssetType.Stock;
    }
  }

  @override
  void write(BinaryWriter writer, AssetType obj) {
    switch (obj) {
      case AssetType.Stock:
        writer.writeByte(0);
        break;
      case AssetType.ETF:
        writer.writeByte(1);
        break;
      case AssetType.Crypto:
        writer.writeByte(2);
        break;
      case AssetType.Bond:
        writer.writeByte(3);
        break;
      case AssetType.Other:
        writer.writeByte(4);
        break;
      case AssetType.Cash:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
