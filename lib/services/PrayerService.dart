import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:prayer_app/models/prayer.dart';

class PrayerService {
  final bool useAutomaticLocation;
  final String city;
  final String country;

  PrayerService({
    required this.useAutomaticLocation,
    required this.city,
    required this.country,
  });

  Future<Map<String, String>> getLocationInfo() async {
    if (useAutomaticLocation) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return _getDefaultLocation();
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            return _getDefaultLocation();
          }
        }

        if (permission == LocationPermission.deniedForever) {
          return _getDefaultLocation();
        }

        try {
          // Get the position with a timeout
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          );
          
          // For now, we'll return the default location
          // In a real app, you'd do reverse geocoding here
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
    
    return _getDefaultLocation();
  }
  
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