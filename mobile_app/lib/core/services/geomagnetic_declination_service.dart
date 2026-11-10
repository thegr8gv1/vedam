import 'dart:math' as math;
import '../models/declination_model.dart';
import '../models/sacred_origin.dart';

/// Single Gauss coefficient entry in the World Magnetic Model.
class WmmCoeff {
  final int n;
  final int m;
  final double gnm;
  final double hnm;
  final double dgnm;
  final double dhnm;

  const WmmCoeff(this.n, this.m, this.gnm, this.hnm, this.dgnm, this.dhnm);
}

/// Offline geomagnetic declination calculator implementing the official NOAA / NCEI
/// World Magnetic Model (WMM) spherical harmonic expansion.
///
/// Features:
/// - 100% offline, pure Dart execution across all platforms (Android, Web, iOS, Desktop).
/// - Zero external dependencies, zero location tracking, zero background processes.
/// - Bundles official NOAA WMM-2025 (valid 2025.0 - 2030.0) and WMM-2020 (valid 2020.0 - 2025.0).
/// - East-positive (+) / West-negative (-) standard scientific convention.
class GeomagneticDeclinationService {
  static const int maxord = 12;
  static const int size = maxord + 1;

  // Earth ellipsoid parameters (WGS-84)
  static const double _a = 6378.137;
  static const double _b = 6356.7523142;
  static const double _re = 6371.2;
  static const double _a2 = _a * _a;
  static const double _b2 = _b * _b;
  static const double _c2 = _a2 - _b2;
  static const double _a4 = _a2 * _a2;
  static const double _b4 = _b2 * _b2;
  static const double _c4 = _a4 - _b4;

  const GeomagneticDeclinationService();

  /// Converts a [DateTime] into a decimal year representation (e.g. 2026.861).
  static double calculateDecimalYear(DateTime dt) {
    final year = dt.year;
    final isLeap = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    final daysInYear = isLeap ? 366.0 : 365.0;
    final startOfYear = DateTime(year, 1, 1);
    final differenceInDays = dt.difference(startOfYear).inMicroseconds / (1000000.0 * 86400.0);
    return year + (differenceInDays / daysInYear);
  }

  /// Calculates magnetic declination for an explicit [origin] point.
  ///
  /// Rejects null, non-finite, out-of-bounds coordinates, and dates outside model validity.
  DeclinationResult calculateDeclination({
    required SacredOrigin origin,
    double? altitudeKm,
    DateTime? date,
    GeomagneticModelType? modelType,
  }) {
    final lat = origin.coordinate.latitude;
    final lon = origin.coordinate.longitude;
    final alt = altitudeKm ?? 0.0;
    final calcDate = date ?? DateTime.now();

    // 1. Guard non-finite values
    if (lat.isNaN || lat.isInfinite || lon.isNaN || lon.isInfinite || alt.isNaN || alt.isInfinite) {
      return DeclinationResult.unavailable(
        modelType: modelType ?? GeomagneticModelType.wmm2025,
        origin: origin,
        status: DeclinationStatus.nonFiniteInput,
        message: 'Input latitude, longitude, or altitude contains NaN or Infinite values.',
        timestamp: calcDate,
      );
    }

    // 2. Guard geographic coordinate boundaries
    if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 360.0) {
      return DeclinationResult.unavailable(
        modelType: modelType ?? GeomagneticModelType.wmm2025,
        origin: origin,
        status: DeclinationStatus.invalidCoordinates,
        message: 'Coordinates out of valid bounds: lat must be in [-90, 90], lon in [-180, 180] or [0, 360].',
        timestamp: calcDate,
      );
    }

    // Normalize longitude to [-180, 180]
    final normalizedLon = lon > 180.0 ? lon - 360.0 : lon;

    // 3. Resolve decimal year and model type
    final decimalYear = calculateDecimalYear(calcDate);
    final selectedModel = modelType ?? _selectModelForYear(decimalYear);

    // 4. Validate model epoch and date bounds
    if (!selectedModel.isDateSupported(decimalYear)) {
      return DeclinationResult.unavailable(
        modelType: selectedModel,
        origin: origin,
        status: DeclinationStatus.modelExpired,
        message: 'Date ($decimalYear) is outside ${selectedModel.name} validity period '
            '(${selectedModel.validityStartYear} - ${selectedModel.validityEndYear}).',
        timestamp: calcDate,
        decimalYear: decimalYear,
      );
    }

