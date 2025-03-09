import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayer_app/models/prayer.dart';

class PrayerTimesCard extends StatelessWidget {
  final DailyPrayerTimes todayPrayerTimes;
  final DailyPrayerTimes tomorrowPrayerTimes;
  
  const PrayerTimesCard({
    Key? key,
    required this.todayPrayerTimes,
    required this.tomorrowPrayerTimes,
  }) : super(key: key);
  
  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "Now";
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final currentPrayer = todayPrayerTimes.currentPrayer;
    final nextPrayer = todayPrayerTimes.nextPrayer;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Prayer Times",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Current or next prayer status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentPrayer != null 
                      ? 'Current Prayer: ${currentPrayer.name}'
                      : 'No current prayer',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextPrayer != null 
                      ? 'Next Prayer: ${nextPrayer.name} (${timeFormat.format(nextPrayer.time)})'
                      : 'No upcoming prayer today',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (nextPrayer != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Time until next prayer: ${_formatDuration(nextPrayer.timeUntil)}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Prayer times list
            ...todayPrayerTimes.prayers.map((prayer) {
              final isActive = prayer.isActive;
              final isNext = nextPrayer == prayer;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: isActive 
                            ? Colors.green 
                            : isNext 
                              ? Colors.orange 
                              : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prayer.name,
                          style: TextStyle(
                            fontWeight: isActive || isNext 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                            color: isActive 
                              ? Colors.green 
                              : isNext 
                                ? Colors.orange 
                                : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          timeFormat.format(prayer.time),
                          style: TextStyle(
                            fontWeight: isActive || isNext 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                            color: isActive 
                              ? Colors.green 
                              : isNext 
                                ? Colors.orange 
                                : null,
                          ),
                        ),
                        if (isActive) 
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          )
                        else if (isNext)
                          Text(
                            ' (in ${_formatDuration(prayer.timeUntil)})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}