import 'package:flutter/material.dart';
import 'addmedication.dart';
import 'history.dart';
import 'profile.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  DateTime selectedDate = DateTime(2026, 2, 19);
  int currentTabIndex = 0;

  // แปลงปีค.ศ. เป็น พ.ศ. (บวก 543)
  String _getThaiYear(DateTime date) {
    return (date.year + 543).toString();
  }

  // ชื่อเดือนไทย
  String _getThaiMonthName(int month) {
    const thaiMonths = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return thaiMonths[month - 1];
  }

  // รูปแบบวันเดือนปีไทย
  String _getThaiDateFormat(DateTime date) {
    return '${_getThaiMonthName(date.month)} ${_getThaiYear(date)}';
  }

  final List<Map<String, dynamic>> reminders = [
    {
      'time': '08:00',
      'name': 'Paracetamol',
      'days': [true, true, true, true, true, true, true],
    },
    {
      'time': '13:00',
      'name': 'Vitamin D',
      'days': [true, true, true, true, true, true, true],
    },
    {
      'time': '19:00',
      'name': 'Blood Pressure Med',
      'days': [true, true, true, true, true, true, true],
    },
  ];

  void _previousMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Calendar Header
            _buildCalendarHeader(),
            const SizedBox(height: 20),
            // Calendar Days Grid
            _buildCalendar(),
            const SizedBox(height: 30),
            // Reminders List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  return _buildReminderCard(reminders[index]);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A90E2),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentTabIndex,
        onTap: (index) {
          if (index == 0) {
            // Stay on Reminders
            setState(() {
              currentTabIndex = index;
            });
          } else if (index == 1) {
            // Navigate to History
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistoryScreen(),
              ),
            );
          } else if (index == 2) {
            // Navigate to Profile
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthYear = _getThaiDateFormat(selectedDate);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          Text(
            monthYear,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    // Convert Dart weekday (1=Monday, 7=Sunday) to position (0=Sunday, 6=Saturday)
    final firstWeekday = now.weekday == 7 ? 0 : now.weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 10),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                return const SizedBox();
              }
              final day = index - firstWeekday + 1;
              final isSelected = day == selectedDate.day;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = DateTime(selectedDate.year, selectedDate.month, day);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4A90E2) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time
            Text(
              reminder['time'],
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Medication Name
            Text(
              reminder['name'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            // Day buttons
            Row(
              children: List.generate(7, (index) {
                final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                final isActive = reminder['days'][index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF4A90E2) : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${reminder['name']} confirmed!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
