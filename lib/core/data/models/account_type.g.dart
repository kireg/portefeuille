// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AccountTypeAdapter extends TypeAdapter<AccountType> {
  @override
  final int typeId = 4;

  @override
  AccountType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AccountType.pea;
      case 1:
        return AccountType.cto;
      case 2:
        return AccountType.assuranceVie;
      case 3:
        return AccountType.per;
      case 4:
        return AccountType.crypto;
      case 5:
        return AccountType.autre;
      default:
        return AccountType.pea;
    }
  }

  @override
  void write(BinaryWriter writer, AccountType obj) {
    switch (obj) {
      case AccountType.pea:
        writer.writeByte(0);
        break;
      case AccountType.cto:
        writer.writeByte(1);
        break;
      case AccountType.assuranceVie:
        writer.writeByte(2);
        break;
      case AccountType.per:
        writer.writeByte(3);
        break;
      case AccountType.crypto:
        writer.writeByte(4);
        break;
      case AccountType.autre:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
