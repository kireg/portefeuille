// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 12;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.synced;
      case 1:
        return SyncStatus.error;
      case 2:
        return SyncStatus.manual;
      case 3:
        return SyncStatus.never;
      case 4:
        return SyncStatus.unsyncable;
      case 5:
        return SyncStatus.pendingValidation;
      default:
        return SyncStatus.synced;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.synced:
        writer.writeByte(0);
        break;
      case SyncStatus.error:
        writer.writeByte(1);
        break;
      case SyncStatus.manual:
        writer.writeByte(2);
        break;
      case SyncStatus.never:
        writer.writeByte(3);
        break;
      case SyncStatus.unsyncable:
        writer.writeByte(4);
        break;
      case SyncStatus.pendingValidation:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
