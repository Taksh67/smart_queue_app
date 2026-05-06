// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'queue_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QueueStateAdapter extends TypeAdapter<QueueState> {
  @override
  final int typeId = 1;

  @override
  QueueState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QueueState(
      currentToken: fields[0] as int,
      totalInQueue: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, QueueState obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.currentToken)
      ..writeByte(1)
      ..write(obj.totalInQueue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QueueStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
