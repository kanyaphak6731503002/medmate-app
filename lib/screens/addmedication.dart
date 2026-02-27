import 'package:flutter/material.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController medicationNameController = TextEditingController();

  String selectedMealTiming = '';
  List<String> reminderTimes = [];
  List<bool> selectedDays = [false, false, false, false, false, false, false];

  bool _validate() {
    if (medicationNameController.text.trim().isEmpty) {
      _showError('Please enter medication name');
      return false;
    }
    if (reminderTimes.isEmpty) {
      _showError('Please add at least one reminder time');
      return false;
    }
    if (!selectedDays.contains(true)) {
      _showError('Please select at least one day');
      return false;
    }
    if (selectedMealTiming.isEmpty) {
      _showError('Please select meal timing');
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
      });
    }
  }

  Widget _buildMealTimingButton(String label) {
    final isSelected = selectedMealTiming == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedMealTiming = label;
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
              label,
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
        title: const Text(
          'Add Medication',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Medication Name
            RichText(
              text: const TextSpan(
                text: 'Medication Name ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                children: [
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
                hintText: 'Enter medication name',
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
              text: const TextSpan(
                text: 'Reminder Time ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // chips เวลาที่เพิ่มแล้ว
            if (reminderTimes.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: reminderTimes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final time = entry.value;
                  return InputChip(
                    label: Text(time),
                    onPressed: () {},
                    onDeleted: () {
                      setState(() {
                        reminderTimes.removeAt(idx);
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                    backgroundColor: Colors.grey[100],
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
                child: const Center(
                  child: Text(
                    '+ Add time',
                    style: TextStyle(
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
              text: const TextSpan(
                text: 'Days of the week ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                children: [
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
                final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
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
              text: const TextSpan(
                text: 'Meal Timing ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                children: [
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
                _buildMealTimingButton('Before'),
                const SizedBox(width: 8),
                _buildMealTimingButton('After'),
                const SizedBox(width: 8),
                _buildMealTimingButton('Anytime'),
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
                    'time': reminderTimes[0],
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
                child: const Text(
                  'Save',
                  style: TextStyle(
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