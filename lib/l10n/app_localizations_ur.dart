// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'ایم ایس ایس';

  @override
  String get hello => 'ہیلو';

  @override
  String get myAttendance => 'میری حاضری';

  @override
  String get present => 'حاضر';

  @override
  String get absent => 'غیر حاضر';

  @override
  String get notMarked => 'نہیں لگائی گئی';

  @override
  String get markPresent => 'حاضری لگائیں';

  @override
  String get markAbsent => 'غیر حاضری لگائیں';

  @override
  String get attendanceMarkedSuccess => 'حاضری کامیابی سے لگا دی گئی ہے!';

  @override
  String get quickActions => 'فوری اقدامات';

  @override
  String get attendance => 'حاضری';

  @override
  String get students => 'طلبہ';

  @override
  String get results => 'نتائج';

  @override
  String get assignments => 'اسائنمنٹس';

  @override
  String get myTeachingCalendar => 'میرا کالینڈر';

  @override
  String get dailySchedule => 'روزانہ کا شیڈول';

  @override
  String get noClassScheduled => 'کوئی کلاس شیڈول نہیں ہے';

  @override
  String get enjoyYourDay => 'اپنا دن انجوائے کریں!';

  @override
  String get performanceAnalytics => 'کارکردگی کا تجزیہ';

  @override
  String get attendanceRate => 'حاضری کی شرح';

  @override
  String get assignmentsCompleted => 'مکمل کی گئی اسائنمنٹس';

  @override
  String get quizScoresAvg => 'کوئز اسکورز (اوسط)';

  @override
  String get readyToStart => 'شروع کرنے کے لیے تیار ہیں؟';

  @override
  String get noClassesAssigned =>
      'آپ کو ابھی تک کوئی کلاس تفویض نہیں کی گئی ہے۔ جیسے ہی ہیڈ ٹیچر آپ کو کلاس تفویض کریں گے، آپ یہاں اپنے طلبہ اور شیڈول دیکھ سکیں گے۔';

  @override
  String get refreshDashboard => 'ڈیش بورڈ ریفریش کریں';

  @override
  String get schoolStaff => 'سکول سٹاف';

  @override
  String get searchStaffHint => 'نام سے سٹاف تلاش کریں...';

  @override
  String get noStaffFound => 'کوئی سٹاف نہیں ملا';

  @override
  String get noMatchingStaffFound => 'نام سے کوئی سٹاف نہیں ملا';

  @override
  String classesAssigned(int count) {
    return '$count کلاسیں تفویض کی گئی ہیں';
  }

  @override
  String get schoolOverview => 'سکول کا جائزہ';

  @override
  String get totalStudents => 'کل طلبہ';

  @override
  String get totalStaff => 'کل سٹاف';

  @override
  String get feeStatus => 'فیس کی صورتحال';

  @override
  String get rating => 'درجہ بندی';

  @override
  String get administrativeTools => 'انتظامی ٹولز';

  @override
  String get staff => 'سٹاف';

  @override
  String get admissions => 'داخلے';

  @override
  String get fees => 'فیس';

  @override
  String get events => 'پروگرامز';

  @override
  String get reports => 'رپورٹس';

  @override
  String get settings => 'سیٹنگز';

  @override
  String get headTeacher => 'ہیڈ ٹیچر';

  @override
  String get selectYourRole => 'اپنا کردار منتخب کریں';

  @override
  String continueAs(String role) {
    return 'بطور $role جاری رکھیں';
  }

  @override
  String get school => 'سکول';

  @override
  String get teacher => 'ٹیچر';

  @override
  String get parent => 'والدین';

  @override
  String get student => 'طالب علم';

  @override
  String get appAppName => 'میرا سمارٹ سکول';

  @override
  String get authWelcomeSub => 'جاری رکھنے کے لیے اکاؤنٹ بنائیں یا لاگ ان کریں';

  @override
  String get schoolAdmin => 'سکول ایڈمن';

  @override
  String get loginExisting => 'موجودہ اکاؤنٹ میں لاگ ان کریں';
}
