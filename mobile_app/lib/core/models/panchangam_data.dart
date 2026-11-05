// Strongly typed data models for the Vedam Hindu Panchangam client.
// Matches backend API schema for Pancha Anga, celestial events, muhurtas, and conventions.

class PanchangamLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String timezone;
  final double altitudeMeters;
  final bool isDeviceLocation;

  const PanchangamLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.altitudeMeters = 0.0,
    this.isDeviceLocation = false,
  });

  factory PanchangamLocation.fromJson(Map<String, dynamic> json) {
    return PanchangamLocation(
      name: json['name'] as String? ?? 'Unknown Location',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timezone: json['timezone'] as String? ?? 'UTC',
      altitudeMeters: (json['altitude_meters'] as num?)?.toDouble() ?? 0.0,
      isDeviceLocation: json['is_device_location'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
    'altitude_meters': altitudeMeters,
    'is_device_location': isDeviceLocation,
  };

  static const PanchangamLocation varanasi = PanchangamLocation(
    name: 'Varanasi (Kashi), UP, India',
    latitude: 25.3176,
    longitude: 82.9739,
    timezone: 'Asia/Kolkata',
    altitudeMeters: 80.0,
  );
}

class PanchaAngaElement {
  final int number;
  final String name;
  final String sanskritName;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? endTimeFormatted;
  final String meaning;
  final String? presidingDeity;

  const PanchaAngaElement({
    required this.number,
    required this.name,
    required this.sanskritName,
    this.startTime,
    this.endTime,
    this.endTimeFormatted,
    required this.meaning,
    this.presidingDeity,
  });

  factory PanchaAngaElement.fromJson(Map<String, dynamic> json) {
    return PanchaAngaElement(
      number: json['number'] as int? ?? 1,
      name: json['name'] as String? ?? '',
      sanskritName: json['sanskrit_name'] as String? ?? '',
      startTime: json['start_time'] != null ? DateTime.tryParse(json['start_time'] as String) : null,
      endTime: json['end_time'] != null ? DateTime.tryParse(json['end_time'] as String) : null,
      endTimeFormatted: json['end_time_formatted'] as String?,
      meaning: json['meaning'] as String? ?? '',
      presidingDeity: json['presiding_deity'] as String?,
    );
  }
}

class TimePeriod {
  final String name;
  final String sanskritName;
  final DateTime startTime;
  final DateTime endTime;
  final String formatted;
  final bool isAuspicious;
  final String description;

  const TimePeriod({
    required this.name,
    required this.sanskritName,
    required this.startTime,
    required this.endTime,
    required this.formatted,
    required this.isAuspicious,
    required this.description,
  });

  factory TimePeriod.fromJson(Map<String, dynamic> json) {
    return TimePeriod(
      name: json['name'] as String? ?? '',
      sanskritName: json['sanskrit_name'] as String? ?? '',
      startTime: DateTime.tryParse(json['start_time'] as String? ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['end_time'] as String? ?? '') ?? DateTime.now(),
      formatted: json['formatted'] as String? ?? '',
      isAuspicious: json['is_auspicious'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }
}

class SunMoonEvents {
  final DateTime? sunrise;
  final String sunriseFormatted;
  final DateTime? sunset;
  final String sunsetFormatted;
  final double dayLengthHours;
  final String dayLengthFormatted;
  final DateTime? solarNoon;
  final DateTime? moonrise;
  final String? moonriseFormatted;
  final DateTime? moonset;
  final String? moonsetFormatted;
  final double moonIlluminationPercent;

  const SunMoonEvents({
    this.sunrise,
    required this.sunriseFormatted,
    this.sunset,
    required this.sunsetFormatted,
    required this.dayLengthHours,
    required this.dayLengthFormatted,
    this.solarNoon,
    this.moonrise,
    this.moonriseFormatted,
    this.moonset,
    this.moonsetFormatted,
    required this.moonIlluminationPercent,
  });

  factory SunMoonEvents.fromJson(Map<String, dynamic> json) {
    return SunMoonEvents(
      sunrise: json['sunrise'] != null ? DateTime.tryParse(json['sunrise'] as String) : null,
      sunriseFormatted: json['sunrise_formatted'] as String? ?? '--:--',
      sunset: json['sunset'] != null ? DateTime.tryParse(json['sunset'] as String) : null,
      sunsetFormatted: json['sunset_formatted'] as String? ?? '--:--',
      dayLengthHours: (json['day_length_hours'] as num?)?.toDouble() ?? 0.0,
      dayLengthFormatted: json['day_length_formatted'] as String? ?? '--',
      solarNoon: json['solar_noon'] != null ? DateTime.tryParse(json['solar_noon'] as String) : null,
      moonrise: json['moonrise'] != null ? DateTime.tryParse(json['moonrise'] as String) : null,
      moonriseFormatted: json['moonrise_formatted'] as String?,
      moonset: json['moonset'] != null ? DateTime.tryParse(json['moonset'] as String) : null,
      moonsetFormatted: json['moonset_formatted'] as String?,
      moonIlluminationPercent: (json['moon_illumination_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Observance {
  final String name;
  final String sanskritName;
  final String category;
  final String description;

  const Observance({
    required this.name,
    required this.sanskritName,
    required this.category,
    required this.description,
  });

  factory Observance.fromJson(Map<String, dynamic> json) {
    return Observance(
      name: json['name'] as String? ?? '',
      sanskritName: json['sanskrit_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class CalculationConventions {
  final String ayanamsaUsed;
  final double ayanamsaValueDegrees;
  final String ayanamsaValueFormatted;
  final String ephemerisEngine;
  final String coordinateSystem;
  final String sunriseConvention;
  final String timeScale;
  final String udayaTithiRule;

  const CalculationConventions({
    required this.ayanamsaUsed,
    required this.ayanamsaValueDegrees,
    required this.ayanamsaValueFormatted,
    required this.ephemerisEngine,
    required this.coordinateSystem,
    required this.sunriseConvention,
    required this.timeScale,
    required this.udayaTithiRule,
  });

  factory CalculationConventions.fromJson(Map<String, dynamic> json) {
    return CalculationConventions(
      ayanamsaUsed: json['ayanamsa_used'] as String? ?? '',
      ayanamsaValueDegrees: (json['ayanamsa_value_degrees'] as num?)?.toDouble() ?? 0.0,
      ayanamsaValueFormatted: json['ayanamsa_value_formatted'] as String? ?? '',
      ephemerisEngine: json['ephemeris_engine'] as String? ?? '',
      coordinateSystem: json['coordinate_system'] as String? ?? '',
      sunriseConvention: json['sunrise_convention'] as String? ?? '',
      timeScale: json['time_scale'] as String? ?? '',
      udayaTithiRule: json['udaya_tithi_rule'] as String? ?? '',
    );
  }
}

class DailyPanchangamData {
  final DateTime calculationTimestampUtc;
  final DateTime requestedDate;
  final PanchangamLocation location;
  final PanchaAngaElement vara;
  final SunMoonEvents sunMoon;
  final PanchaAngaElement tithi;
  final PanchaAngaElement nakshatra;
  final PanchaAngaElement yoga;
  final PanchaAngaElement karana;
  final String paksha;
  final TimePeriod rahuKalam;
  final TimePeriod yamagandam;
  final TimePeriod gulikaKalam;
  final TimePeriod? abhijitMuhurat;
  final TimePeriod? brahmaMuhurta;
  final List<Observance> observances;
  final CalculationConventions conventions;

  const DailyPanchangamData({
    required this.calculationTimestampUtc,
    required this.requestedDate,
    required this.location,
    required this.vara,
    required this.sunMoon,
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.paksha,
    required this.rahuKalam,
    required this.yamagandam,
    required this.gulikaKalam,
    this.abhijitMuhurat,
    this.brahmaMuhurta,
    required this.observances,
    required this.conventions,
  });

  factory DailyPanchangamData.fromJson(Map<String, dynamic> json) {
    return DailyPanchangamData(
      calculationTimestampUtc: DateTime.tryParse(json['calculation_timestamp_utc'] as String? ?? '') ?? DateTime.now(),
      requestedDate: DateTime.tryParse(json['requested_date'] as String? ?? '') ?? DateTime.now(),
      location: PanchangamLocation.fromJson(json['location'] as Map<String, dynamic>),
      vara: PanchaAngaElement.fromJson(json['vara'] as Map<String, dynamic>),
      sunMoon: SunMoonEvents.fromJson(json['sun_moon'] as Map<String, dynamic>),
      tithi: PanchaAngaElement.fromJson(json['tithi'] as Map<String, dynamic>),
      nakshatra: PanchaAngaElement.fromJson(json['nakshatra'] as Map<String, dynamic>),
      yoga: PanchaAngaElement.fromJson(json['yoga'] as Map<String, dynamic>),
      karana: PanchaAngaElement.fromJson(json['karana'] as Map<String, dynamic>),
      paksha: json['paksha'] as String? ?? 'Shukla Paksha',
      rahuKalam: TimePeriod.fromJson(json['rahu_kalam'] as Map<String, dynamic>),
      yamagandam: TimePeriod.fromJson(json['yamagandam'] as Map<String, dynamic>),
      gulikaKalam: TimePeriod.fromJson(json['gulika_kalam'] as Map<String, dynamic>),
      abhijitMuhurat: json['abhijit_muhurat'] != null ? TimePeriod.fromJson(json['abhijit_muhurat'] as Map<String, dynamic>) : null,
      brahmaMuhurta: json['brahma_muhurta'] != null ? TimePeriod.fromJson(json['brahma_muhurta'] as Map<String, dynamic>) : null,
      observances: (json['observances'] as List<dynamic>?)
              ?.map((e) => Observance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      conventions: CalculationConventions.fromJson(json['conventions'] as Map<String, dynamic>),
    );
  }
}
