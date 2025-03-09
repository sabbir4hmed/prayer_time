import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prayer_app/models/prayer.dart';

class RamadanTimesCard extends StatelessWidget {
  final DailyPrayerTimes todayPrayerTimes;
  final DailyPrayerTimes tomorrowPrayerTimes;
  
  const RamadanTimesCard({
    Key? key,
    required this.todayPrayerTimes,
    required this.tomorrowPrayerTimes,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    
    // Extract Fajr and Maghrib times
    final Prayer fajrPrayer = todayPrayerTimes.prayers.firstWhere(
      (prayer) => prayer.name == 'Fajr',
      orElse: () => todayPrayerTimes.prayers.first,
    );
    
    final Prayer maghribPrayer = todayPrayerTimes.prayers.firstWhere(
      (prayer) => prayer.name == 'Maghrib',
      orElse: () => todayPrayerTimes.prayers.last,
    );
    
    // Tomorrow's Fajr for Sehri time
    final Prayer tomorrowFajrPrayer = tomorrowPrayerTimes.prayers.firstWhere(
      (prayer) => prayer.name == 'Fajr',
      orElse: () => tomorrowPrayerTimes.prayers.first,
    );
    
    // Calculate Sehri end time (5 minutes before Fajr)
    final sehriEndTime = fajrPrayer.time.subtract(const Duration(minutes: 5));
    final tomorrowSehriEndTime = tomorrowFajrPrayer.time.subtract(const Duration(minutes: 5));
    
    // Calculate fasting duration
    final fastingDuration = maghribPrayer.time.difference(fajrPrayer.time);
    final fastingHours = fastingDuration.inHours;
    final fastingMinutes = fastingDuration.inMinutes % 60;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ramadan Times",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Today's times
            ListTile(
              title: const Text('Today\'s Sehri Ends'),
              trailing: Text(
                timeFormat.format(sehriEndTime),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.free_breakfast),
            ),
            
            ListTile(
              title: const Text('Today\'s Iftar Time'),
              trailing: Text(
                timeFormat.format(maghribPrayer.time),
                style: const TextStyle(fontWeight: FontWeight.bold,
                fontSize: 18),
              ),
              leading: const Icon(Icons.dinner_dining),
            ),
            
            const Divider(),
            
            // Tomorrow's times
            ListTile(
              title: const Text('Tomorrow\'s Sehri Ends'),
              trailing: Text(
                timeFormat.format(tomorrowSehriEndTime),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.wb_twilight),
            ),
            
            // Fasting duration
            ListTile(
              title: const Text('Fasting Duration'),
              trailing: Text(
                '$fastingHours hours $fastingMinutes minutes',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.timer),
            ),
          ],
        ),
      ),
    );
  }
}