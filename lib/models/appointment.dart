import 'package:hive/hive.dart';

part 'appointment.g.dart';

@HiveType(typeId: 0)
class Appointment extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String serviceType;

  @HiveField(3)
  final DateTime dateTime;

  @HiveField(4)
  String status; // e.g., 'waiting', 'in-service', 'completed', 'cancelled'

  @HiveField(5)
  int? queuePosition;

  @HiveField(6)
  bool isRescheduled;

  Appointment({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.dateTime,
    this.status = 'waiting',
    this.queuePosition,
    this.isRescheduled = false,
  });
}
