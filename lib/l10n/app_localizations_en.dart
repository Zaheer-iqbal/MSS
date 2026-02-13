// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MSS';

  @override
  String get hello => 'Hello';

  @override
  String get myAttendance => 'My Attendance';

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get notMarked => 'Not Marked';

  @override
  String get markPresent => 'Mark Present';

  @override
  String get markAbsent => 'Mark Absent';

  @override
  String get attendanceMarkedSuccess => 'Attendance marked successfully!';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get attendance => 'Attendance';

  @override
  String get students => 'Students';

  @override
  String get results => 'Results';

  @override
  String get assignments => 'Assignments';

  @override
  String get myTeachingCalendar => 'My Teaching Calendar';

  @override
  String get dailySchedule => 'Daily Schedule';

  @override
  String get noClassScheduled => 'No Class Scheduled';

  @override
  String get enjoyYourDay => 'Enjoy your day!';

  @override
  String get performanceAnalytics => 'Performance Analytics';

  @override
  String get attendanceRate => 'Attendance Rate';

  @override
  String get assignmentsCompleted => 'Assignments Completed';

  @override
  String get quizScoresAvg => 'Quiz Scores (Avg)';

  @override
  String get readyToStart => 'Ready to Start?';

  @override
  String get noClassesAssigned =>
      'You haven\'t been assigned any classes yet. Once the Head Teacher assigns you classes, you\'ll see your students and schedule here.';

  @override
  String get refreshDashboard => 'Refresh Dashboard';

  @override
  String get schoolStaff => 'School Staff';

  @override
  String get searchStaffHint => 'Search staff by name...';

  @override
  String get noStaffFound => 'No staff members found';

  @override
  String get noMatchingStaffFound => 'No matching staff members found';

  @override
  String classesAssigned(int count) {
    return '$count Classes Assigned';
  }

  @override
  String get schoolOverview => 'School Overview';

  @override
  String get totalStudents => 'Total Students';

  @override
  String get totalStaff => 'Total Staff';

  @override
  String get feeStatus => 'Fee Status';

  @override
  String get rating => 'Rating';

  @override
  String get administrativeTools => 'Administrative Tools';

  @override
  String get staff => 'Staff';

  @override
  String get admissions => 'Admissions';

  @override
  String get fees => 'Fees';

  @override
  String get events => 'Events';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get headTeacher => 'Head Teacher';

  @override
  String get selectYourRole => 'Select Your Role';

  @override
  String continueAs(String role) {
    return 'Continue as $role';
  }

  @override
  String get school => 'School';

  @override
  String get teacher => 'Teacher';

  @override
  String get parent => 'Parent';

  @override
  String get student => 'Student';

  @override
  String get appAppName => 'My Smart School';

  @override
  String get authWelcomeSub => 'Create an account or login to continue';

  @override
  String get schoolAdmin => 'School Admin';

  @override
  String get loginExisting => 'Login to Existing Account';
}
