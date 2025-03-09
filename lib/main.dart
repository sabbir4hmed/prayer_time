import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Prayer App',
    theme: ThemeData(
      scaffoldBackgroundColor: Colors.teal,
      primarySwatch: Colors.teal,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        primary: Colors.teal[700], // This will affect AppBar background
        // You can customize more colors here
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      useMaterial3: true,
    ),
    home: const PrayerApp(),
  );
}}// Main App Class
class PrayerApp extends StatefulWidget {
  const PrayerApp({Key? key}) : super(key: key);

  @override
  State<PrayerApp> createState() => _PrayerAppState();
}

class _PrayerAppState extends State<PrayerApp> {
  // Current time for clock
  DateTime _currentTime = DateTime.now();
  
  // Prayer time data
  DailyPrayerTimes? _todayPrayerTimes;
  DailyPrayerTimes? _tomorrowPrayerTimes;
  
  // Loading state
  bool _isLoading = true;
  String? _errorMessage;
  
  // Timers
  Timer? _clockTimer;
  Timer? _prayerUpdateTimer;
  
  // Location settings
  bool _useAutomaticLocation = true;
  String _city = 'Tangail';
  String _country = 'Bangladesh';
  String _locationDisplay = 'Detecting location...';
  
  @override
  void initState() {
    super.initState();
    _loadLocationSettings();
    _setupTimers();
  }
  
  Future<void> _loadLocationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useAutomaticLocation = prefs.getBool('useAutomaticLocation') ?? true;
      _city = prefs.getString('city') ?? 'Tangail';
      _country = prefs.getString('country') ?? 'Bangladesh';
      
