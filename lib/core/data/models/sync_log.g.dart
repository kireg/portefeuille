// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncLogAdapter extends TypeAdapter<SyncLog> {
  @override
  final int typeId = 13;

  @override
  SyncLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncLog(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      ticker: fields[2] as String,
      status: fields[3] as SyncStatus,
      message: fields[4] as String,
      source: fields[5] as String?,
      price: fields[6] as double?,
      currency: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncLog obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.ticker)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.message)
      ..writeByte(5)
      ..write(obj.source)
      ..writeByte(6)
      ..write(obj.price)
      ..writeByte(7)
      ..write(obj.currency);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
