import '../../core/models/mantra_item.dart';
import '../fixtures/authentic_mantras_data.dart';

abstract class MantraRepository {
  List<MantraItem> getAllMantras();
  List<String> getAllCollections();
  List<String> getAllDeities();
  List<MantraItem> getMantrasByCollection(String collection);
  List<MantraItem> getMantrasByDeity(String deity);
  List<MantraItem> getBundledMantras();
  List<MantraItem> searchMantras(String query);
  MantraItem? getMantraById(String id);
}

class MantraRepositoryImpl implements MantraRepository {
  final List<MantraItem> _mantras;

  MantraRepositoryImpl({List<MantraItem>? customMantras})
      : _mantras = customMantras ?? AuthenticMantrasData.allMantras;

  @override
  List<MantraItem> getAllMantras() => List.unmodifiable(_mantras);

  @override
  List<String> getAllCollections() {
    final collections = <String>{};
    for (final m in _mantras) {
      collections.add(m.collection);
    }
    return collections.toList()..sort();
  }

  @override
  List<String> getAllDeities() {
    final deities = <String>{};
    for (final m in _mantras) {
      deities.add(m.deity);
    }
    return deities.toList()..sort();
  }

  @override
  List<MantraItem> getMantrasByCollection(String collection) {
    if (collection.isEmpty || collection.toLowerCase() == 'all') {
      return getAllMantras();
    }
    return _mantras
        .where((m) => m.collection.toLowerCase() == collection.toLowerCase())
        .toList();
  }

  @override
  List<MantraItem> getMantrasByDeity(String deity) {
    if (deity.isEmpty || deity.toLowerCase() == 'all') {
      return getAllMantras();
    }
    return _mantras
        .where((m) => m.deity.toLowerCase() == deity.toLowerCase())
        .toList();
  }

  @override
  List<MantraItem> getBundledMantras() {
    return _mantras.where((m) => m.isBundled).toList();
  }

  @override
  List<MantraItem> searchMantras(String query) {
    if (query.trim().isEmpty) return getAllMantras();
    final q = query.trim().toLowerCase();
    return _mantras.where((m) {
      return m.title.toLowerCase().contains(q) ||
          m.mantraText.toLowerCase().contains(q) ||
          m.deity.toLowerCase().contains(q) ||
          m.collection.toLowerCase().contains(q) ||
          m.significance.toLowerCase().contains(q);
    }).toList();
  }

  @override
  MantraItem? getMantraById(String id) {
    try {
      return _mantras.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
