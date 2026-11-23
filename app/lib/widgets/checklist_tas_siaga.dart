import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChecklistTasSiagaSheet extends StatefulWidget {
  const ChecklistTasSiagaSheet({super.key});

  @override
  State<ChecklistTasSiagaSheet> createState() => _ChecklistTasSiagaSheetState();
}

class _ChecklistTasSiagaSheetState extends State<ChecklistTasSiagaSheet> {
  final List<String> _items = const [
    'Dokumen Penting',
    'Kotak P3K',
    'Senter & Baterai',
    'Air Minum',
    'Pakaian Ganti',
  ];

  final Map<String, bool> _checkedStatus = {};

  @override
  void initState() {
    super.initState();
    for (final item in _items) {
      _checkedStatus[item] = false;
    }
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final item in _items) {
        _checkedStatus[item] = prefs.getBool('tas_siaga_$item') ?? false;
      }
    });
  }

  Future<void> _saveItemStatus(String item, bool value) async {
    setState(() {
      _checkedStatus[item] = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tas_siaga_$item', value);
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
            'Checklist Tas Siaga',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              final isChecked = _checkedStatus[item] ?? false;
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  item,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                activeColor: Colors.green,
                value: isChecked,
                onChanged: (bool? value) {
                  if (value != null) {
                    _saveItemStatus(item, value);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

