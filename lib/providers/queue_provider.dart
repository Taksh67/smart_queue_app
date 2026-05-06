import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/appointment.dart';
import '../models/queue_state.dart';
import '../services/hive_service.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QueueProvider extends ChangeNotifier {
  final _appointmentBox = HiveService.getAppointmentBox();
  final _queueStateBox = HiveService.getQueueStateBox();
  final _firestore = FirestoreService();
  final _uuid = const Uuid();

  List<Appointment> get appointments => _appointmentBox.values.toList();

  Appointment? get latestActiveAppointment {
    final active = appointments.where((a) => a.status != 'completed' && a.status != 'cancelled').toList();
    if (active.isEmpty) return null;
    return active.last;
  }

  QueueState get queueState {
    if (_queueStateBox.isEmpty) {
      final newState = QueueState();
      _queueStateBox.put('current', newState);
      return newState;
    }
    return _queueStateBox.get('current')!;
  }

  String? bookAppointment({
    required String name,
    required String serviceType,
    required DateTime date,
    required String timeSlot,
    String? idOverride,
  }) {
    // 1. Validate fields (already done in UI but safety check)
    if (name.isEmpty || serviceType.isEmpty || timeSlot.isEmpty) {
      return 'Please fill all fields';
    }

    // 2. Check for past dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today)) {
      return 'Cannot book for a past date';
    }

    // 3. Parse timeSlot to DateTime for storage
    // Example timeSlot: "09:00 AM"
    final timeParts = timeSlot.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    int minute = int.parse(hourMinute[1]);
    if (timeParts[1] == 'PM' && hour != 12) hour += 12;
    if (timeParts[1] == 'AM' && hour == 12) hour = 0;

    final appointmentDateTime = DateTime(date.year, date.month, date.day, hour, minute);

    // 4. Check for conflicts (max 1 per slot)
    final existingInSlot = appointments.where((a) => a.dateTime == appointmentDateTime && a.status != 'cancelled').length;
    if (existingInSlot >= 1) {
      return 'Time slot is already booked';
    }

    // 5. Generate ID and Queue Position
    final id = idOverride ?? _uuid.v4();
    final nextPosition = queueState.totalInQueue + 1;

    final appointment = Appointment(
      id: id,
      name: name,
      serviceType: serviceType,
      dateTime: appointmentDateTime,
      queuePosition: nextPosition,
    );

    // 6. Save to Hive & Firestore
    _appointmentBox.add(appointment);
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _firestore.addAppointment(appointment, uid);
    }
    
    final state = queueState;
    state.totalInQueue++;
    state.save();
    
    notifyListeners();
    return null; // Success
  }

  int get totalAppointments => appointments.length;
  int get pendingCount => appointments.where((a) => a.status == 'waiting' || a.status == 'scheduled').length;

  Future<void> updateAppointmentStatus(String id, String newStatus) async {
    final index = appointments.indexWhere((a) => a.id == id);
    if (index != -1) {
      final appointment = _appointmentBox.getAt(index);
      if (appointment != null) {
        appointment.status = newStatus;
        appointment.save();
        
        // Sync with Firestore
        await _firestore.updateStatus(id, newStatus);
        
        notifyListeners();
      }
    }
  }

  Future<String?> rescheduleAppointment(String id, DateTime newDate, String timeSlot) async {
    // 1. Parse timeSlot
    final timeParts = timeSlot.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    int minute = int.parse(hourMinute[1]);
    if (timeParts[1] == 'PM' && hour != 12) hour += 12;
    if (timeParts[1] == 'AM' && hour == 12) hour = 0;

    final newDateTime = DateTime(newDate.year, newDate.month, newDate.day, hour, minute);

    // 2. Conflict check (max 3 per slot, excluding this appointment)
    final existingInSlot = appointments.where((a) => a.dateTime == newDateTime && a.id != id && a.status != 'cancelled').length;
    if (existingInSlot >= 1) {
      return 'Time slot is already booked';
    }

    // 3. Update
    final index = appointments.indexWhere((a) => a.id == id);
    if (index != -1) {
      final appointment = _appointmentBox.getAt(index);
      if (appointment != null) {
        // Sync with Hive
        _appointmentBox.putAt(index, Appointment(
          id: appointment.id,
          name: appointment.name,
          serviceType: appointment.serviceType,
          dateTime: newDateTime,
          status: appointment.status,
          queuePosition: appointment.queuePosition,
          isRescheduled: true,
        ));

        // Sync with Firestore
        await _firestore.updateAppointmentDateTime(id, newDateTime);

        notifyListeners();
        return null;
      }
    }
    return 'Appointment not found';
  }

  void nextToken() {
    final state = queueState;
    if (state.currentToken < state.totalInQueue) {
      state.currentToken++;
      state.save();
      notifyListeners();
    }
  }
}
