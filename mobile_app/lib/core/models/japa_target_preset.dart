/// Traditional chanting count presets and custom target validation rules for Japa Mala.
class JapaPreset {
  final int count;
  final String traditionalLabel;
  final String spiritualSignificance;

  const JapaPreset({
    required this.count,
    required this.traditionalLabel,
    required this.spiritualSignificance,
  });

  String get label => traditionalLabel;
}

/// The 7 mandatory traditional chanting counts in Phase 16B.
const List<JapaPreset> kJapaTraditionalPresets = [
  JapaPreset(
    count: 11,
    traditionalLabel: '11 repetitions',
    spiritualSignificance: 'Ekadasha Japa — Invocative chanting honoring the 11 forms of Rudra.',
  ),
  JapaPreset(
    count: 21,
    traditionalLabel: '21 repetitions',
    spiritualSignificance: 'Ekavimshati Japa — Traditional offering often paired with Ganesha and Surya worship.',
  ),
  JapaPreset(
    count: 27,
    traditionalLabel: '27 repetitions',
    spiritualSignificance: 'Quarter Mala — Aligned with the 27 lunar mansions (Nakshatras).',
  ),
  JapaPreset(
    count: 54,
    traditionalLabel: 'Half Mala',
    spiritualSignificance: 'Ardha Mala — Exactly half of a sacred 108-bead garland.',
  ),
  JapaPreset(
    count: 108,
    traditionalLabel: 'One Mala',
    spiritualSignificance: 'Purna Mala — The classical full sacred cycle of 108 auspicious beads.',
  ),
  JapaPreset(
    count: 111,
    traditionalLabel: '111 repetitions',
    spiritualSignificance: 'Shubha Sankalpa — A sacred auspicious count often chosen for special vratas.',
  ),
  JapaPreset(
    count: 1008,
    traditionalLabel: '1008 repetitions',
    spiritualSignificance: 'Sahasra Japa — Ten full malas, celebrated during intense devotional sadhanas.',
  ),
];

/// Validation result container for custom Japa count entry.
class CustomJapaTargetResult {
  final bool isValid;
  final int? count;
  final String? errorMessage;

  const CustomJapaTargetResult._({
    required this.isValid,
    this.count,
    this.errorMessage,
  });

  int? get parsedValue => count;

  factory CustomJapaTargetResult.valid(int count) =>
      CustomJapaTargetResult._(isValid: true, count: count);

  factory CustomJapaTargetResult.invalid(String message) =>
      CustomJapaTargetResult._(isValid: false, errorMessage: message);
}

/// Practical safe upper bound for custom Japa counts (100,000 repetitions).
/// This prevents memory strain, 32-bit integer overflow, and unresponsive UI loops,
/// while comfortably accommodating any legitimate lifelong or multi-month purashcharana practice.
const int kMaxPracticalJapaTarget = 100000;

/// Validates devotee input for custom chanting target.
CustomJapaTargetResult validateCustomJapaTarget(String? rawInput) {
  if (rawInput == null || rawInput.trim().isEmpty) {
    return CustomJapaTargetResult.invalid('Please enter a target count.');
  }

  final trimmed = rawInput.trim();

  // Protect against decimals
  if (trimmed.contains('.') || trimmed.contains(',')) {
    return CustomJapaTargetResult.invalid('Target must be a positive whole number (no decimals).');
  }

  // Parse integer
  final parsed = int.tryParse(trimmed);
  if (parsed == null) {
    return CustomJapaTargetResult.invalid('Target must contain digits only.');
  }

  if (parsed <= 0) {
    return CustomJapaTargetResult.invalid('Target must be greater than zero.');
  }

  if (parsed > kMaxPracticalJapaTarget) {
    return CustomJapaTargetResult.invalid(
      'Maximum practical target is $kMaxPracticalJapaTarget repetitions to ensure responsive device performance.',
    );
  }

  return CustomJapaTargetResult.valid(parsed);
}
