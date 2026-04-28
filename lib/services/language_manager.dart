class LanguageManager {
  static const String ENGLISH = 'english';
  static const String THAI = 'thai';

  static const Map<String, Map<String, String>> translations = {
    ENGLISH: {
      'welcome': 'Welcome to MedMate!',
      'add_medication': 'Add Medication',
      'medication_name': 'Medication Name',
      'enter_medication_name': 'Enter medication name',
      'reminder_time': 'Reminder Time',
      'add_time': '+ Add time',
      'add_another_time': '+ Add another time',
      'frequency': 'Frequency',
      'days_of_week': 'Days of the week',
      'time_range': 'Time range',
      'cycle': 'Cycle',
      'meal_timing': 'Meal Timing',
      'before': 'Before',
      'after': 'After',
      'anytime': 'Anytime',
      'start_date': 'Start date',
      'end_date': 'End date (optional)',
      'save': 'Save',
      'medication_added': 'Medication added!',
      'reminders': 'Reminders',
      'history': 'History',
      'profile': 'Profile',
      'confirm': 'Confirm',
      'confirmed': 'Confirmed!',
      'adherence_rate': 'Adherence Rate',
      'today': 'Today',
      'scheduled': 'Scheduled for',
      'taken': 'Taken',
      'missed': 'Missed',
      'taken_at': 'Taken at',
      'language': 'Language',
      'as_needed': 'As needed',
      'no_reminders_yet': 'No reminders yet',
      'tap_to_add': 'Tap + to add a medication',
      'delete_reminder_title': 'Delete Reminder',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'no_history': 'No history yet',
      'error_enter_name': 'Please enter medication name',
      'error_add_time': 'Please add at least one reminder time',
      'error_select_day': 'Please select at least one day',
      'error_select_meal': 'Please select meal timing',
      'medical_disclaimer':
          'MedMate is for reminders only and does not provide medical advice, diagnosis, or treatment.',
    },
    THAI: {
      'welcome': 'ยินดีต้อนรับสู่ MedMate!',
      'add_medication': 'เพิ่มยา',
      'medication_name': 'ชื่อยา',
      'enter_medication_name': 'ป้อนชื่อยา',
      'reminder_time': 'เวลาแจ้งเตือน',
      'add_time': '+ เพิ่มเวลา',
      'add_another_time': '+ เพิ่มเวลาอื่น',
      'frequency': 'ความถี่',
      'days_of_week': 'วันของสัปดาห์',
      'time_range': 'ช่วงเวลา',
      'cycle': 'รอบ',
      'meal_timing': 'เวลาทานยา',
      'before': 'ก่อนอาหาร',
      'after': 'หลังอาหาร',
      'anytime': 'เวลาใดก็ได้',
      'start_date': 'วันที่เริ่มต้น',
      'end_date': 'วันที่สิ้นสุด (ไม่จำเป็น)',
      'save': 'บันทึก',
      'medication_added': 'เพิ่มยาแล้ว!',
      'reminders': 'การแจ้งเตือน',
      'history': 'ประวัติ',
      'profile': 'โปรไฟล์',
      'confirm': 'ยืนยัน',
      'confirmed': 'ยืนยันแล้ว!',
      'adherence_rate': 'อัตราการทานยา',
      'today': 'วันนี้',
      'scheduled': 'ตั้งเวลา',
      'taken': 'ทานแล้ว',
      'missed': 'พลาด',
      'taken_at': 'ทานเมื่อ',
      'language': 'ภาษา',
      'as_needed': 'ตามต้องการ',
      'no_reminders_yet': 'ยังไม่มีการแจ้งเตือน',
      'tap_to_add': 'กด + เพื่อเพิ่มยา',
      'delete_reminder_title': 'ลบการแจ้งเตือน',
      'delete': 'ลบ',
      'cancel': 'ยกเลิก',
      'no_history': 'ยังไม่มีประวัติ',
      'error_enter_name': 'กรุณาใส่ชื่อยา',
      'error_add_time': 'กรุณาเพิ่มเวลาแจ้งเตือนอย่างน้อย 1 เวลา',
      'error_select_day': 'กรุณาเลือกวันอย่างน้อย 1 วัน',
      'error_select_meal': 'กรุณาเลือกเวลาทานยา',
      'medical_disclaimer':
          'MedMate ใช้สำหรับการแจ้งเตือนเท่านั้น และไม่ใช่คำแนะนำ การวินิจฉัย หรือการรักษาทางการแพทย์',
    },
  };

  static String getString(String key, String language) {
    return translations[language]?[key] ?? translations[ENGLISH]?[key] ?? key;
  }

  static List<String> getDayAbbreviations(String language) {
    if (language == THAI) {
      return ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];
    }
    return ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  }

  static List<String> getCalendarHeaders(String language) {
    if (language == THAI) {
      return ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];
    }
    return ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  }

  static String getMonthName(int month, String language) {
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const th = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    final list = language == THAI ? th : en;
    return list[month - 1];
  }
}
