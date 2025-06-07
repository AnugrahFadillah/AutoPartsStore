// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sparepart.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SparepartAdapter extends TypeAdapter<Sparepart> {
  @override
  final int typeId = 1;

  @override
  Sparepart read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sparepart(
      id: fields[0] as String,
      name: fields[1] as String,
      brand: fields[2] as String,
      price: fields[3] as double,
      stock: fields[4] as int,
      description: fields[5] as String?,
      imageUrl: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Sparepart obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brand)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.stock)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SparepartAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