      if (_useAutomaticLocation) {
        _locationDisplay = 'Detecting location...';
      } else {
        _locationDisplay = '$_city, $_country';
      }
    });
    
    _loadPrayerTimes();
  }
  
  Future<void> _saveLocationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useAutomaticLocation', _useAutomaticLocation);
    await prefs.setString('city', _city);
    await prefs.setString('country', _country);
  }
  
  void _setupTimers() {
    // Update clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    
    // Update prayer times every 15 minutes
    _prayerUpdateTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _loadPrayerTimes();
    });
  }
  
  Future<void> _loadPrayerTimes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final prayerService = PrayerService(
        useAutomaticLocation: _useAutomaticLocation,
        city: _city,
        country: _country,
      );
      
      final locationInfo = await prayerService.getLocationInfo();
      setState(() {
        if (_useAutomaticLocation) {
          _city = locationInfo['city']!;
          _country = locationInfo['country']!;
        }
        _locationDisplay = '$_city, $_country';
      });
      
      _todayPrayerTimes = await prayerService.getPrayerTimes();
      _tomorrowPrayerTimes = await prayerService.getPrayerTimes(
        date: DateTime.now().add(const Duration(days: 1))
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load prayer times: $e';
      });
    }
  }
  
  void _showLocationSettings() {
    showDialog(
      context: context,
      builder: (context) => LocationSettingsDialog(
        useAutomaticLocation: _useAutomaticLocation,
        city: _city,
        country: _country,
        onSave: (useAutomatic, city, country) {
          setState(() {
            _useAutomaticLocation = useAutomatic;
            _city = city;
            _country = country;
            if (!_useAutomaticLocation) {
              _locationDisplay = '$_city, $_country';
            }
          });
          _saveLocationSettings();
          _loadPrayerTimes();
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _clockTimer?.cancel();
    _prayerUpdateTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Times'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _showLocationSettings,
            tooltip: 'Location Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrayerTimes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPrayerTimes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Date & Time Card
              DateTimeCard(
                currentTime: _currentTime,
                location: _locationDisplay,
              ),
              
              const SizedBox(height: 16),
              
              // Prayer Times Card
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (_errorMessage != null)
                ErrorCard(errorMessage: _errorMessage!)
              else if (_todayPrayerTimes != null && _tomorrowPrayerTimes != null)
                Column(
                  children: [
                    PrayerTimesCard(
                      todayPrayerTimes: _todayPrayerTimes!,
                      tomorrowPrayerTimes: _tomorrowPrayerTimes!,
                    ),
                    const SizedBox(height: 16),
                    RamadanTimesCard(
                      todayPrayerTimes: _todayPrayerTimes!,
                      tomorrowPrayerTimes: _tomorrowPrayerTimes!,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Location Settings Dialog
class LocationSettingsDialog extends StatefulWidget {
  final bool useAutomaticLocation;
  final String city;
  final String country;
  final Function(bool useAutomatic, String city, String country) onSave;

  const LocationSettingsDialog({
    Key? key,
    required this.useAutomaticLocation,
    required this.city,
    required this.country,
    required this.onSave,
  }) : super(key: key);

  @override
  State<LocationSettingsDialog> createState() => _LocationSettingsDialogState();
}

class _LocationSettingsDialogState extends State<LocationSettingsDialog> {
  late bool _useAutomaticLocation;
  late TextEditingController _cityController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _useAutomaticLocation = widget.useAutomaticLocation;
    _cityController = TextEditingController(text: widget.city);
    _countryController = TextEditingController(text: widget.country);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Location Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Automatic location switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Automatic Location',
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: _useAutomaticLocation,
                  onChanged: (value) {
                    setState(() {
                      _useAutomaticLocation = value;
                    });
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Manual location inputs
            if (!_useAutomaticLocation) ...[
              const Text(
                'Manual Location:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              const Text(
                'Location will be detected automatically based on your device location.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onSave(
              _useAutomaticLocation,
              _cityController.text.trim(),
              _countryController.text.trim(),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Date & Time Card Widget
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
    final hijriDate = HijriCalendar.fromDate(currentTime);
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Location display
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.teal, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            
            // Date and time row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Dates
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(currentTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hijriDate.hDay} ${hijriDate.longMonthName}, ${hijriDate.hYear} AH',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                
                // Right side - Clock
                Text(
                  DateFormat('hh:mm:ss a').format(currentTime),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Prayer Times Card Widget
class PrayerTimesCard extends StatelessWidget {
  final DailyPrayerTimes todayPrayerTimes;
  final DailyPrayerTimes tomorrowPrayerTimes;
  
  const PrayerTimesCard({
    Key? key,
    required this.todayPrayerTimes,
    required this.tomorrowPrayerTimes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nextPrayer = todayPrayerTimes.nextPrayer;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - Progress circle
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _calculateProgressValue(nextPrayer),
                              strokeWidth: 10,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    nextPrayer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    nextPrayer.remainingTimeString,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Next Prayer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right side - Prayer times list
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Today\'s Prayer Times',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildPrayerTimesList(todayPrayerTimes),
                      
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Tomorrow\'s Prayer Times',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildPrayerTimesList(tomorrowPrayerTimes),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProgressValue(PrayerTimeModel prayer) {
    final now = DateTime.now();
    
    // If the prayer time is in the future
    if (prayer.time.isAfter(now)) {
      // Use a fixed value to ensure progress is visible
      return 0.3;
    }
    
    // If we're between this prayer and the next one
    if (prayer.nextTime != null) {
      final total = prayer.nextTime!.difference(prayer.time).inMinutes;
      if (total <= 0) return 0.5; // Default visible value
      
      final elapsed = now.difference(prayer.time).inMinutes;
      if (elapsed <= 0) return 0.1; // Small visible value
      if (elapsed >= total) return 1;
      
      return elapsed / total;
    }
    
    return 0.5; // Default visible progress when calculation fails
  }

  List<Widget> _buildPrayerTimesList(DailyPrayerTimes prayerTimes) {
    return prayerTimes.prayers.map((prayer) {
      final timeFormat = DateFormat('hh:mm a');
      final isNext = prayerTimes.nextPrayer.name == prayer.name;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              prayer.name,
              style: TextStyle(
                fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                color: isNext ? Colors.blue : Colors.black,
              ),
            ),
            Row(
              children: [
                Text(
                  timeFormat.format(prayer.time),
                  style: TextStyle(
                    fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    color: isNext ? Colors.blue : Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                if (isNext) 
                  Text(
                    ' (${prayer.remainingTimeString})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}

// Ramadan Times Card Widget
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
    // Get Fajr and Maghrib times from today's prayers
    final fajrPrayer = todayPrayerTimes.prayers.firstWhere(
      (prayer) => prayer.name == 'Fajr',
      orElse: () => todayPrayerTimes.prayers.first,
    );
    
    final maghribPrayer = todayPrayerTimes.prayers.firstWhere(
      (prayer) => prayer.name == 'Maghrib',
      orElse: () => todayPrayerTimes.prayers.first,
    );
    
    // Calculate Sehri end time (5 minutes before Fajr)
    final sehriEndTime = fajrPrayer.time.subtract(const Duration(minutes: 5));
    
    // Iftar time is the same as Maghrib time
    final iftarTime = maghribPrayer.time;
    
    // For tomorrow's times
    final tomorrowFajr = tomorrowPrayerTimes.prayers.firstWhere(
      (prayer) => prayer.name == 'Fajr',
      orElse: () => tomorrowPrayerTimes.prayers.first,
    );
    
    final tomorrowMaghrib = tomorrowPrayerTimes.prayers.firstWhere(
      (prayer) => prayer.name == 'Maghrib',
      orElse: () => tomorrowPrayerTimes.prayers.first,
    );
    
    final tomorrowSehriEndTime = tomorrowFajr.time.subtract(const Duration(minutes: 5));
    final tomorrowIftarTime = tomorrowMaghrib.time;
    
    final timeFormat = DateFormat('hh:mm a');
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon
            Row(
              children: [
                 Icon(
                  Icons.nightlight_round,
                  color: Colors.indigo,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Ramadan Times',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
            Divider(thickness: 1.5, color: Colors.indigo[100]),
            SizedBox(height: 8),
            
            // Today's times
            Text(
              "Today's Times",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            
            // Sehri time row
            _buildTimeRow(
              context: context,
              title: 'Sehri Ends',
              time: timeFormat.format(sehriEndTime),
              iconData: Icons.free_breakfast,
              iconColor: Colors.amber[700]!,
            ),
            
            SizedBox(height: 8),
            
            // Iftar time row
            _buildTimeRow(
              context: context,
              title: 'Iftar Time',
              time: timeFormat.format(iftarTime),
              iconData: Icons.dining,
              iconColor: Colors.green[700]!,
            ),
            
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            
            // Tomorrow's times
            Text(
              "Tomorrow's Times",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            
            // Tomorrow's Sehri time row
            _buildTimeRow(
              context: context,
              title: 'Sehri Ends',
              time: timeFormat.format(tomorrowSehriEndTime),
              iconData: Icons.free_breakfast,
              iconColor: Colors.amber[700]!,
            ),
            
            SizedBox(height: 8),
            
            // Tomorrow's Iftar time row
            _buildTimeRow(
              context: context,
              title: 'Iftar Time',
              time: timeFormat.format(tomorrowIftarTime),
              iconData: Icons.dining,
              iconColor: Colors.green[700]!,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeRow({
    required BuildContext context,
    required String title,
    required String time,
    required IconData iconData,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

// Error Card Widget
class ErrorCard extends StatelessWidget {
  final String errorMessage;
  
  const ErrorCard({
    Key? key,
    required this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading prayer times',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// Models
class PrayerTimeModel {
  final String name;
  final DateTime time;
  final DateTime? nextTime;

  PrayerTimeModel({
    required this.name,
    required this.time,
    this.nextTime,
  });

  Duration get remainingTime {
    final now = DateTime.now();
    if (time.isAfter(now)) {
      return time.difference(now);
    } else if (nextTime != null) {
      return nextTime!.difference(now);
    } else {
      return Duration.zero;
    }
  }

  String get remainingTimeString {
    final duration = remainingTime;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  bool get isActive {
    final now = DateTime.now();
    return time.isBefore(now) && (nextTime?.isAfter(now) ?? false);
  }
}

class DailyPrayerTimes {
  final DateTime date;
  final List<PrayerTimeModel> prayers = [];
  
  DailyPrayerTimes({required this.date});
  
  void addPrayer(String name, DateTime time, DateTime? nextTime) {
    prayers.add(PrayerTimeModel(
      name: name,
      time: time,
      nextTime: nextTime,
    ));
  }

  PrayerTimeModel? get currentPrayer {
    final now = DateTime.now();
    for (var i = 0; i < prayers.length - 1; i++) {
      if (now.isAfter(prayers[i].time) && now.isBefore(prayers[i + 1].time)) {
        return prayers[i];
      }
    }
    
    // Check last prayer
    if (prayers.isNotEmpty && now.isAfter(prayers.last.time)) {
      return prayers.last;
    }
    
    return null;
  }

  PrayerTimeModel get nextPrayer {
    final now = DateTime.now();
    for (var prayer in prayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return prayers.first; // Return first prayer for next day
  }
}

// API Models
class AladhanPrayerTimesResponse {
  final int code;
  final String status;
  final AladhanPrayerData data;

  AladhanPrayerTimesResponse({
    required this.code,
    required this.status,
    required this.data,
  });

  factory AladhanPrayerTimesResponse.fromJson(Map<String, dynamic> json) {
    return AladhanPrayerTimesResponse(
      code: json['code'],
      status: json['status'],
      data: AladhanPrayerData.fromJson(json['data']),
    );
  }
}

class AladhanPrayerData {
  final Timings timings;
  final Date date;
  final Meta meta;

  AladhanPrayerData({
    required this.timings,
    required this.date,
    required this.meta,
  });

  factory AladhanPrayerData.fromJson(Map<String, dynamic> json) {
    return AladhanPrayerData(
      timings: Timings.fromJson(json['timings']),
      date: Date.fromJson(json['date']),
      meta: Meta.fromJson(json['meta']),
    );
  }
}

class Timings {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String sunset;
  final String maghrib;
  final String isha;
  final String imsak;
  final String midnight;
  final String firstThird;
  final String lastThird;

  Timings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.midnight,
    required this.firstThird,
    required this.lastThird,
  });

  factory Timings.fromJson(Map<String, dynamic> json) {
    return Timings(
      fajr: json['Fajr'],
      sunrise: json['Sunrise'],
      dhuhr: json['Dhuhr'],
      asr: json['Asr'],
      sunset: json['Sunset'],
      maghrib: json['Maghrib'],
      isha: json['Isha'],
      imsak: json['Imsak'],
      midnight: json['Midnight'],
      firstThird: json['Firstthird'],
      lastThird: json['Lastthird'],
    );
  }
}

class Date {
  final String readable;
  final String timestamp;
  final Gregorian gregorian;
  final Hijri hijri;

  Date({
    required this.readable,
    required this.timestamp,
    required this.gregorian,
    required this.hijri,
  });

  factory Date.fromJson(Map<String, dynamic> json) {
    return Date(
      readable: json['readable'],
      timestamp: json['timestamp'],
      gregorian: Gregorian.fromJson(json['gregorian']),
      hijri: Hijri.fromJson(json['hijri']),
    );
  }
}

class Gregorian {
  final String date;
  final String format;
  final String day;
  final GregorianMonth month;
  final String year;
  final Designation designation;
  final List<dynamic> holidays;

  Gregorian({
    required this.date,
    required this.format,
    required this.day,
    required this.month,
    required this.year,
    required this.designation,
    required this.holidays,
  });

  factory Gregorian.fromJson(Map<String, dynamic> json) {
    return Gregorian(
      date: json['date'],
      format: json['format'],
      day: json['day'],
      month: GregorianMonth.fromJson(json['month']),
      year: json['year'],
      designation: Designation.fromJson(json['designation']),
      holidays: json['holidays'] ?? [],
    );
  }
}

class GregorianMonth {
  final int number;
  final String en;

  GregorianMonth({
    required this.number,
    required this.en,
  });

  factory GregorianMonth.fromJson(Map<String, dynamic> json) {
    return GregorianMonth(
      number: json['number'],
      en: json['en'],
    );
  }
}

class HijriMonthData {
  final int number;
  final String en;
  final String ar;

  HijriMonthData({
    required this.number,
    required this.en,
    required this.ar,
  });

  factory HijriMonthData.fromJson(Map<String, dynamic> json) {
    return HijriMonthData(
      number: json['number'],
      en: json['en'],
      ar: json['ar'],
    );
  }
}

class Hijri {
  final String date;
  final String format;
  final String day;
  final HijriMonthData month;
  final String year;
  final Designation designation;
  final List<dynamic> holidays;

  Hijri({
    required this.date,
    required this.format,
    required this.day,
    required this.month,
    required this.year,
    required this.designation,
    required this.holidays,
  });

  factory Hijri.fromJson(Map<String, dynamic> json) {
    return Hijri(
      date: json['date'],
      format: json['format'],
      day: json['day'],
      month: HijriMonthData.fromJson(json['month']),
      year: json['year'],
      designation: Designation.fromJson(json['designation']),
      holidays: List<dynamic>.from(json['holidays'] ?? []),
    );
  }
}

class Designation {
  final String abbreviated;
  final String expanded;

  Designation({
    required this.abbreviated,
    required this.expanded,
  });

  factory Designation.fromJson(Map<String, dynamic> json) {
    return Designation(
      abbreviated: json['abbreviated'],
      expanded: json['expanded'],
    );
  }
}

class Meta {
  final double latitude;
  final double longitude;
  final String timezone;
  final Method method;
  final String latitudeAdjustmentMethod;
  final String midnightMode;
  final String school;
  final Map<String, int> offset;

  Meta({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.method,
    required this.latitudeAdjustmentMethod,
    required this.midnightMode,
    required this.school,
    required this.offset,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      timezone: json['timezone'],
      method: Method.fromJson(json['method']),
      latitudeAdjustmentMethod: json['latitudeAdjustmentMethod'],
      midnightMode: json['midnightMode'],
      school: json['school'],
      offset: Map<String, int>.from(json['offset']),
    );
  }
}

class Method {
  final int id;
  final String name;
  final Map<String, dynamic> params;
  final Location location;

  Method({
    required this.id,
    required this.name,
    required this.params,
    required this.location,
  });

  factory Method.fromJson(Map<String, dynamic> json) {
    return Method(
      id: json['id'],
      name: json['name'],
      params: Map<String, dynamic>.from(json['params']),
      location: Location.fromJson(json['location']),
    );
  }
}

class Location {
  final double latitude;
  final double longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }
}

// Prayer Service
class PrayerService {
  final bool useAutomaticLocation;
  final String city;
  final String country;
  
  PrayerService({
    this.useAutomaticLocation = true,
    this.city = 'Tangail',
    this.country = 'Bangladesh',
  });

  // Get location information
  Future<Map<String, String>> getLocationInfo() async {
    if (!useAutomaticLocation) {
      return {
        'city': city,
        'country': country,
      };
    }
    
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        
        // If still denied after requesting, use default
        if (permission == LocationPermission.denied) {
          return _getDefaultLocation();
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return _getDefaultLocation();
      }
      
      try {
        // Get the position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
        
        // For now, we'll return default values
        // In a real app, you might want to use reverse geocoding
        // to determine city and country from coordinates
        return _getDefaultLocation();
        
      } catch (e) {
        print('Error getting position: $e');
        return _getDefaultLocation();
      }
    } catch (e) {
      print('Error in location service: $e');
      return _getDefaultLocation();
    }
  }
  
  // Helper method to return default location
  Map<String, String> _getDefaultLocation() {
    return {
      'city': city,
      'country': country,
    };
  }

  Future<AladhanPrayerTimesResponse> fetchPrayerTimes({DateTime? date}) async {
    date ??= DateTime.now();
    
    // Format date as DD-MM-YYYY
    final dateStr = DateFormat('dd-MM-yyyy').format(date);
    
    // Get location info
    final locationInfo = await getLocationInfo();
    final city = locationInfo['city'];
    final country = locationInfo['country'];
    
    // 1 is Egyptian General Authority of Survey
    final method = 1;
    
    final url = 'https://api.aladhan.com/v1/timingsByCity/$dateStr?city=$city&country=$country&method=$method';
    
    print('Fetching prayer times from: $url');
    
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode == 200) {
      return AladhanPrayerTimesResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load prayer times: ${response.statusCode}');
    }
  }

  // Parse the time string (HH:MM format) to a DateTime
  DateTime _parseTimeString(String timeStr, DateTime baseDate) {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    return DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      hour,
      minute,
    );
  }

  Future<DailyPrayerTimes> getPrayerTimes({DateTime? date}) async {
    date ??= DateTime.now();
    
    final apiResponse = await fetchPrayerTimes(date: date);
    final timings = apiResponse.data.timings;
    
    // Create a base date object for the requested date
    final baseDate = date;
    
    final dailyPrayerTimes = DailyPrayerTimes(date: baseDate);
    
    // Parse all prayer times
    final fajrTime = _parseTimeString(timings.fajr.split(' ')[0], baseDate);
    final sunriseTime = _parseTimeString(timings.sunrise.split(' ')[0], baseDate);
    final dhuhrTime = _parseTimeString(timings.dhuhr.split(' ')[0], baseDate);
    final asrTime = _parseTimeString(timings.asr.split(' ')[0], baseDate);
    final maghribTime = _parseTimeString(timings.maghrib.split(' ')[0], baseDate);
    final ishaTime = _parseTimeString(timings.isha.split(' ')[0], baseDate);
    
    // Consider the API time as Shafi/standard Asr time
    final asrShafiTime = asrTime;
    // Create Hanafi time by adding 1 hour to the standard time
    final asrHanafiTime = asrTime.add(const Duration(hours: 1));
    
    // Add prayers to the daily prayer times object
    dailyPrayerTimes.addPrayer('Fajr', fajrTime, sunriseTime);
    dailyPrayerTimes.addPrayer('Sunrise', sunriseTime, dhuhrTime);
    dailyPrayerTimes.addPrayer('Dhuhr', dhuhrTime, asrShafiTime);
    dailyPrayerTimes.addPrayer('Asr (Shafi)', asrShafiTime, asrHanafiTime);
    dailyPrayerTimes.addPrayer('Asr (Hanafi)', asrHanafiTime, maghribTime);
    dailyPrayerTimes.addPrayer('Maghrib', maghribTime, ishaTime);

    // For Isha, the next prayer is Fajr of the next day
    // We'll need to get tomorrow's Fajr time for the last prayer
    DateTime nextFajr;
    if (date.day == DateTime.now().day) {
      // If we're getting today's prayers, try to use tomorrow's Fajr if already loaded
      try {
        final tomorrowData = await fetchPrayerTimes(
          date: date.add(const Duration(days: 1))
        );
        final tomorrowFajrStr = tomorrowData.data.timings.fajr.split(' ')[0];
        nextFajr = _parseTimeString(
          tomorrowFajrStr, 
          date.add(const Duration(days: 1))
        );
      } catch (e) {
        // If that fails, estimate next Fajr 24 hours after today's
        nextFajr = fajrTime.add(const Duration(days: 1));
      }
    } else {
      // For non-today requests, just estimate
      nextFajr = fajrTime.add(const Duration(days: 1));
    }
    
    dailyPrayerTimes.addPrayer('Isha', ishaTime, nextFajr);
    
    return dailyPrayerTimes;
  }
}