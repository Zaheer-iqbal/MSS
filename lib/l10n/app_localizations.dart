import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MSS'**
  String get appTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @myAttendance.
  ///
  /// In en, this message translates to:
  /// **'My Attendance'**
  String get myAttendance;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @notMarked.
  ///
  /// In en, this message translates to:
  /// **'Not Marked'**
  String get notMarked;

  /// No description provided for @markPresent.
  ///
  /// In en, this message translates to:
  /// **'Mark Present'**
  String get markPresent;

  /// No description provided for @markAbsent.
  ///
  /// In en, this message translates to:
  /// **'Mark Absent'**
  String get markAbsent;

  /// No description provided for @attendanceMarkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Attendance marked successfully!'**
  String get attendanceMarkedSuccess;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignments;

  /// No description provided for @myTeachingCalendar.
  ///
  /// In en, this message translates to:
  /// **'My Teaching Calendar'**
  String get myTeachingCalendar;

  /// No description provided for @dailySchedule.
  ///
  /// In en, this message translates to:
  /// **'Daily Schedule'**
  String get dailySchedule;

  /// No description provided for @noClassScheduled.
  ///
  /// In en, this message translates to:
  /// **'No Class Scheduled'**
  String get noClassScheduled;

  /// No description provided for @enjoyYourDay.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your day!'**
  String get enjoyYourDay;

  /// No description provided for @performanceAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Performance Analytics'**
  String get performanceAnalytics;

  /// No description provided for @attendanceRate.
  ///
  /// In en, this message translates to:
  /// **'Attendance Rate'**
  String get attendanceRate;

  /// No description provided for @assignmentsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Assignments Completed'**
  String get assignmentsCompleted;

  /// No description provided for @quizScoresAvg.
  ///
  /// In en, this message translates to:
  /// **'Quiz Scores (Avg)'**
  String get quizScoresAvg;

  /// No description provided for @readyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready to Start?'**
  String get readyToStart;

  /// No description provided for @noClassesAssigned.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t been assigned any classes yet. Once the Head Teacher assigns you classes, you\'ll see your students and schedule here.'**
  String get noClassesAssigned;

  /// No description provided for @refreshDashboard.
  ///
  /// In en, this message translates to:
  /// **'Refresh Dashboard'**
  String get refreshDashboard;

  /// No description provided for @schoolStaff.
  ///
  /// In en, this message translates to:
  /// **'School Staff'**
  String get schoolStaff;

  /// No description provided for @searchStaffHint.
  ///
  /// In en, this message translates to:
  /// **'Search staff by name...'**
  String get searchStaffHint;

  /// No description provided for @noStaffFound.
  ///
  /// In en, this message translates to:
  /// **'No staff members found'**
  String get noStaffFound;

  /// No description provided for @noMatchingStaffFound.
  ///
  /// In en, this message translates to:
  /// **'No matching staff members found'**
  String get noMatchingStaffFound;

  /// No description provided for @classesAssigned.
  ///
  /// In en, this message translates to:
  /// **'{count} Classes Assigned'**
  String classesAssigned(int count);

  /// No description provided for @schoolOverview.
  ///
  /// In en, this message translates to:
  /// **'School Overview'**
  String get schoolOverview;

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudents;

  /// No description provided for @totalStaff.
  ///
  /// In en, this message translates to:
  /// **'Total Staff'**
  String get totalStaff;

  /// No description provided for @feeStatus.
  ///
  /// In en, this message translates to:
  /// **'Fee Status'**
  String get feeStatus;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @administrativeTools.
  ///
  /// In en, this message translates to:
  /// **'Administrative Tools'**
  String get administrativeTools;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @admissions.
  ///
  /// In en, this message translates to:
  /// **'Admissions'**
  String get admissions;

  /// No description provided for @fees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get fees;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @headTeacher.
  ///
  /// In en, this message translates to:
  /// **'Head Teacher'**
  String get headTeacher;

  /// No description provided for @selectYourRole.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectYourRole;

  /// No description provided for @continueAs.
  ///
  /// In en, this message translates to:
  /// **'Continue as {role}'**
  String continueAs(String role);

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get school;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @appAppName.
  ///
  /// In en, this message translates to:
  /// **'My Smart School'**
  String get appAppName;

  /// No description provided for @authWelcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Create an account or login to continue'**
  String get authWelcomeSub;

  /// No description provided for @schoolAdmin.
  ///
  /// In en, this message translates to:
  /// **'School Admin'**
  String get schoolAdmin;

  /// No description provided for @loginExisting.
  ///
  /// In en, this message translates to:
  /// **'Login to Existing Account'**
  String get loginExisting;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
