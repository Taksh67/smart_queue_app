import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/queue_provider.dart';
import '../widgets/status_badge.dart';

import '../providers/auth_provider.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(authProvider.currentUser?.assignedService == null 
            ? 'Admin Dashboard (Master)' 
            : 'Admin Dashboard (${authProvider.currentUser!.assignedService})'),
        actions: [
          IconButton(
            onPressed: () => authProvider.logout(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Consumer<QueueProvider>(
        builder: (context, provider, child) {
          final assignedService = authProvider.currentUser?.assignedService;
          
          // Filter appointments based on assigned service
          final filteredAppointments = assignedService == null 
              ? provider.appointments 
              : provider.appointments.where((a) => a.serviceType == assignedService).toList();

          final queue = provider.queueState;
          
          final pendingCount = filteredAppointments.where((a) => a.status == 'waiting' || a.status == 'scheduled' || a.status == 'in-progress' || a.status == 'in-service').length;

          return Column(
            children: [
              // Summary Cards
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    _buildSummaryCard('Total', '${filteredAppointments.length}', Colors.blue),
                    _buildSummaryCard('Serving', '#${queue.currentToken}', Colors.green),
                    _buildSummaryCard('Pending', '$pendingCount', Colors.orange),
                  ],
                ),
              ),
              
              // Global Next Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: provider.nextToken,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next in Queue'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const Divider(height: 32),
              
              // Appointments List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = filteredAppointments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(appointment.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${appointment.serviceType} | ${DateFormat('MMM d, HH:mm').format(appointment.dateTime)}'),
                              trailing: StatusBadge(
                                status: appointment.status,
                                isRescheduled: appointment.isRescheduled,
                              ),
                            ),
                            if (appointment.status == 'waiting' || appointment.status == 'in-service' || appointment.status == 'scheduled' || appointment.status == 'in-progress')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showRescheduleDialog(context, appointment.id),
                                    icon: const Icon(Icons.calendar_month, size: 18),
                                    label: const Text('Reschedule'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _confirmCancel(context, provider, appointment.id),
                                    icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      provider.updateAppointmentStatus(appointment.id, 'completed');
                                      provider.nextToken();
                                    },
                                    child: const Text('Mark Complete'),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withAlpha(200),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, QueueProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              provider.updateAppointmentStatus(id, 'cancelled');
              Navigator.pop(context);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context, String id) async {
    final provider = Provider.of<QueueProvider>(context, listen: false);
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null) {
      // For simplicity, just show a list of slots
      List<String> slots = [];
      for (int h = 9; h < 17; h++) {
        slots.add('${h.toString().padLeft(2, '0')}:00 AM');
        slots.add('${h.toString().padLeft(2, '0')}:30 AM');
      }
      // Quick slot picker
      String? pickedSlot = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Select Time Slot'),
          children: slots.map((s) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, s),
            child: Text(s),
          )).toList(),
        ),
      );

      if (pickedSlot != null) {
        final error = await provider.rescheduleAppointment(id, pickedDate, pickedSlot);
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
        }
      }
    }
  }
}