    // 5. Run spherical harmonic calculation
    try {
      final (dec, dip, ti, bh) = _computeWmm(
        model: selectedModel,
        latDeg: lat,
        lonDeg: normalizedLon,
        altKm: alt,
        decimalYear: decimalYear,
      );

      // Check for magnetic pole caution / blackout zones
      DeclinationStatus status = DeclinationStatus.valid;
      String? message;
      if (bh < 2000.0) {
        status = DeclinationStatus.blackoutZone;
        message = 'Compass readings highly unreliable: horizontal magnetic field < 2000 nT near magnetic pole.';
      } else if (bh < 6000.0) {
        status = DeclinationStatus.cautionZone;
        message = 'Compass readings degraded: horizontal magnetic field < 6000 nT near auroral/polar zone.';
      }

      // Uncertainty calculation via official NOAA WMM formula
      // sigma_D = sqrt(0.26^2 + (5417 / H)^2) for WMM-2025
      final uncertaintyCoeff = selectedModel == GeomagneticModelType.wmm2025 ? 5417.0 : 5625.0;
      final baseUnc = selectedModel == GeomagneticModelType.wmm2025 ? 0.26 : 0.26;
      final estUnc = math.sqrt(baseUnc * baseUnc + (uncertaintyCoeff / bh) * (uncertaintyCoeff / bh));

      return DeclinationResult.valid(
        declinationDegrees: dec,
        modelType: selectedModel,
        timestamp: calcDate,
        decimalYear: decimalYear,
        origin: origin,
        altitudeKm: alt,
        horizontalIntensityNt: bh,
        totalIntensityNt: ti,
        estimatedUncertaintyDegrees: estUnc,
        status: status,
        message: message,
      );
    } catch (e) {
      return DeclinationResult.unavailable(
        modelType: selectedModel,
        origin: origin,
        status: DeclinationStatus.unavailable,
        message: 'Geomagnetic computation error: $e',
        timestamp: calcDate,
        decimalYear: decimalYear,
      );
    }
  }

  static GeomagneticModelType _selectModelForYear(double decimalYear) {
    if (decimalYear >= 2025.0 && decimalYear < 2030.0) {
      return GeomagneticModelType.wmm2025;
    } else if (decimalYear >= 2020.0 && decimalYear < 2025.0) {
      return GeomagneticModelType.wmm2020;
    }
    // Default to WMM-2025 if in future
    return GeomagneticModelType.wmm2025;
  }

  /// Internal NOAA WMM spherical harmonic expansion engine.
  static (double dec, double dip, double ti, double bh) _computeWmm({
    required GeomagneticModelType model,
    required double latDeg,
    required double lonDeg,
    required double altKm,
    required double decimalYear,
  }) {
    final coeffs = model == GeomagneticModelType.wmm2025 ? _wmm2025Coeffs : _wmm2020Coeffs;
    final epoch = model.epoch;

    final c = List.generate(size, (_) => List.filled(size, 0.0));
    final cd = List.generate(size, (_) => List.filled(size, 0.0));
    final p = List.filled(size * size, 0.0);
    final fn = List.filled(size, 0.0);
    final fm = List.filled(size, 0.0);
    final k = List.generate(size, (_) => List.filled(size, 0.0));

    // Populate coefficient matrices
    for (final coeff in coeffs) {
      if (coeff.m <= coeff.n) {
        c[coeff.m][coeff.n] = coeff.gnm;
        cd[coeff.m][coeff.n] = coeff.dgnm;
        if (coeff.m != 0) {
          c[coeff.n][coeff.m - 1] = coeff.hnm;
          cd[coeff.n][coeff.m - 1] = coeff.dhnm;
        }
      }
    }

    // Convert Schmidt quasi-normalized coefficients to unnormalized
    p[0] = 1.0;
    fm[0] = 0.0;
    for (int n = 1; n <= maxord; n++) {
      p[n] = p[n - 1] * (2 * n - 1) / n;
      int j = 2;
      int m = 0;
      int d2 = n - m + 1;
      while (d2 > 0) {
        k[m][n] = (((n - 1) * (n - 1)) - (m * m)) / ((2 * n - 1) * (2 * n - 3));
        if (m > 0) {
          final flnmj = ((n - m + 1) * j) / (n + m);
          p[n + m * size] = p[n + (m - 1) * size] * math.sqrt(flnmj);
          j = 1;
          c[n][m - 1] = p[n + m * size] * c[n][m - 1];
          cd[n][m - 1] = p[n + m * size] * cd[n][m - 1];
        }
        c[m][n] = p[n + m * size] * c[m][n];
        cd[m][n] = p[n + m * size] * cd[m][n];
        d2 -= 1;
        m += 1;
      }
      fn[n] = (n + 1).toDouble();
      fm[n] = n.toDouble();
    }
    k[1][1] = 0.0;

    final tc = List.generate(size, (_) => List.filled(size, 0.0));
    final dp = List.generate(size, (_) => List.filled(size, 0.0));
    final sp = List.filled(size, 0.0);
    final cp = List.filled(size, 0.0);
    final pp = List.filled(size, 0.0);

    sp[0] = 0.0;
    cp[0] = pp[0] = 1.0;
    dp[0][0] = 0.0;

    final dt = decimalYear - epoch;
    final rlon = lonDeg * math.pi / 180.0;
    final rlat = latDeg * math.pi / 180.0;
    final srlon = math.sin(rlon);
    final srlat = math.sin(rlat);
    final crlon = math.cos(rlon);
    final crlat = math.cos(rlat);
    final srlat2 = srlat * srlat;
    final crlat2 = crlat * crlat;
    sp[1] = srlon;
    cp[1] = crlon;

    // Convert geodetic coordinates to spherical coordinates on WGS-84 ellipsoid
    final q = math.sqrt(_a2 - _c2 * srlat2);
    final q1 = altKm * q;
    final q2 = ((q1 + _a2) / (q1 + _b2)) * ((q1 + _a2) / (q1 + _b2));
    final ct = srlat / math.sqrt(q2 * crlat2 + srlat2);
    final st = math.sqrt(1.0 - (ct * ct));
    final r2 = (altKm * altKm) + 2.0 * q1 + (_a4 - _c4 * srlat2) / (q * q);
    final r = math.sqrt(r2);
    final d = math.sqrt(_a2 * crlat2 + _b2 * srlat2);
    final ca = (altKm + d) / r;
    final sa = _c2 * crlat * srlat / (r * d);

    for (int m = 2; m <= maxord; m++) {
      sp[m] = sp[1] * cp[m - 1] + cp[1] * sp[m - 1];
      cp[m] = cp[1] * cp[m - 1] - sp[1] * sp[m - 1];
    }

    final aor = _re / r;
    var ar = aor * aor;
    var br = 0.0;
    var bt = 0.0;
    var bp = 0.0;
    var bpp = 0.0;

    for (int n = 1; n <= maxord; n++) {
      ar = ar * aor;
      int m = 0;
      int d4 = n + m + 1;
      while (d4 > 0) {
        if (n == m) {
          p[n + m * size] = st * p[n - 1 + (m - 1) * size];
          dp[m][n] = st * dp[m - 1][n - 1] + ct * p[n - 1 + (m - 1) * size];
        } else if (n == 1 && m == 0) {
          p[n + m * size] = ct * p[n - 1 + m * size];
          dp[m][n] = ct * dp[m][n - 1] - st * p[n - 1 + m * size];
        } else if (n > 1 && n != m) {
          if (m > n - 2) {
            p[n - 2 + m * size] = 0.0;
            dp[m][n - 2] = 0.0;
          }
          p[n + m * size] = ct * p[n - 1 + m * size] - k[m][n] * p[n - 2 + m * size];
          dp[m][n] = ct * dp[m][n - 1] - st * p[n - 1 + m * size] - k[m][n] * dp[m][n - 2];
        }

        tc[m][n] = c[m][n] + dt * cd[m][n];
        if (m != 0) {
          tc[n][m - 1] = c[n][m - 1] + dt * cd[n][m - 1];
        }

        final par = ar * p[n + m * size];
        double temp1;
        double temp2;
        if (m == 0) {
          temp1 = tc[m][n] * cp[m];
          temp2 = tc[m][n] * sp[m];
        } else {
          temp1 = tc[m][n] * cp[m] + tc[n][m - 1] * sp[m];
          temp2 = tc[m][n] * sp[m] - tc[n][m - 1] * cp[m];
        }

        bt = bt - ar * temp1 * dp[m][n];
        bp += fm[m] * temp2 * par;
        br += fn[n] * temp1 * par;

        if (st == 0.0 && m == 1) {
          if (n == 1) {
            pp[n] = pp[n - 1];
          } else {
            pp[n] = ct * pp[n - 1] - k[m][n] * pp[n - 2];
          }
          final parp = ar * pp[n];
          bpp += fm[m] * temp2 * parp;
        }

        d4 -= 1;
        m += 1;
      }
    }

    if (st == 0.0) {
      bp = bpp;
    } else {
      bp /= st;
    }

    final bx = -bt * ca - br * sa;
    final by = bp;
    final bz = bt * sa - br * ca;

    final bh = math.sqrt((bx * bx) + (by * by));
    final ti = math.sqrt((bh * bh) + (bz * bz));
    final dec = math.atan2(by, bx) * 180.0 / math.pi;
    final dip = math.atan2(bz, bh) * 180.0 / math.pi;

    return (dec, dip, ti, bh);
  }

  // Official NOAA WMM-2025 Coefficients (Epoch 2025.0 - 2030.0)
  static const List<WmmCoeff> _wmm2025Coeffs = [
    WmmCoeff(1, 0, -29351.8, 0.0, 12.0, 0.0),
    WmmCoeff(1, 1, -1410.8, 4545.4, 9.7, -21.5),
    WmmCoeff(2, 0, -2556.6, 0.0, -11.6, 0.0),
    WmmCoeff(2, 1, 2951.1, -3133.6, -5.2, -27.7),
    WmmCoeff(2, 2, 1649.3, -815.1, -8.0, -12.1),
    WmmCoeff(3, 0, 1361.0, 0.0, -1.3, 0.0),
    WmmCoeff(3, 1, -2404.1, -56.6, -4.2, 4.0),
    WmmCoeff(3, 2, 1243.8, 237.5, 0.4, -0.3),
    WmmCoeff(3, 3, 453.6, -549.5, -15.6, -4.1),
    WmmCoeff(4, 0, 895.0, 0.0, -1.6, 0.0),
    WmmCoeff(4, 1, 799.5, 278.6, -2.4, -1.1),
    WmmCoeff(4, 2, 55.7, -133.9, -6.0, 4.1),
    WmmCoeff(4, 3, -281.1, 212.0, 5.6, 1.6),
    WmmCoeff(4, 4, 12.1, -375.6, -7.0, -4.4),
    WmmCoeff(5, 0, -233.2, 0.0, 0.6, 0.0),
    WmmCoeff(5, 1, 368.9, 45.4, 1.4, -0.5),
    WmmCoeff(5, 2, 187.2, 220.2, 0.0, 2.2),
    WmmCoeff(5, 3, -138.7, -122.9, 0.6, 0.4),
    WmmCoeff(5, 4, -142.0, 43.0, 2.2, 1.7),
    WmmCoeff(5, 5, 20.9, 106.1, 0.9, 1.9),
    WmmCoeff(6, 0, 64.4, 0.0, -0.2, 0.0),
    WmmCoeff(6, 1, 63.8, -18.4, -0.4, 0.3),
    WmmCoeff(6, 2, 76.9, 16.8, 0.9, -1.6),
    WmmCoeff(6, 3, -115.7, 48.8, 1.2, -0.4),
    WmmCoeff(6, 4, -40.9, -59.8, -0.9, 0.9),
    WmmCoeff(6, 5, 14.9, 10.9, 0.3, 0.7),
    WmmCoeff(6, 6, -60.7, 72.7, 0.9, 0.9),
    WmmCoeff(7, 0, 79.5, 0.0, -0.0, 0.0),
    WmmCoeff(7, 1, -77.0, -48.9, -0.1, 0.6),
    WmmCoeff(7, 2, -8.8, -14.4, -0.1, 0.5),
    WmmCoeff(7, 3, 59.3, -1.0, 0.5, -0.8),
    WmmCoeff(7, 4, 15.8, 23.4, -0.1, 0.0),
    WmmCoeff(7, 5, 2.5, -7.4, -0.8, -1.0),
    WmmCoeff(7, 6, -11.1, -25.1, -0.8, 0.6),
    WmmCoeff(7, 7, 14.2, -2.3, 0.8, -0.2),
    WmmCoeff(8, 0, 23.2, 0.0, -0.1, 0.0),
    WmmCoeff(8, 1, 10.8, 7.1, 0.2, -0.2),
    WmmCoeff(8, 2, -17.5, -12.6, 0.0, 0.5),
    WmmCoeff(8, 3, 2.0, 11.4, 0.5, -0.4),
    WmmCoeff(8, 4, -21.7, -9.7, -0.1, 0.4),
    WmmCoeff(8, 5, 16.9, 12.7, 0.3, -0.5),
    WmmCoeff(8, 6, 15.0, 0.7, 0.2, -0.6),
    WmmCoeff(8, 7, -16.8, -5.2, -0.0, 0.3),
    WmmCoeff(8, 8, 0.9, 3.9, 0.2, 0.2),
    WmmCoeff(9, 0, 4.6, 0.0, -0.0, 0.0),
    WmmCoeff(9, 1, 7.8, -24.8, -0.1, -0.3),
    WmmCoeff(9, 2, 3.0, 12.2, 0.1, 0.3),
    WmmCoeff(9, 3, -0.2, 8.3, 0.3, -0.3),
    WmmCoeff(9, 4, -2.5, -3.3, -0.3, 0.3),
    WmmCoeff(9, 5, -13.1, -5.2, 0.0, 0.2),
    WmmCoeff(9, 6, 2.4, 7.2, 0.3, -0.1),
    WmmCoeff(9, 7, 8.6, -0.6, -0.1, -0.2),
    WmmCoeff(9, 8, -8.7, 0.8, 0.1, 0.4),
    WmmCoeff(9, 9, -12.9, 10.0, -0.1, 0.1),
    WmmCoeff(10, 0, -1.3, 0.0, 0.1, 0.0),
    WmmCoeff(10, 1, -6.4, 3.3, 0.0, 0.0),
    WmmCoeff(10, 2, 0.2, 0.0, 0.1, -0.0),
    WmmCoeff(10, 3, 2.0, 2.4, 0.1, -0.2),
    WmmCoeff(10, 4, -1.0, 5.3, -0.0, 0.1),
    WmmCoeff(10, 5, -0.6, -9.1, -0.3, -0.1),
    WmmCoeff(10, 6, -0.9, 0.4, 0.0, 0.1),
    WmmCoeff(10, 7, 1.5, -4.2, -0.1, 0.0),
    WmmCoeff(10, 8, 0.9, -3.8, -0.1, -0.1),
    WmmCoeff(10, 9, -2.7, 0.9, -0.0, 0.2),
    WmmCoeff(10, 10, -3.9, -9.1, -0.0, -0.0),
    WmmCoeff(11, 0, 2.9, 0.0, 0.0, 0.0),
    WmmCoeff(11, 1, -1.5, 0.0, -0.0, -0.0),
    WmmCoeff(11, 2, -2.5, 2.9, 0.0, 0.1),
    WmmCoeff(11, 3, 2.4, -0.6, 0.0, -0.0),
    WmmCoeff(11, 4, -0.6, 0.2, 0.0, 0.1),
    WmmCoeff(11, 5, -0.1, 0.5, -0.1, -0.0),
    WmmCoeff(11, 6, -0.6, -0.3, 0.0, -0.0),
    WmmCoeff(11, 7, -0.1, -1.2, -0.0, 0.1),
    WmmCoeff(11, 8, 1.1, -1.7, -0.1, -0.0),
    WmmCoeff(11, 9, -1.0, -2.9, -0.1, 0.0),
    WmmCoeff(11, 10, -0.2, -1.8, -0.1, 0.0),
    WmmCoeff(11, 11, 2.6, -2.3, -0.1, 0.0),
    WmmCoeff(12, 0, -2.0, 0.0, 0.0, 0.0),
    WmmCoeff(12, 1, -0.2, -1.3, 0.0, -0.0),
    WmmCoeff(12, 2, 0.3, 0.7, -0.0, 0.0),
    WmmCoeff(12, 3, 1.2, 1.0, -0.0, -0.1),
    WmmCoeff(12, 4, -1.3, -1.4, -0.0, 0.1),
    WmmCoeff(12, 5, 0.6, -0.0, -0.0, -0.0),
    WmmCoeff(12, 6, 0.6, 0.6, 0.1, -0.0),
    WmmCoeff(12, 7, 0.5, -0.1, -0.0, -0.0),
    WmmCoeff(12, 8, -0.1, 0.8, 0.0, 0.0),
    WmmCoeff(12, 9, -0.4, 0.1, 0.0, -0.0),
    WmmCoeff(12, 10, -0.2, -1.0, -0.1, -0.0),
    WmmCoeff(12, 11, -1.3, 0.1, -0.0, 0.0),
    WmmCoeff(12, 12, -0.7, 0.2, -0.1, -0.1),
  ];

  // Official NOAA WMM-2020 Coefficients (Epoch 2020.0 - 2025.0)
  static const List<WmmCoeff> _wmm2020Coeffs = [
    WmmCoeff(1, 0, -29404.5, 0.0, 6.7, 0.0),
    WmmCoeff(1, 1, -1450.7, 4652.9, 7.7, -25.1),
    WmmCoeff(2, 0, -2500.0, 0.0, -11.5, 0.0),
    WmmCoeff(2, 1, 2982.0, -2991.6, -7.1, -30.2),
    WmmCoeff(2, 2, 1676.8, -734.8, -2.2, -23.9),
    WmmCoeff(3, 0, 1363.9, 0.0, 2.8, 0.0),
    WmmCoeff(3, 1, -2381.0, -82.2, -6.2, 5.7),
    WmmCoeff(3, 2, 1236.2, 241.8, 3.4, -1.0),
    WmmCoeff(3, 3, 525.7, -542.9, -12.2, 1.1),
    WmmCoeff(4, 0, 903.1, 0.0, -1.1, 0.0),
    WmmCoeff(4, 1, 809.4, 282.0, -1.6, 0.2),
    WmmCoeff(4, 2, 86.2, -158.4, -6.0, 6.9),
    WmmCoeff(4, 3, -309.4, 199.8, 5.4, 3.7),
    WmmCoeff(4, 4, 47.9, -350.1, -5.5, -5.6),
    WmmCoeff(5, 0, -234.4, 0.0, -0.3, 0.0),
    WmmCoeff(5, 1, 363.1, 47.7, 0.6, 0.1),
    WmmCoeff(5, 2, 187.8, 208.4, -0.7, 2.5),
    WmmCoeff(5, 3, -140.7, -121.3, 0.1, -0.9),
    WmmCoeff(5, 4, -151.2, 32.2, 1.2, 3.0),
    WmmCoeff(5, 5, 13.7, 99.1, 1.0, 0.5),
    WmmCoeff(6, 0, 65.9, 0.0, -0.6, 0.0),
    WmmCoeff(6, 1, 65.6, -19.1, -0.4, 0.1),
    WmmCoeff(6, 2, 73.0, 25.0, 0.5, -1.8),
    WmmCoeff(6, 3, -121.5, 52.7, 1.4, -1.4),
    WmmCoeff(6, 4, -36.2, -64.4, -1.4, 0.9),
    WmmCoeff(6, 5, 13.5, 9.0, -0.0, 0.1),
    WmmCoeff(6, 6, -64.7, 68.1, 0.8, 1.0),
    WmmCoeff(7, 0, 80.6, 0.0, -0.1, 0.0),
    WmmCoeff(7, 1, -76.8, -51.4, -0.3, 0.5),
    WmmCoeff(7, 2, -8.3, -16.8, -0.1, 0.6),
    WmmCoeff(7, 3, 56.5, 2.3, 0.7, -0.7),
    WmmCoeff(7, 4, 15.8, 23.5, 0.2, -0.2),
    WmmCoeff(7, 5, 6.4, -2.2, -0.5, -1.2),
    WmmCoeff(7, 6, -7.2, -27.2, -0.8, 0.2),
    WmmCoeff(7, 7, 9.8, -1.9, 1.0, 0.3),
    WmmCoeff(8, 0, 23.6, 0.0, -0.1, 0.0),
    WmmCoeff(8, 1, 9.8, 8.4, 0.1, -0.3),
    WmmCoeff(8, 2, -17.5, -15.3, -0.1, 0.7),
    WmmCoeff(8, 3, -0.4, 12.8, 0.5, -0.2),
    WmmCoeff(8, 4, -21.1, -11.8, -0.1, 0.5),
    WmmCoeff(8, 5, 15.3, 14.9, 0.4, -0.3),
    WmmCoeff(8, 6, 13.7, 3.6, 0.5, -0.5),
    WmmCoeff(8, 7, -16.5, -6.9, 0.0, 0.4),
    WmmCoeff(8, 8, -0.3, 2.8, 0.4, 0.1),
    WmmCoeff(9, 0, 5.0, 0.0, -0.1, 0.0),
    WmmCoeff(9, 1, 8.2, -23.3, -0.2, -0.3),
    WmmCoeff(9, 2, 2.9, 11.1, -0.0, 0.2),
    WmmCoeff(9, 3, -1.4, 9.8, 0.4, -0.4),
    WmmCoeff(9, 4, -1.1, -5.1, -0.3, 0.4),
    WmmCoeff(9, 5, -13.3, -6.2, -0.0, 0.1),
    WmmCoeff(9, 6, 1.1, 7.8, 0.3, -0.0),
    WmmCoeff(9, 7, 8.9, 0.4, -0.0, -0.2),
    WmmCoeff(9, 8, -9.3, -1.5, -0.0, 0.5),
    WmmCoeff(9, 9, -11.9, 9.7, -0.4, 0.2),
    WmmCoeff(10, 0, -1.9, 0.0, 0.0, 0.0),
    WmmCoeff(10, 1, -6.2, 3.4, -0.0, -0.0),
    WmmCoeff(10, 2, -0.1, -0.2, -0.0, 0.1),
    WmmCoeff(10, 3, 1.7, 3.5, 0.2, -0.3),
    WmmCoeff(10, 4, -0.9, 4.8, -0.1, 0.1),
    WmmCoeff(10, 5, 0.6, -8.6, -0.2, -0.2),
    WmmCoeff(10, 6, -0.9, -0.1, -0.0, 0.1),
    WmmCoeff(10, 7, 1.9, -4.2, -0.1, -0.0),
    WmmCoeff(10, 8, 1.4, -3.4, -0.2, -0.1),
    WmmCoeff(10, 9, -2.4, -0.1, -0.1, 0.2),
    WmmCoeff(10, 10, -3.9, -8.8, -0.0, -0.0),
    WmmCoeff(11, 0, 3.0, 0.0, -0.0, 0.0),
    WmmCoeff(11, 1, -1.4, -0.0, -0.1, -0.0),
    WmmCoeff(11, 2, -2.5, 2.6, -0.0, 0.1),
    WmmCoeff(11, 3, 2.4, -0.5, 0.0, 0.0),
    WmmCoeff(11, 4, -0.9, -0.4, -0.0, 0.2),
    WmmCoeff(11, 5, 0.3, 0.6, -0.1, -0.0),
    WmmCoeff(11, 6, -0.7, -0.2, 0.0, 0.0),
    WmmCoeff(11, 7, -0.1, -1.7, -0.0, 0.1),
    WmmCoeff(11, 8, 1.4, -1.6, -0.1, -0.0),
    WmmCoeff(11, 9, -0.6, -3.0, -0.1, -0.1),
    WmmCoeff(11, 10, 0.2, -2.0, -0.1, 0.0),
    WmmCoeff(11, 11, 3.1, -2.6, -0.1, -0.0),
    WmmCoeff(12, 0, -2.0, 0.0, 0.0, 0.0),
    WmmCoeff(12, 1, -0.1, -1.2, -0.0, -0.0),
    WmmCoeff(12, 2, 0.5, 0.5, -0.0, 0.0),
    WmmCoeff(12, 3, 1.3, 1.3, 0.0, -0.1),
    WmmCoeff(12, 4, -1.2, -1.8, -0.0, 0.1),
    WmmCoeff(12, 5, 0.7, 0.1, -0.0, -0.0),
    WmmCoeff(12, 6, 0.3, 0.7, 0.0, 0.0),
    WmmCoeff(12, 7, 0.5, -0.1, -0.0, -0.0),
    WmmCoeff(12, 8, -0.2, 0.6, 0.0, 0.1),
    WmmCoeff(12, 9, -0.5, 0.2, -0.0, -0.0),
    WmmCoeff(12, 10, 0.1, -0.9, -0.0, -0.0),
    WmmCoeff(12, 11, -1.1, -0.0, -0.0, 0.0),
    WmmCoeff(12, 12, -0.3, 0.5, -0.1, -0.1),
  ];
}
