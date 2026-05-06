import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/queue_provider.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  final List<String> _services = ['Consultation', 'Salon', 'Clinic', 'College', 'Office', 'Bank'];
  
  List<String> _generateTimeSlots() {
    List<String> slots = [];
    for (int hour = 9; hour < 17; hour++) {
      for (int minute in [0, 30]) {
        final h = hour > 12 ? hour - 12 : hour;
        final amPm = hour >= 12 ? 'PM' : 'AM';
        final m = minute == 0 ? '00' : '30';
        slots.add('${h.toString().padLeft(2, '0')}:$m $amPm');
      }
    }
    return slots;
  }

  late List<String> _timeSlots;

  @override
  void initState() {
    super.initState();
    _timeSlots = _generateTimeSlots();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTimeSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time slot')),
        );
        return;
      }

      final provider = Provider.of<QueueProvider>(context, listen: false);
      final error = provider.bookAppointment(
        name: _nameController.text,
        serviceType: _selectedService!,
        date: _selectedDate!,
        timeSlot: _selectedTimeSlot!,
      );

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        final lastAppointment = provider.appointments.last;
        _showConfirmationDialog(lastAppointment.id, lastAppointment.queuePosition!);
      }
    }
  }

  void _showConfirmationDialog(String id, int queueNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Booking Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appointment ID: $id'),
            const SizedBox(height: 8),
            Text('Queue Number: #$queueNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Reset form
              _nameController.clear();
              setState(() {
                _selectedService = null;
                _selectedDate = null;
                _selectedTimeSlot = null;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedService,
                decoration: const InputDecoration(labelText: 'Service Type', border: OutlineInputBorder()),
                items: _services.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedService = val),
                validator: (val) => val == null ? 'Select a service' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_selectedDate == null ? 'Select Preferred Date' : 'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTimeSlot,
                decoration: const InputDecoration(labelText: 'Time Slot', border: OutlineInputBorder()),
                items: _timeSlots.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedTimeSlot = val),
                validator: (val) => val == null ? 'Select a time slot' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Confirm Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
