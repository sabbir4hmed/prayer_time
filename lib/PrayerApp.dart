import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prayer_app/services/PrayerService.dart';
import 'package:prayer_app/services/NotificationService.dart';
import 'package:prayer_app/models/prayer.dart';
import 'package:prayer_app/widgets/DateTimeCard.dart';
import 'package:prayer_app/widgets/PrayerTimesCard.dart';
import 'package:prayer_app/widgets/RamadanTimesCard.dart';
import 'package:prayer_app/widgets/ErrorCard.dart';
import 'package:prayer_app/widgets/settings_dialog.dart';

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
  
  // Notification settings
  bool _enableNotifications = true;
  final NotificationService _notificationService = NotificationService();
 
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSettings();
    _setupTimers();
  }
  
  // Initialize notification service
  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
  }
 
  // Load all app settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useAutomaticLocation = prefs.getBool('useAutomaticLocation') ?? true;
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
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
 
  // Save location settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useAutomaticLocation', _useAutomaticLocation);
    await prefs.setBool('enableNotifications', _enableNotifications);
    await prefs.setString('city', _city);
    await prefs.setString('country', _country);
  }
 
  // Setup timers for clock and prayer time updates
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
 
  // Schedule notifications for prayer times
  Future<void> _scheduleNotifications() async {
    // Only proceed if notifications are enabled and we have prayer times data
    if (!_enableNotifications || _todayPrayerTimes == null || _tomorrowPrayerTimes == null) {
      return;
    }
    
    // Cancel all existing notifications first
    await _notificationService.cancelAllNotifications();
    
    // Schedule notifications for each prayer time
    for (var prayer in _todayPrayerTimes!.prayers) {
      if (prayer.time.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: prayer.name.hashCode,
          title: "It's ${prayer.name} Time",
          body: "Time to offer your ${prayer.name} prayer",
          scheduledTime: prayer.time,
          sound: 'adhan',
          payload: 'prayer_${prayer.name}',
        );
      }
    }
    
    // Schedule Sehri end notification (5 minutes before Fajr)
    final fajrPrayer = _todayPrayerTimes!.prayers.firstWhere(
      (prayer) => prayer.name == 'Fajr',
      orElse: () => _todayPrayerTimes!.prayers.first,
    );
    
    final sehriEndTime = fajrPrayer.time.subtract(const Duration(minutes: 5));
    if (sehriEndTime.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: 'sehri_end'.hashCode,
        title: "Sehri Time Ending Soon",
        body: "Only 5 minutes left until Fajr prayer time",
        scheduledTime: sehriEndTime,
        sound: 'sehri_alarm',
        payload: 'sehri_end',
      );
    }
    
    // Schedule Iftar notification (at Maghrib time)
    final maghribPrayer = _todayPrayerTimes!.prayers.firstWhere(
      (prayer) => prayer.name == 'Maghrib',
      orElse: () => _todayPrayerTimes!.prayers.first,
    );
    
    if (maghribPrayer.time.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: 'iftar'.hashCode,
        title: "It's Iftar Time",
        body: "Time to break your fast",
        scheduledTime: maghribPrayer.time,
        sound: 'iftar_alarm',
        payload: 'iftar',
      );
    }
    
    // Schedule tomorrow's Sehri reminder (1 hour before Fajr)
    final tomorrowFajr = _tomorrowPrayerTimes!.prayers.firstWhere(
      (prayer) => prayer.name == 'Fajr',
      orElse: () => _tomorrowPrayerTimes!.prayers.first,
    );
    
    final tomorrowSehriTime = tomorrowFajr.time.subtract(const Duration(hours: 1));
    await _notificationService.scheduleNotification(
      id: 'tomorrow_sehri'.hashCode,
      title: "Prepare for Sehri",
      body: "One hour until Sehri ends",
      scheduledTime: tomorrowSehriTime,
      sound: 'sehri_alarm',
      payload: 'tomorrow_sehri',
    );
  }
 
  // Load prayer times from API
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
      
      // Schedule notifications after loading prayer times
      _scheduleNotifications();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load prayer times: $e';
      });
    }
  }
 
  // Show settings dialog
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        useAutomaticLocation: _useAutomaticLocation,
        enableNotifications: _enableNotifications,
        city: _city,
        country: _country,
        onSave: (useAutomatic, enableNotifications, city, country) {
          setState(() {
            _useAutomaticLocation = useAutomatic;
            _enableNotifications = enableNotifications;
            _city = city;
            _country = country;
            if (!_useAutomaticLocation) {
              _locationDisplay = '$_city, $_country';
            }
          });
          _saveSettings();
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.white,
        title: const Text('Prayer Times'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
            tooltip: 'Settings',
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
                    const SizedBox(height: 16),
                    // Notification status indicator
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              _enableNotifications 
                                ? Icons.notifications_active 
                                : Icons.notifications_off,
                              color: _enableNotifications 
                                ? Colors.green 
                                : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _enableNotifications
                                  ? 'Notifications are enabled for prayer times, Sehri and Iftar'
                                  : 'Notifications are disabled',
                                style: TextStyle(
                                  color: _enableNotifications 
                                    ? Colors.green 
                                    : Colors.grey,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: _showSettings,
                              tooltip: 'Notification Settings',
                            ),
                          ],
                        ),
                      ),
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