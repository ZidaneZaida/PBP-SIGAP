/// Durasi 1 unit dasar sinyal Morse SOS standar (200 ms).
const Duration kDefaultMorseUnitDuration = Duration(milliseconds: 200);

/// Satu langkah deterministik dalam urutan sinyal Morse SOS (`... --- ...`).
class MorseStep {
  final bool isLightOn;
  final int durationUnits;
  final String symbolLabel;
  final String letter;

  /// Indeks simbol aktif (0..8) untuk 9 denyut S-O-S (`• • • — — — • • •`),
  /// atau `null` saat fase jeda (mati).
  final int? activeSymbolIndex;

  const MorseStep({
    required this.isLightOn,
    required this.durationUnits,
    required this.symbolLabel,
    required this.letter,
    this.activeSymbolIndex,
  });

  /// Menghitung durasi nyata langkah ini berdasarkan [unitDuration].
  Duration durationForUnit(Duration unitDuration) {
    return Duration(
      milliseconds: unitDuration.inMilliseconds * durationUnits,
    );
  }
}

/// Menghasilkan urutan deterministik pola Morse SOS internasional (`... --- ...`):
/// - Titik (`.`): nyala 1 unit
/// - Garis (`-`): nyala 3 unit
/// - Jeda antarelemen dalam 1 huruf: mati 1 unit
/// - Jeda antarhuruf (`S -> O -> S`): mati 3 unit
/// - Jeda antarsiklus SOS: mati 7 unit
///
/// Total: 18 langkah, 34 unit dasar (6,8 detik per siklus pada 200 ms/unit).
List<MorseStep> buildSosMorseSequence() {
  return const <MorseStep>[
    // Huruf S: • • • (1u nyala, 1u jeda, 1u nyala, 1u jeda, 1u nyala)
    MorseStep(
      isLightOn: true,
      durationUnits: 1,
      symbolLabel: '•',
      letter: 'S',
      activeSymbolIndex: 0,
    ),
    MorseStep(
      isLightOn: false,
      durationUnits: 1,
      symbolLabel: ' ',
      letter: 'S',
    ),
    MorseStep(
      isLightOn: true,
      durationUnits: 1,
      symbolLabel: '•',
      letter: 'S',
      activeSymbolIndex: 1,
    ),
    MorseStep(
      isLightOn: false,
      durationUnits: 1,
      symbolLabel: ' ',
      letter: 'S',
    ),
    MorseStep(
      isLightOn: true,
      durationUnits: 1,
      symbolLabel: '•',
      letter: 'S',
      activeSymbolIndex: 2,
    ),

    // Jeda antarhuruf S -> O (3 unit)
    MorseStep(
      isLightOn: false,
      durationUnits: 3,
      symbolLabel: ' ',
      letter: 'JEDA',
    ),

    // Huruf O: — — — (3u nyala, 1u jeda, 3u nyala, 1u jeda, 3u nyala)
    MorseStep(
      isLightOn: true,
      durationUnits: 3,
      symbolLabel: '—',
      letter: 'O',
      activeSymbolIndex: 3,
    ),
    MorseStep(
      isLightOn: false,
      durationUnits: 1,
      symbolLabel: ' ',
      letter: 'O',
    ),
    MorseStep(
      isLightOn: true,
      durationUnits: 3,
      symbolLabel: '—',
      letter: 'O',
      activeSymbolIndex: 4,
    ),
    MorseStep(
      isLightOn: false,
      durationUnits: 1,
      symbolLabel: ' ',
      letter: 'O',
    ),
    MorseStep(
      isLightOn: true,
      durationUnits: 3,
      symbolLabel: '—',
      letter: 'O',
      activeSymbolIndex: 5,
    ),

    // Jeda antarhuruf O -> S (3 unit)
    MorseStep(
      isLightOn: false,
      durationUnits: 3,
      symbolLabel: ' ',
      letter: 'JEDA',
    ),

    // Huruf S: • • • (1u nyala, 1u jeda, 1u nyala, 1u jeda, 1u nyala)
    MorseStep(
      isLightOn: true,
      durationUnits: 1,
      symbolLabel: '•',
      letter: 'S',
      activeSymbolIndex: 6,
    ),
    MorseStep(
      isLightOn: false,
      durationUnits: 1,
      symbolLabel: ' ',
      letter: 'S',
    ),
    MorseStep(
      isLightOn: true,
      durationUnits: 1,
      symbolLabel: '•',
      letter: 'S',
      activeSymbolIndex: 7,
    ),
    MorseStep(
      isLightOn: false,
      durationUnits: 1,
      symbolLabel: ' ',
      letter: 'S',
    ),
    MorseStep(
      isLightOn: true,
      durationUnits: 1,
      symbolLabel: '•',
      letter: 'S',
      activeSymbolIndex: 8,
    ),

    // Jeda antarsiklus SOS (7 unit)
    MorseStep(
      isLightOn: false,
      durationUnits: 7,
      symbolLabel: ' ',
      letter: 'JEDA',
    ),
  ];
}

/// Menghitung jumlah total unit waktu dalam sebuah rangkaian [MorseStep].
int calculateTotalMorseUnits(List<MorseStep> steps) {
  var total = 0;
  for (final step in steps) {
    total += step.durationUnits;
  }
  return total;
}
