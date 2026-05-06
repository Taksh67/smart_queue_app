import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/queue_provider.dart';

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({super.key});

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Poll every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          // This triggers a rebuild to refresh data from provider
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Queue Status')),
      body: Consumer<QueueProvider>(
        builder: (context, provider, child) {
          final queue = provider.queueState;
          final myAppointment = provider.latestActiveAppointment;
          
          int? positionAhead;
          int? waitTime;

          if (myAppointment != null) {
            positionAhead = myAppointment.queuePosition! - queue.currentToken;
            if (positionAhead < 0) positionAhead = 0;
            waitTime = positionAhead * 10;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildStatusCard(
                  context,
                  title: 'Currently Serving',
                  value: 'Token #${queue.currentToken}',
                  icon: Icons.notifications_active,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                if (myAppointment != null) ...[
                  _buildStatusCard(
                    context,
                    title: 'Your Position',
                    value: 'Queue #${myAppointment.queuePosition}',
                    subtitle: positionAhead == 0 
                        ? 'It\'s your turn!' 
                        : '$positionAhead person(s) ahead of you',
                    icon: Icons.person,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  _buildStatusCard(
                    context,
                    title: 'Estimated Wait',
                    value: '$waitTime mins',
                    icon: Icons.timer,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 30),
                  const Text('Queue Progress'),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: queue.totalInQueue > 0 ? queue.currentToken / queue.totalInQueue : 0,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ] else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, size: 48, color: Colors.blue[300]),
                          const SizedBox(height: 16),
                          const Text(
                            'No active appointments.',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Book an appointment to track your status here.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(40),
              radius: 30,
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: 12, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
