// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetAdapter extends TypeAdapter<Asset> {
  @override
  final int typeId = 3;

  @override
  Asset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Asset(
      id: fields[6] as String,
      name: fields[0] as String,
      ticker: fields[1] as String,
      type: fields[7] as AssetType?,
      projectName: fields[9] as String?,
      location: fields[10] as String?,
      minDuration: fields[11] as int?,
      targetDuration: fields[12] as int?,
      maxDuration: fields[13] as int?,
      expectedYield: fields[14] as double?,
      repaymentType: fields[15] as RepaymentType?,
      riskRating: fields[16] as String?,
      staleQuantity: fields[2] as double?,
      staleAveragePrice: fields[3] as double?,
    )
      ..latitude = fields[17] as double?
      ..longitude = fields[18] as double?;
  }

  @override
  void write(BinaryWriter writer, Asset obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.ticker)
      ..writeByte(2)
      ..write(obj.staleQuantity)
      ..writeByte(3)
      ..write(obj.staleAveragePrice)
      ..writeByte(6)
      ..write(obj.id)
      ..writeByte(7)
      ..write(obj.type)
      ..writeByte(9)
      ..write(obj.projectName)
      ..writeByte(10)
      ..write(obj.location)
      ..writeByte(11)
      ..write(obj.minDuration)
      ..writeByte(12)
      ..write(obj.targetDuration)
      ..writeByte(13)
      ..write(obj.maxDuration)
      ..writeByte(14)
      ..write(obj.expectedYield)
      ..writeByte(15)
      ..write(obj.repaymentType)
      ..writeByte(16)
      ..write(obj.riskRating)
      ..writeByte(17)
      ..write(obj.latitude)
      ..writeByte(18)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
