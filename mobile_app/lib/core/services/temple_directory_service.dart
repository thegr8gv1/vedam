import '../models/temple.dart';
import '../../data/fixtures/authentic_temples_data.dart';

/// Service responsible for managing, querying, and filtering sacred temple directory records.
/// In Phase 22A, this serves the curated provisional dataset of 20 user-researched temples.
class TempleDirectoryService {
  final List<Temple> _temples;

  TempleDirectoryService({List<Temple>? temples})
      : _temples = List.unmodifiable(temples ?? AuthenticTemplesData.initialTemples);

  /// Returns all available temple records.
  List<Temple> getAllTemples() => _temples;

  /// Retrieves a single temple by its unique identifier.
  Temple? getTempleById(String id) {
    try {
      return _temples.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Filters temples by search text, country, tradition, and verification status.
  List<Temple> searchAndFilter({
    String? query,
    String? country,
    TempleTradition? tradition,
    CoordinateVerificationStatus? status,
  }) {
    return _temples.where((temple) {
      if (country != null && country.isNotEmpty && country != 'All') {
        if (temple.country.toLowerCase() != country.toLowerCase()) {
          return false;
        }
      }

      if (tradition != null && temple.tradition != tradition) {
        return false;
      }

      if (status != null && temple.verificationStatus != status) {
        return false;
      }

      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesName = temple.name.toLowerCase().contains(q);
        final matchesDeity = temple.deity.toLowerCase().contains(q);
        final matchesCity = temple.city.toLowerCase().contains(q);
        final matchesState = temple.state.toLowerCase().contains(q);
        final matchesCountry = temple.country.toLowerCase().contains(q);
        final matchesAliases = temple.alternateNames.any((a) => a.toLowerCase().contains(q));
        if (!matchesName && !matchesDeity && !matchesCity && !matchesState && !matchesCountry && !matchesAliases) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Returns the distinct set of countries represented in the directory.
  List<String> getAvailableCountries() {
    final countries = _temples.map((t) => t.country).toSet().toList();
    countries.sort();
    return countries;
  }

  /// Returns the distinct set of traditions represented in the directory.
  List<TempleTradition> getAvailableTraditions() {
    final traditions = _temples.map((t) => t.tradition).toSet().toList();
    traditions.sort((a, b) => a.label.compareTo(b.label));
    return traditions;
  }
}
