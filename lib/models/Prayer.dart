class Prayer {
  final String name;
  final DateTime time;
  final DateTime nextPrayer;

  Prayer({
    required this.name,
    required this.time,
    required this.nextPrayer,
  });

  Duration get timeUntil => 
    time.isAfter(DateTime.now()) 
      ? time.difference(DateTime.now()) 
      : const Duration();
      
  bool get isActive => 
    time.isBefore(DateTime.now()) && 
    nextPrayer.isAfter(DateTime.now());
}

class DailyPrayerTimes {
  final DateTime date;
  final List<Prayer> prayers = [];

  DailyPrayerTimes({required this.date});

  void addPrayer(String name, DateTime time, DateTime nextPrayer) {
    prayers.add(Prayer(
      name: name, 
      time: time, 
      nextPrayer: nextPrayer
    ));
  }

  Prayer? get currentPrayer {
    for (final prayer in prayers) {
      if (prayer.isActive) {
        return prayer;
      }
    }
    return null;
  }

  Prayer? get nextPrayer {
    for (final prayer in prayers) {
      if (prayer.time.isAfter(DateTime.now())) {
        return prayer;
      }
    }
    return null;
  }
}

class AladhanPrayerTimesResponse {
  final int code;
  final String status;
  final PrayerTimesData data;

  AladhanPrayerTimesResponse({
    required this.code,
    required this.status,
    required this.data,
  });

  factory AladhanPrayerTimesResponse.fromJson(Map<String, dynamic> json) {
    return AladhanPrayerTimesResponse(
      code: json['code'],
      status: json['status'],
      data: PrayerTimesData.fromJson(json['data']),
    );
  }
}

class PrayerTimesData {
  final PrayerTimings timings;
  final PrayerDate date;
  final PrayerMeta meta;

  PrayerTimesData({
    required this.timings,
    required this.date,
    required this.meta,
  });

  factory PrayerTimesData.fromJson(Map<String, dynamic> json) {
    return PrayerTimesData(
      timings: PrayerTimings.fromJson(json['timings']),
      date: PrayerDate.fromJson(json['date']),
      meta: PrayerMeta.fromJson(json['meta']),
    );
  }
}

class PrayerTimings {
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String sunset;
  final String maghrib;
  final String isha;
  final String imsak;
  final String midnight;

  PrayerTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.midnight,
  });

  factory PrayerTimings.fromJson(Map<String, dynamic> json) {
    return PrayerTimings(
      fajr: json['Fajr'],
      sunrise: json['Sunrise'],
      dhuhr: json['Dhuhr'],
      asr: json['Asr'],
      sunset: json['Sunset'],
      maghrib: json['Maghrib'],
      isha: json['Isha'],
      imsak: json['Imsak'],
      midnight: json['Midnight'],
    );
  }
}

class PrayerDate {
  final String readable;
  final String gregorian;
  final String hijri;

  PrayerDate({
    required this.readable,
    required this.gregorian,
    required this.hijri,
  });

  factory PrayerDate.fromJson(Map<String, dynamic> json) {
    return PrayerDate(
      readable: json['readable'],
      gregorian: json['gregorian']['date'],
      hijri: json['hijri']['date'],
    );
  }
}

class PrayerMeta {
  final double latitude;
  final double longitude;
  final String timezone;
  final String method;

  PrayerMeta({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.method,
  });

  factory PrayerMeta.fromJson(Map<String, dynamic> json) {
    return PrayerMeta(
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      timezone: json['timezone'],
      method: json['method']['name'],
    );
  }
}