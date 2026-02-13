import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/school_event_model.dart';
import '../../school/services/school_api.dart';
import 'package:intl/intl.dart';

class SchoolEventsScreen extends StatelessWidget {
  const SchoolEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = SchoolApi();
    final mq = MediaQuery.of(context);
    final isMobile = mq.size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Events'),
        backgroundColor: AppColors.headTeacherRole,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SchoolEventModel>>(
        stream: api.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.event_busy, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No school events scheduled yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final isToday = DateUtils.isSameDay(event.date, DateTime.now());

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: isToday ? 8 : 2,
                shadowColor: isToday ? AppColors.headTeacherRole.withValues(alpha: 0.3) : Colors.black12,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(20),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isToday ? Colors.orange : AppColors.headTeacherRole).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isToday ? Icons.stars : Icons.event_available,
                      color: isToday ? Colors.orange : AppColors.headTeacherRole,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(DateFormat('EEEE, MMM d, yyyy').format(event.date)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(event.location),
                        ],
                      ),
                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(event.description, style: const TextStyle(color: Colors.black54)),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
