// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_plan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingsPlanAdapter extends TypeAdapter<SavingsPlan> {
  @override
  final int typeId = 5;

  @override
  SavingsPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsPlan(
      id: fields[0] as String,
      name: fields[1] as String,
      monthlyAmount: fields[2] as double,
      targetTicker: fields[3] as String,
      targetAssetName: fields[4] as String,
      estimatedAnnualReturn: fields[5] as double,
      isActive: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SavingsPlan obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.monthlyAmount)
      ..writeByte(3)
      ..write(obj.targetTicker)
      ..writeByte(4)
      ..write(obj.targetAssetName)
      ..writeByte(5)
      ..write(obj.estimatedAnnualReturn)
      ..writeByte(6)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
