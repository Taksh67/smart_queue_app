import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appointment.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add Appointment
  Future<void> addAppointment(Appointment appointment, String uid) async {
    Map<String, dynamic> data = {
      'id': appointment.id,
      'name': appointment.name,
      'serviceType': appointment.serviceType,
      'dateTime': Timestamp.fromDate(appointment.dateTime),
      'status': appointment.status,
      'queuePosition': appointment.queuePosition,
      'isRescheduled': appointment.isRescheduled,
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('appointments').doc(appointment.id).set(data);
  }

  // Get User Appointments
  Stream<List<Map<String, dynamic>>> getUserAppointments(String uid) {
    return _db
        .collection('appointments')
        .where('createdBy', isEqualTo: uid)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get All Appointments (Admin)
  Stream<List<Map<String, dynamic>>> getAllAppointments() {
    return _db
        .collection('appointments')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Update Appointment Status
  Future<void> updateStatus(String id, String status) async {
    await _db.collection('appointments').doc(id).update({'status': status});
  }

  // Update Appointment Date/Time
  Future<void> updateAppointmentDateTime(String id, DateTime newDateTime) async {
    await _db.collection('appointments').doc(id).update({
      'dateTime': Timestamp.fromDate(newDateTime),
      'isRescheduled': true,
    });
  }
}
