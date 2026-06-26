import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/state/app_state.dart';
import '../../core/constants/app_colors.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final attendanceHistory = state.attendanceHistory;

    if (attendanceHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.forestGreen));
    }

    final todayData = attendanceHistory.first;
    final int todayDeliveries = todayData['deliveriesCompleted'] ?? 0;
    final int target = todayData['target'] ?? 5;
    final bool isPresent = todayData['status'] == 'Present';

    return RefreshIndicator(
      edgeOffset: 0,
      onRefresh: () => state.fetchAttendance(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's Status Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: isPresent 
                      ? [Colors.green.shade400, Colors.green.shade700]
                      : [Colors.orange.shade400, Colors.deepOrange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Attendance",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPresent ? 'PRESENT' : 'ABSENT',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isPresent) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$todayDeliveries',
                          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, height: 1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Deliveries Today',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Checked in at ${todayData['checkInTime'] != null ? DateFormat('hh:mm a').format(DateTime.parse(todayData['checkInTime']).toLocal()) : 'N/A'}',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                    ),
                  ] else ...[
                    Text(
                      'You have not marked attendance for today.',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await state.markAttendance();
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Attendance marked successfully!')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Mark Attendance (Check In)'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Text(
            'LAST 7 DAYS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          // History List
          ...attendanceHistory.skip(1).map((record) {
            final date = DateTime.parse(record['date']);
            final deliveries = record['deliveriesCompleted'] ?? 0;
            final recordTarget = record['target'] ?? 5;
            final recordIsPresent = record['status'] == 'Present';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: recordIsPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    recordIsPresent ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: recordIsPresent ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  DateFormat('EEEE, MMM d').format(date),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('$deliveries / $recordTarget Deliveries'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: recordIsPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record['status'],
                    style: TextStyle(
                      color: recordIsPresent ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
