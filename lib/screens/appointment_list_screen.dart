import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/queue_provider.dart';
import '../widgets/status_badge.dart';

class AppointmentListScreen extends StatelessWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Appointments'),
      ),
      body: Consumer<QueueProvider>(
        builder: (context, provider, child) {
          final appointments = provider.appointments;

          if (appointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No bookings yet!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Start by booking an appointment.'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Provider already reads from Hive, but we can notify listeners to refresh if needed
              provider.notifyListeners();
            },
            child: ListView.builder(
              itemCount: appointments.length,
              itemBuilder: (context, index) {
                final appointment = appointments[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      appointment.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Service: ${appointment.serviceType}'),
                        Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(appointment.dateTime)}'),
                        const SizedBox(height: 4),
                        StatusBadge(
                          status: appointment.status,
                          isRescheduled: appointment.isRescheduled,
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '#${appointment.queuePosition}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const Text('Queue No.', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
