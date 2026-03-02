import 'package:flutter/material.dart';
import 'addmedication.dart';
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

  @override
  void initState() {
    super.initState();
    AppLanguageState.addListener(_onLanguageChange);
  }

  @override
  void dispose() {
    AppLanguageState.removeListener(_onLanguageChange);
    super.dispose();
  }

  void _onLanguageChange() => setState(() {});

 List<Map<String, dynamic>> get todayMedications {
    return widget.reminders
        .where((reminder) => reminder['confirmed'] == true)
        .map((reminder) {
      return {
        'name': reminder['name'],
        'scheduledTime': reminder['confirmedTime'] ?? reminder['time'],
        'status': 'Taken',
      };
    }).toList();
  }

  void _previousMonth() => setState(() {
        selectedDate =
            DateTime(selectedDate.year, selectedDate.month - 1);
      });

  void _nextMonth() => setState(() {
        selectedDate =
            DateTime(selectedDate.year, selectedDate.month + 1);
      });

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
              const Text('History',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildAdherenceCard(),
              const SizedBox(height: 24),
              _buildMonthNavigation(),
              const SizedBox(height: 24),
              const Text('Today',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
              const SizedBox(height: 12),
              if (todayMedications.isEmpty)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No history yet')))
              else
                ...todayMedications
                    .map((med) => _buildMedicationHistoryCard(med))
                    .toList(),
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

  Widget _buildAdherenceCard() {
    final total = todayMedications.length;
    final taken =
        todayMedications.where((m) => m['status'] == 'Taken').length;
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
          const Text('Adherence Rate',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text('$percent%',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('$taken taken • $missed missed • $total total',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth),
        Text('${months[selectedDate.month - 1]} ${selectedDate.year}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
        IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth),
      ],
    );
  }

  Widget _buildMedicationHistoryCard(Map<String, dynamic> med) {
    final taken = med['status'] == 'Taken';
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
                Text('Scheduled: ${med['scheduledTime']}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(taken ? 'Taken' : 'Missed',
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