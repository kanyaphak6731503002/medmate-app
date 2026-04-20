import 'package:flutter/material.dart';
import 'dart:async';
import 'addmedication.dart';
import '../services/alarm_storage.dart';
import '../services/language_manager.dart';
import '../services/app_language_state.dart';

class HistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> reminders;

  const HistoryScreen({
  Key? key,
  required this.reminders,
}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime selectedDate = DateTime.now();
  Timer? _midnightTimer;
  List<Map<String, dynamic>> _historyEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppLanguageState.addListener(_onLanguageChange);
    AlarmStorage.addListener(_loadHistory);
    _scheduleMidnightRefresh();
    _loadHistory();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    AppLanguageState.removeListener(_onLanguageChange);
    AlarmStorage.removeListener(_loadHistory);
    super.dispose();
  }

  void _onLanguageChange() => setState(() {});

  Future<void> _loadHistory() async {
    final loaded = await AlarmStorage.loadHistoryEntries();
    if (!mounted) return;
    setState(() {
      _historyEntries = loaded;
      _loading = false;
    });
  }

  String get _lang => AppLanguageState.currentLanguage;
  String _t(String key) => LanguageManager.getString(key, _lang);

  String _dayKey([DateTime? date]) {
    final value = date ?? DateTime.now();
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDay(String value) {
    return DateTime.parse(value);
  }

  String _formatLabel(String day) {
    final current = DateTime.now();
    final parsed = _parseDay(day);
    final currentDay = DateTime(current.year, current.month, current.day);
    final parsedDay = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = currentDay.difference(parsedDay).inDays;
    if (diff == 0) return _t('today');
    if (diff == 1) return _lang == LanguageManager.THAI ? 'เมื่อวาน' : 'Yesterday';
    final month = LanguageManager.getMonthName(parsedDay.month, _lang);
    final year = _lang == LanguageManager.THAI ? parsedDay.year + 543 : parsedDay.year;
    return '${parsedDay.day} $month $year';
  }

  Map<String, List<Map<String, dynamic>>> get _groupedHistory {
    final sorted = [..._historyEntries]
      ..sort((a, b) => b['eventDate'].toString().compareTo(a['eventDate'].toString()));
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final entry in sorted) {
      final day = entry['eventDate']?.toString() ?? _dayKey();
      grouped.putIfAbsent(day, () => []).add(entry);
    }
    return grouped;
  }

  void _scheduleMidnightRefresh() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleMidnightRefresh();
    });
  }

  List<Map<String, dynamic>> get _todayEntries {
    return _historyEntries
        .where((entry) => entry['eventDate']?.toString() == _dayKey())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    LanguageManager.getString('history', AppLanguageState.currentLanguage),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  _buildLanguageToggle(),
                ],
              ),
              const SizedBox(height: 24),
              _buildAdherenceCard(),
              const SizedBox(height: 24),
              if (_loading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (_historyEntries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_t('no_history')),
                  ),
                )
              else
                ..._groupedHistory.entries.expand((group) {
                  final label = _formatLabel(group.key);
                  return [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...group.value.map((entry) => _buildMedicationHistoryCard(entry)),
                    const SizedBox(height: 12),
                  ];
                }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications, color: Colors.grey),
                  Text(
                    LanguageManager.getString(
                        'reminders', AppLanguageState.currentLanguage),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddMedicationScreen()),
                );
                if (result != null && result is Map<String, dynamic>) {
                  Navigator.pop(context, result);
                }
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: Color(0xFF4A90E2), shape: BoxShape.circle),
                child:
                    const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history, color: Color(0xFF4A90E2)),
                Text(
                  LanguageManager.getString(
                      'history', AppLanguageState.currentLanguage),
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF4A90E2)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    final isThai = AppLanguageState.currentLanguage == LanguageManager.THAI;
    return GestureDetector(
      onTap: () {
        AppLanguageState.changeLanguage(
            isThai ? LanguageManager.ENGLISH : LanguageManager.THAI);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF4A90E2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isThai ? 'EN' : 'TH',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAdherenceCard() {
    final total = _todayEntries.length;
    final taken = _todayEntries.where((m) => m['status'] == 'taken').length;
    final missed = total - taken;
    final percent =
        total == 0 ? 0 : ((taken / total) * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_t('adherence_rate'),
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('$percent%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            _lang == LanguageManager.THAI
                ? 'ทาน $taken ครั้ง • พลาด $missed ครั้ง • รวม $total ครั้ง'
                : '$taken taken • $missed missed • $total total',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationHistoryCard(Map<String, dynamic> med) {
    final taken = med['status'] == 'taken';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            taken ? Icons.check_circle : Icons.cancel,
            color: taken ? const Color(0xFF4A90E2) : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(med['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${_t('scheduled')} ${med['scheduledTime']}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),                if (taken && med['confirmedTime'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: Color(0xFF4A90E2)),
                        const SizedBox(width: 4),
                        Text('${_t('taken_at')} ${med['confirmedTime']}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4A90E2))),
                      ],
                    ),
                  ),              ],
            ),
          ),
          Text(taken ? _t('taken') : _t('missed'),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: taken
                      ? const Color(0xFF4A90E2)
                      : Colors.red)),
        ],
      ),
    );
  }
}