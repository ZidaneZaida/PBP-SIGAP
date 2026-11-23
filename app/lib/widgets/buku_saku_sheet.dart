import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class BukuSakuSheet extends StatefulWidget {
  const BukuSakuSheet({super.key});

  @override
  State<BukuSakuSheet> createState() => _BukuSakuSheetState();
}

class _BukuSakuSheetState extends State<BukuSakuSheet> {
  final FlutterTts _flutterTts = FlutterTts();

  static const String _panduanGempaText =
      'Panduan Gempa. Tetap tenang, lindungi kepala Anda, berlindung di bawah meja yang kokoh, jauhi jendela kaca, dan segera menuju tanah lapang setelah guncangan berhenti.';

  static const String _panduanTsunamiText =
      'Panduan Tsunami. Ingat aturan 20-20-20. Jika gempa terasa lebih dari 20 detik, Anda memiliki waktu 20 menit untuk segera evakuasi ke tempat tinggi minimal 20 meter di atas permukaan laut.';

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("id-ID");
    await _flutterTts.setSpeechRate(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buku Saku Darurat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.public, color: Colors.orange),
            title: const Text(
              'Panduan Gempa',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Lindungi kepala, berlindung di bawah meja kokoh, dan jauhi kaca.',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.green),
              tooltip: 'Bacakan Panduan Gempa',
              onPressed: () => _speak(_panduanGempaText),
            ),
          ),
          const Divider(),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.waves, color: Colors.blue),
            title: const Text(
              'Panduan Tsunami',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Evakuasi segera ke tempat tinggi (>20m) jika gempa terasa >20 detik.',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.green),
              tooltip: 'Bacakan Panduan Tsunami',
              onPressed: () => _speak(_panduanTsunamiText),
            ),
          ),
        ],
      ),
    );
  }
}

