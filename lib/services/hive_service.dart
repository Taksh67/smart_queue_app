import 'package:hive_flutter/hive_flutter.dart';
import '../models/appointment.dart';
import '../models/queue_state.dart';

class HiveService {
  static const String appointmentBoxName = 'appointments';
  static const String queueStateBoxName = 'queue_state';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(AppointmentAdapter());
    Hive.registerAdapter(QueueStateAdapter());

    // Open Boxes
    await Hive.openBox<Appointment>(appointmentBoxName);
    await Hive.openBox<QueueState>(queueStateBoxName);
  }

  static Box<Appointment> getAppointmentBox() => Hive.box<Appointment>(appointmentBoxName);
  static Box<QueueState> getQueueStateBox() => Hive.box<QueueState>(queueStateBoxName);
}
