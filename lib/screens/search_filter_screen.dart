import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/queue_provider.dart';
import '../models/appointment.dart';
import '../widgets/status_badge.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  String _searchQuery = '';
  DateTime? _filterDate;
  String? _filterStatus;
  String? _filterService;

  final List<String> _statuses = ['Waiting', 'In-Service', 'Completed', 'Cancelled'];
  final List<String> _services = ['Consultation', 'Salon', 'Clinic', 'College', 'Office', 'Bank'];

  List<Appointment> _applyFilters(List<Appointment> appointments) {
    return appointments.where((a) {
      // 1. Search Query (Name or ID)
      final matchesSearch = a.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.id.toLowerCase().contains(_searchQuery.toLowerCase());

      // 2. Date Filter
      bool matchesDate = true;
      if (_filterDate != null) {
        matchesDate = a.dateTime.year == _filterDate!.year &&
            a.dateTime.month == _filterDate!.month &&
            a.dateTime.day == _filterDate!.day;
      }

      // 3. Status Filter
      bool matchesStatus = true;
      if (_filterStatus != null) {
        matchesStatus = a.status.toLowerCase() == _filterStatus!.toLowerCase();
      }

      // 4. Service Filter
      bool matchesService = true;
      if (_filterService != null) {
        matchesService = a.serviceType == _filterService;
      }

      return matchesSearch && matchesDate && matchesStatus && matchesService;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Filter'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by Name or ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Filters Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Date Picker Action
                ActionChip(
                  avatar: Icon(Icons.calendar_today, size: 16, color: _filterDate != null ? Colors.white : Colors.blue),
                  label: Text(_filterDate == null ? 'Filter Date' : DateFormat('MMM d').format(_filterDate!)),
                  backgroundColor: _filterDate != null ? Colors.blue : null,
                  labelStyle: TextStyle(color: _filterDate != null ? Colors.white : null),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _filterDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    setState(() => _filterDate = picked);
                  },
                ),
                const SizedBox(width: 8),

                // Status Filter
                _buildDropdownFilter(
                  hint: 'Status',
                  value: _filterStatus,
                  items: _statuses,
                  onChanged: (val) => setState(() => _filterStatus = val),
                ),
                const SizedBox(width: 8),

                // Service Filter
                _buildDropdownFilter(
                  hint: 'Service',
                  value: _filterService,
                  items: _services,
                  onChanged: (val) => setState(() => _filterService = val),
                ),
                const SizedBox(width: 8),

                // Reset Button
                if (_filterDate != null || _filterStatus != null || _filterService != null || _searchQuery.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _filterDate = null;
                      _filterStatus = null;
                      _filterService = null;
                    }),
                    child: const Text('Reset'),
                  ),
              ],
            ),
          ),
          const Divider(),

          // Results List
          Expanded(
            child: Consumer<QueueProvider>(
              builder: (context, provider, child) {
                final filtered = _applyFilters(provider.appointments);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No results found', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final appointment = filtered[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(appointment.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${appointment.serviceType} | ${DateFormat('MMM d, HH:mm').format(appointment.dateTime)}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('#${appointment.queuePosition}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            StatusBadge(
                              status: appointment.status,
                              isRescheduled: appointment.isRescheduled,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value != null ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: value != null ? Colors.white : Colors.black87, fontSize: 13)),
          icon: Icon(Icons.arrow_drop_down, color: value != null ? Colors.white : Colors.black87),
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87),
          items: items.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s, style: const TextStyle(color: Colors.black87)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
