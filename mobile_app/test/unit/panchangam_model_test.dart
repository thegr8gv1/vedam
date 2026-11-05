import 'package:flutter_test/flutter_test.dart';
import 'package:vedam_app/core/models/panchangam_data.dart';

void main() {
  group('Panchangam Data Model Tests', () {
    test('PanchangamLocation serialization and deserialization', () {
      const loc = PanchangamLocation(
        name: 'Varanasi (Kashi), UP, India',
        latitude: 25.3176,
        longitude: 82.9739,
        timezone: 'Asia/Kolkata',
        altitudeMeters: 80.0,
      );

      final json = loc.toJson();
      expect(json['name'], 'Varanasi (Kashi), UP, India');
      expect(json['latitude'], 25.3176);
      expect(json['longitude'], 82.9739);
      expect(json['timezone'], 'Asia/Kolkata');

      final fromJson = PanchangamLocation.fromJson(json);
      expect(fromJson.name, loc.name);
      expect(fromJson.latitude, loc.latitude);
      expect(fromJson.longitude, loc.longitude);
      expect(fromJson.timezone, loc.timezone);
      expect(fromJson.altitudeMeters, 80.0);
    });

    test('DailyPanchangamData parsed from comprehensive JSON map', () {
      final sampleJson = {
        'calculation_timestamp_utc': '2026-11-05T12:00:00Z',
        'requested_date': '2026-11-05',
        'location': {
          'name': 'Chennai, Tamil Nadu, India',
          'latitude': 13.0827,
          'longitude': 80.2707,
          'timezone': 'Asia/Kolkata',
          'altitude_meters': 6.0,
        },
        'vara': {
          'number': 5,
          'name': 'Guruvara',
          'sanskrit_name': 'गुरुवार (Thursday)',
          'meaning': 'Brihaspati worship, study, wisdom',
          'presiding_deity': 'Brihaspati (Jupiter)',
        },
        'sun_moon': {
          'sunrise': '2026-11-05T06:03:00+05:30',
          'sunrise_formatted': '06:03 AM',
          'sunset': '2026-11-05T17:41:00+05:30',
          'sunset_formatted': '05:41 PM',
          'day_length_hours': 11.63,
          'day_length_formatted': '11h 38m',
          'moon_illumination_percent': 18.5,
        },
        'tithi': {
          'number': 26,
          'name': 'Krishna Ekadashi',
          'sanskrit_name': 'कृष्ण एकादशी',
          'end_time_formatted': '10:35 AM',
          'meaning': 'Sacred fasting and Vishnu devotion',
          'presiding_deity': 'Vishnu',
        },
        'nakshatra': {
          'number': 12,
          'name': 'Uttara Phalguni',
          'sanskrit_name': 'उत्तर फाल्गुनी',
          'end_time_formatted': '03:55 AM',
          'meaning': 'Noble friendship, dharma vows',
          'presiding_deity': 'Aryaman',
        },
        'yoga': {
          'number': 26,
          'name': 'Aindra (Indra)',
          'sanskrit_name': 'ऐन्द्र',
          'end_time_formatted': '07:12 PM',
          'meaning': 'Nobility, strength',
        },
        'karana': {
          'number': 52,
          'name': 'Balava',
          'sanskrit_name': 'बालव',
          'end_time_formatted': '10:35 AM',
          'meaning': 'Spiritual growth',
        },
        'paksha': 'Krishna Paksha (Waning)',
        'rahu_kalam': {
          'name': 'Rahu Kalam',
          'sanskrit_name': 'राहुकाल',
          'start_time': '2026-11-05T13:19:00+05:30',
          'end_time': '2026-11-05T14:46:00+05:30',
          'formatted': '01:19 PM - 02:46 PM',
          'is_auspicious': false,
          'description': '1/8th daylight interval ruled by Rahu',
        },
        'yamagandam': {
          'name': 'Yamagandam',
          'sanskrit_name': 'यमगण्ड',
          'start_time': '2026-11-05T06:03:00+05:30',
          'end_time': '2026-11-05T07:30:00+05:30',
          'formatted': '06:03 AM - 07:30 AM',
          'is_auspicious': false,
          'description': 'Ruled by Yama',
        },
        'gulika_kalam': {
          'name': 'Gulika Kalam',
          'sanskrit_name': 'गुलिक काल',
          'start_time': '2026-11-05T08:57:00+05:30',
          'end_time': '2026-11-05T10:24:00+05:30',
          'formatted': '08:57 AM - 10:24 AM',
          'is_auspicious': true,
          'description': 'Ruled by Gulika',
        },
        'abhijit_muhurat': {
          'name': 'Abhijit Muhurat',
          'sanskrit_name': 'अभिजित् मुहूर्त',
          'start_time': '2026-11-05T11:29:00+05:30',
          'end_time': '2026-11-05T12:15:00+05:30',
          'formatted': '11:29 AM - 12:15 PM',
          'is_auspicious': true,
          'description': 'Midday 8th muhurta centered at solar noon',
        },
        'observances': [
          {
            'name': 'Krishna Ekadashi Vratam',
            'sanskrit_name': 'कृष्ण एकादशी व्रतम्',
            'category': 'Ekadashi',
            'description': 'Rama Ekadashi fasting',
            'is_informational': true,
            'disclaimer': 'Calculated from Udaya Tithi. Vaishnava and Smartha traditions may differ.',
          }
        ],
        'conventions': {
          'ayanamsa_used': 'Lahiri (Chitra Paksha)',
          'ayanamsa_value_degrees': 24.2321,
          'ayanamsa_value_formatted': '24° 13\' 55.59"',
          'ephemeris_engine': 'Astronomy Engine 2.1 (VSOP87/ELP2000-82)',
          'coordinate_system': 'Geocentric apparent ecliptic',
          'sunrise_convention': 'Center of solar disc at -50\'',
          'time_scale': 'TT to UTC via Delta-T',
          'udaya_tithi_rule': 'Tithi at local sunrise governs liturgical day',
        },
      };

      final data = DailyPanchangamData.fromJson(sampleJson);
      expect(data.location.name, 'Chennai, Tamil Nadu, India');
      expect(data.vara.name, 'Guruvara');
      expect(data.tithi.name, 'Krishna Ekadashi');
      expect(data.tithi.endTimeFormatted, '10:35 AM');
      expect(data.nakshatra.name, 'Uttara Phalguni');
      expect(data.yoga.name, 'Aindra (Indra)');
      expect(data.karana.name, 'Balava');
      expect(data.rahuKalam.formatted, '01:19 PM - 02:46 PM');
      expect(data.abhijitMuhurat?.formatted, '11:29 AM - 12:15 PM');
      expect(data.observances.length, 1);
      expect(data.observances.first.name, 'Krishna Ekadashi Vratam');
      expect(data.observances.first.isInformational, isTrue);
      expect(data.observances.first.disclaimer, contains('Vaishnava and Smartha'));
      expect(data.conventions.ayanamsaUsed, 'Lahiri (Chitra Paksha)');
    });
  });
}
