import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

class DateTimeCard extends StatelessWidget {
  final DateTime currentTime;
  final String location;
  
  const DateTimeCard({
    Key? key,
    required this.currentTime,
    required this.location,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Create Hijri date
    final HijriCalendar hijri = HijriCalendar.fromDate(currentTime);
    
    // Format time
    final timeFormat = DateFormat('h:mm:ss a');
    final dateFormat = DateFormat('EEEE, MMMM d, y');
    
    // Format Hijri date
    final hijriDateStr = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(currentTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hijriDateStr,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeFormat.format(currentTime),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}