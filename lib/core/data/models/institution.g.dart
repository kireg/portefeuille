// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'institution.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstitutionAdapter extends TypeAdapter<Institution> {
  @override
  final int typeId = 1;

  @override
  Institution read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Institution(
      name: fields[0] as String,
      accounts: (fields[1] as List).cast<Account>(),
    );
  }

  @override
  void write(BinaryWriter writer, Institution obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.accounts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstitutionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
