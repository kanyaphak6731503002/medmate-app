import 'package:flutter/material.dart';
import '../services/language_manager.dart';
import '../services/app_language_state.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController medicationNameController = TextEditingController();

  String selectedMealTiming = '';
  List<String> reminderTimes = [];
  int selectedTimeIndex = 0;
  List<bool> selectedDays = [false, false, false, false, false, false, false];

  String get _lang => AppLanguageState.currentLanguage;
  String _t(String key) => LanguageManager.getString(key, _lang);

  @override
  void initState() {
    super.initState();
    AppLanguageState.addListener(_onLanguageChange);
  }

  @override
  void dispose() {
    AppLanguageState.removeListener(_onLanguageChange);
    medicationNameController.dispose();
    super.dispose();
  }

  void _onLanguageChange() => setState(() {});

  bool _validate() {
    if (medicationNameController.text.trim().isEmpty) {
      _showError(_t('error_enter_name'));
      return false;
    }
    if (reminderTimes.isEmpty) {
      _showError(_t('error_add_time'));
      return false;
    }
    if (!selectedDays.contains(true)) {
      _showError(_t('error_select_day'));
      return false;
    }
    if (selectedMealTiming.isEmpty) {
      _showError(_t('error_select_meal'));
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _pickTimeAndAdd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        reminderTimes.add(formatted);
        selectedTimeIndex = reminderTimes.length - 1; // auto-select new time
      });
    }
  }

  // key = 'before' | 'after' | 'anytime'
  Widget _buildMealTimingButton(String key) {
    final isSelected = selectedMealTiming == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedMealTiming = key;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A90E2) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _t(key),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _t('add_medication'),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                AppLanguageState.changeLanguage(
                  AppLanguageState.currentLanguage == LanguageManager.THAI
                      ? LanguageManager.ENGLISH
                      : LanguageManager.THAI,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppLanguageState.currentLanguage == LanguageManager.THAI ? 'EN' : 'TH',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Medication Name
            RichText(
              text: TextSpan(
                text: '${_t('medication_name')} ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: medicationNameController,
              decoration: InputDecoration(
                hintText: _t('enter_medication_name'),
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reminder Time
            RichText(
              text: TextSpan(
                text: '${_t('reminder_time')} ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // chips เวลาที่เพิ่มแล้ว (เลือกได้แค่ 1)
            if (reminderTimes.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reminderTimes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final time = entry.value;
                  final isSelected = idx == selectedTimeIndex;
                  return GestureDetector(
                    onTap: () => setState(() => selectedTimeIndex = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4A90E2)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF4A90E2)
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            time,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                reminderTimes.removeAt(idx);
                                if (reminderTimes.isNotEmpty) {
                                  selectedTimeIndex =
                                      (selectedTimeIndex >= reminderTimes.length)
                                          ? reminderTimes.length - 1
                                          : selectedTimeIndex;
                                } else {
                                  selectedTimeIndex = 0;
                                }
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: isSelected ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // ปุ่ม + Add time
            GestureDetector(
              onTap: _pickTimeAndAdd,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4A90E2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _t('add_time'),
                    style: const TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Days of the week
            RichText(
              text: TextSpan(
                text: '${_t('days_of_week')} ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final days = LanguageManager.getDayAbbreviations(_lang);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDays[index] = !selectedDays[index];
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selectedDays[index]
                          ? const Color(0xFF4A90E2)
                          : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        days[index],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: selectedDays[index]
                              ? Colors.white
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Meal Timing
            RichText(
              text: TextSpan(
                text: '${_t('meal_timing')} ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMealTimingButton('before'),
                const SizedBox(width: 8),
                _buildMealTimingButton('after'),
                const SizedBox(width: 8),
                _buildMealTimingButton('anytime'),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!_validate()) return;

                  final newMedication = {
                    'name': medicationNameController.text.trim(),
                    'time': reminderTimes[selectedTimeIndex],
                    'days': List<bool>.from(selectedDays),
                    'mealTiming': selectedMealTiming,
                  };

                  Navigator.pop(context, newMedication);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _t('save'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}