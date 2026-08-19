import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

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
    Locale('km'),
  ];

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @failedToLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile details.'**
  String get failedToLoadProfile;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @accessRoles.
  ///
  /// In en, this message translates to:
  /// **'Access Roles'**
  String get accessRoles;

  /// No description provided for @returnToAdminConsole.
  ///
  /// In en, this message translates to:
  /// **'Return to Admin Console'**
  String get returnToAdminConsole;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logoutConfirmationDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of your account?'**
  String get logoutConfirmationDesc;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @khmer.
  ///
  /// In en, this message translates to:
  /// **'Khmer'**
  String get khmer;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @loginIdentityHint.
  ///
  /// In en, this message translates to:
  /// **'user@email.com, 010123456, or EMP01'**
  String get loginIdentityHint;

  /// No description provided for @loginIdentityLabel.
  ///
  /// In en, this message translates to:
  /// **'Email, Phone, or Employee ID'**
  String get loginIdentityLabel;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password *'**
  String get passwordRequired;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @hrManagementSystem.
  ///
  /// In en, this message translates to:
  /// **'HR Management System'**
  String get hrManagementSystem;

  /// No description provided for @smartAttendanceSystem.
  ///
  /// In en, this message translates to:
  /// **'Smart Attendance & HR Solution'**
  String get smartAttendanceSystem;

  /// No description provided for @gpsAttendanceReady.
  ///
  /// In en, this message translates to:
  /// **'GPS Geofence Attendance Ready'**
  String get gpsAttendanceReady;

  /// No description provided for @cambodiaAttendanceTagline.
  ///
  /// In en, this message translates to:
  /// **'Cambodia\'s Smart Attendance & Workforce Management'**
  String get cambodiaAttendanceTagline;

  /// No description provided for @poweredByAttendKH.
  ///
  /// In en, this message translates to:
  /// **'AttendKH Cambodia'**
  String get poweredByAttendKH;

  /// No description provided for @companyPrefix.
  ///
  /// In en, this message translates to:
  /// **'Company \"'**
  String get companyPrefix;

  /// No description provided for @createdSuccessSuffix.
  ///
  /// In en, this message translates to:
  /// **'\" created successfully! Please sign in.'**
  String get createdSuccessSuffix;

  /// No description provided for @registerYourCompany.
  ///
  /// In en, this message translates to:
  /// **'Register Your Company'**
  String get registerYourCompany;

  /// No description provided for @companyDetails.
  ///
  /// In en, this message translates to:
  /// **'Company Details'**
  String get companyDetails;

  /// No description provided for @step1Of2.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2: Create your admin account.'**
  String get step1Of2;

  /// No description provided for @step2Of2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2: Fill in your company information.'**
  String get step2Of2;

  /// No description provided for @yourFullName.
  ///
  /// In en, this message translates to:
  /// **'Your Full Name'**
  String get yourFullName;

  /// No description provided for @johnSmith.
  ///
  /// In en, this message translates to:
  /// **'John Smith'**
  String get johnSmith;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'010 123 456'**
  String get phoneNumberHint;

  /// No description provided for @phoneRequiredForLogin.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required for login'**
  String get phoneRequiredForLogin;

  /// No description provided for @workEmail.
  ///
  /// In en, this message translates to:
  /// **'Work Email'**
  String get workEmail;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@company.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get validEmailRequired;

  /// No description provided for @min8Chars.
  ///
  /// In en, this message translates to:
  /// **'Min 8 chars'**
  String get min8Chars;

  /// No description provided for @min8CharsRequired.
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters'**
  String get min8CharsRequired;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @reEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get reEnterPassword;

  /// No description provided for @pleaseConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @companyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// No description provided for @companyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Acme Inc.'**
  String get companyNameHint;

  /// No description provided for @companyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get companyNameRequired;

  /// No description provided for @selectCompanySize.
  ///
  /// In en, this message translates to:
  /// **'Select company size'**
  String get selectCompanySize;

  /// No description provided for @companySize.
  ///
  /// In en, this message translates to:
  /// **'Company Size'**
  String get companySize;

  /// No description provided for @companySizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select company size'**
  String get companySizeRequired;

  /// No description provided for @phoneNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (Optional)'**
  String get phoneNumberOptional;

  /// No description provided for @phoneOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'+855 12 345 678'**
  String get phoneOptionalHint;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @createWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Create Workspace'**
  String get createWorkspace;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @verificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent!'**
  String get verificationEmailSent;

  /// No description provided for @emailNotYetVerified.
  ///
  /// In en, this message translates to:
  /// **'Email is not yet verified.'**
  String get emailNotYetVerified;

  /// No description provided for @verifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// No description provided for @verifyYourEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Verify your email address'**
  String get verifyYourEmailAddress;

  /// No description provided for @verificationInstruction.
  ///
  /// In en, this message translates to:
  /// **'To continue using the application, you must verify your email address. Please check your inbox and click the verification link.'**
  String get verificationInstruction;

  /// No description provided for @iHaveVerifiedRefresh.
  ///
  /// In en, this message translates to:
  /// **'I have verified (Refresh)'**
  String get iHaveVerifiedRefresh;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @confirmOvertimeClockOut.
  ///
  /// In en, this message translates to:
  /// **'Confirm Overtime Clock Out'**
  String get confirmOvertimeClockOut;

  /// No description provided for @confirmClockOut.
  ///
  /// In en, this message translates to:
  /// **'Confirm Clock Out'**
  String get confirmClockOut;

  /// No description provided for @endOvertimeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to end your overtime?'**
  String get endOvertimeConfirm;

  /// No description provided for @clockOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clock out for the day? Your work hours will be recorded.'**
  String get clockOutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clockOutBtn.
  ///
  /// In en, this message translates to:
  /// **'Clock Out'**
  String get clockOutBtn;

  /// No description provided for @overtimeEnded.
  ///
  /// In en, this message translates to:
  /// **'👋 Overtime ended!'**
  String get overtimeEnded;

  /// No description provided for @clockedOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'👋 Clocked out successfully!'**
  String get clockedOutSuccess;

  /// No description provided for @clockOutFailed.
  ///
  /// In en, this message translates to:
  /// **'Clock-out failed'**
  String get clockOutFailed;

  /// No description provided for @waitingForLocation.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Waiting for location data...'**
  String get waitingForLocation;

  /// No description provided for @unknownLocation.
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get unknownLocation;

  /// No description provided for @helloPrefix.
  ///
  /// In en, this message translates to:
  /// **'Hello, '**
  String get helloPrefix;

  /// No description provided for @myCompany.
  ///
  /// In en, this message translates to:
  /// **'My Company'**
  String get myCompany;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get loadingDashboard;

  /// No description provided for @lateWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Late Attendance Warning'**
  String get lateWarningTitle;

  /// No description provided for @lateWarningDesc1.
  ///
  /// In en, this message translates to:
  /// **'Notice: You have been late '**
  String get lateWarningDesc1;

  /// No description provided for @lateWarningDesc2.
  ///
  /// In en, this message translates to:
  /// **' times this month. Please ensure you clock in on time to adhere to company policy.'**
  String get lateWarningDesc2;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @upcomingLeaves.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Leaves'**
  String get upcomingLeaves;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @activeTrainings.
  ///
  /// In en, this message translates to:
  /// **'Active Trainings'**
  String get activeTrainings;

  /// No description provided for @companyAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Company Announcements'**
  String get companyAnnouncements;

  /// No description provided for @readyToWork.
  ///
  /// In en, this message translates to:
  /// **'Ready to Work?'**
  String get readyToWork;

  /// No description provided for @overtimeStartedAt.
  ///
  /// In en, this message translates to:
  /// **'Overtime started at '**
  String get overtimeStartedAt;

  /// No description provided for @overtimeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Overtime Completed'**
  String get overtimeCompleted;

  /// No description provided for @clockedInAt.
  ///
  /// In en, this message translates to:
  /// **'Clocked in at '**
  String get clockedInAt;

  /// No description provided for @activeDuration.
  ///
  /// In en, this message translates to:
  /// **'Active duration: '**
  String get activeDuration;

  /// No description provided for @shiftCompleted.
  ///
  /// In en, this message translates to:
  /// **'Shift Completed'**
  String get shiftCompleted;

  /// No description provided for @worked.
  ///
  /// In en, this message translates to:
  /// **'Worked: '**
  String get worked;

  /// No description provided for @locationAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Access Required'**
  String get locationAccessRequired;

  /// No description provided for @locationAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'We need location access to verify your check-in distance.'**
  String get locationAccessDesc;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @calculatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Calculating location...'**
  String get calculatingLocation;

  /// No description provided for @withinRadiusPrefix.
  ///
  /// In en, this message translates to:
  /// **'Within radius ('**
  String get withinRadiusPrefix;

  /// No description provided for @clockOutAnywhere.
  ///
  /// In en, this message translates to:
  /// **'You can clock out from anywhere.'**
  String get clockOutAnywhere;

  /// No description provided for @youAreAwayPrefix.
  ///
  /// In en, this message translates to:
  /// **'You are '**
  String get youAreAwayPrefix;

  /// No description provided for @youAreAwaySuffix.
  ///
  /// In en, this message translates to:
  /// **'m away.'**
  String get youAreAwaySuffix;

  /// No description provided for @mustBeWithinPrefix.
  ///
  /// In en, this message translates to:
  /// **'Must be within '**
  String get mustBeWithinPrefix;

  /// No description provided for @mustBeWithinSuffix.
  ///
  /// In en, this message translates to:
  /// **'m to clock in.'**
  String get mustBeWithinSuffix;

  /// No description provided for @managerPortal.
  ///
  /// In en, this message translates to:
  /// **'Manager Portal'**
  String get managerPortal;

  /// No description provided for @teamApprovals.
  ///
  /// In en, this message translates to:
  /// **'Team approvals'**
  String get teamApprovals;

  /// No description provided for @leaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get leaves;

  /// No description provided for @requestOffDays.
  ///
  /// In en, this message translates to:
  /// **'Request off days'**
  String get requestOffDays;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @claimReimbursements.
  ///
  /// In en, this message translates to:
  /// **'Claim reimbursements'**
  String get claimReimbursements;

  /// No description provided for @payslips.
  ///
  /// In en, this message translates to:
  /// **'Payslips'**
  String get payslips;

  /// No description provided for @viewMonthlyStatements.
  ///
  /// In en, this message translates to:
  /// **'View monthly statements'**
  String get viewMonthlyStatements;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @checkAttendanceLogs.
  ///
  /// In en, this message translates to:
  /// **'Check attendance logs'**
  String get checkAttendanceLogs;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @enrollInCourses.
  ///
  /// In en, this message translates to:
  /// **'Enroll in courses'**
  String get enrollInCourses;

  /// No description provided for @myKpis.
  ///
  /// In en, this message translates to:
  /// **'My KPIs'**
  String get myKpis;

  /// No description provided for @performanceGoals.
  ///
  /// In en, this message translates to:
  /// **'Performance goals'**
  String get performanceGoals;

  /// No description provided for @holidays.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidays;

  /// No description provided for @companyCalendar.
  ///
  /// In en, this message translates to:
  /// **'Company calendar'**
  String get companyCalendar;

  /// No description provided for @failedToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dashboard'**
  String get failedToLoadDashboard;

  /// No description provided for @swipeToClockOutOT.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Clock Out (OT)'**
  String get swipeToClockOutOT;

  /// No description provided for @swipeToClockInOT.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Clock In (OT)'**
  String get swipeToClockInOT;

  /// No description provided for @swipeToClockOut.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Clock Out'**
  String get swipeToClockOut;

  /// No description provided for @swipeToClockIn.
  ///
  /// In en, this message translates to:
  /// **'Swipe to Clock In'**
  String get swipeToClockIn;

  /// No description provided for @quickFeatures.
  ///
  /// In en, this message translates to:
  /// **'Quick Features'**
  String get quickFeatures;

  /// No description provided for @requestCorrection.
  ///
  /// In en, this message translates to:
  /// **'Request Correction'**
  String get requestCorrection;

  /// No description provided for @requestCorrectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Submit a request to correct an anomaly in your attendance log.'**
  String get requestCorrectionDesc;

  /// No description provided for @dateStr.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateStr;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @correctionType.
  ///
  /// In en, this message translates to:
  /// **'Correction Type'**
  String get correctionType;

  /// No description provided for @missedClockIn.
  ///
  /// In en, this message translates to:
  /// **'Missed Clock In'**
  String get missedClockIn;

  /// No description provided for @missedClockOut.
  ///
  /// In en, this message translates to:
  /// **'Missed Clock Out'**
  String get missedClockOut;

  /// No description provided for @wrongTime.
  ///
  /// In en, this message translates to:
  /// **'Wrong Time'**
  String get wrongTime;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @explainCorrectionReason.
  ///
  /// In en, this message translates to:
  /// **'Explain why you are requesting this correction...'**
  String get explainCorrectionReason;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @correctionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'✅ Correction request submitted'**
  String get correctionSubmitted;

  /// No description provided for @attendanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistory;

  /// No description provided for @loadingCalendar.
  ///
  /// In en, this message translates to:
  /// **'Loading calendar...'**
  String get loadingCalendar;

  /// No description provided for @noRecordForThisDay.
  ///
  /// In en, this message translates to:
  /// **'No record for this day'**
  String get noRecordForThisDay;

  /// No description provided for @noRecordsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No attendance records this month'**
  String get noRecordsThisMonth;

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

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @halfDay.
  ///
  /// In en, this message translates to:
  /// **'Half Day'**
  String get halfDay;

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDate;

  /// No description provided for @inLabel.
  ///
  /// In en, this message translates to:
  /// **'In: '**
  String get inLabel;

  /// No description provided for @outLabel.
  ///
  /// In en, this message translates to:
  /// **'Out: '**
  String get outLabel;

  /// No description provided for @minsBreak.
  ///
  /// In en, this message translates to:
  /// **' mins break'**
  String get minsBreak;

  /// No description provided for @earlyIn.
  ///
  /// In en, this message translates to:
  /// **'Early In'**
  String get earlyIn;

  /// No description provided for @hLabel.
  ///
  /// In en, this message translates to:
  /// **'h '**
  String get hLabel;

  /// No description provided for @mLabel.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get mLabel;

  /// No description provided for @otApproved.
  ///
  /// In en, this message translates to:
  /// **'OT Approved'**
  String get otApproved;

  /// No description provided for @lateLabel.
  ///
  /// In en, this message translates to:
  /// **' late'**
  String get lateLabel;

  /// No description provided for @simMockSelfie.
  ///
  /// In en, this message translates to:
  /// **'🤖 Simulator: generated mock selfie photo'**
  String get simMockSelfie;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'❌ Camera permission is required for selfie verification.'**
  String get cameraPermissionRequired;

  /// No description provided for @cameraException.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Camera exception: '**
  String get cameraException;

  /// No description provided for @outOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of Range'**
  String get outOfRange;

  /// No description provided for @outOfRangeDesc1.
  ///
  /// In en, this message translates to:
  /// **'You are '**
  String get outOfRangeDesc1;

  /// No description provided for @outOfRangeDesc2.
  ///
  /// In en, this message translates to:
  /// **'m away from the branch (allowed: '**
  String get outOfRangeDesc2;

  /// No description provided for @outOfRangeDesc3.
  ///
  /// In en, this message translates to:
  /// **'m). This will be flagged for manager review. Proceed?'**
  String get outOfRangeDesc3;

  /// No description provided for @clockInAnyway.
  ///
  /// In en, this message translates to:
  /// **'Clock In Anyway'**
  String get clockInAnyway;

  /// No description provided for @clockedInSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Clocked in successfully!'**
  String get clockedInSuccessfully;

  /// No description provided for @clockedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Clocked out successfully!'**
  String get clockedOutSuccessfully;

  /// No description provided for @attendanceRecorded.
  ///
  /// In en, this message translates to:
  /// **'Your attendance has been recorded.'**
  String get attendanceRecorded;

  /// No description provided for @clockedInSuccessfullyEmoji.
  ///
  /// In en, this message translates to:
  /// **'🎉 Clocked in successfully!'**
  String get clockedInSuccessfullyEmoji;

  /// No description provided for @clockedOutSuccessfullyEmoji.
  ///
  /// In en, this message translates to:
  /// **'🎉 Clocked out successfully!'**
  String get clockedOutSuccessfullyEmoji;

  /// No description provided for @clockInFailed.
  ///
  /// In en, this message translates to:
  /// **'Clock-in failed'**
  String get clockInFailed;

  /// No description provided for @overtimeCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Overtime Check In'**
  String get overtimeCheckIn;

  /// No description provided for @checkInTitle.
  ///
  /// In en, this message translates to:
  /// **'Check In'**
  String get checkInTitle;

  /// No description provided for @overtimeCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Overtime Check Out'**
  String get overtimeCheckOut;

  /// No description provided for @checkOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Check Out'**
  String get checkOutTitle;

  /// No description provided for @takeSelfie.
  ///
  /// In en, this message translates to:
  /// **'Take Selfie'**
  String get takeSelfie;

  /// No description provided for @tapToCapture.
  ///
  /// In en, this message translates to:
  /// **'Tap to capture'**
  String get tapToCapture;

  /// No description provided for @takeSelfieToVerify.
  ///
  /// In en, this message translates to:
  /// **'Please take Selfie to verify yourself'**
  String get takeSelfieToVerify;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location: '**
  String get locationLabel;

  /// No description provided for @withinRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Within '**
  String get withinRadiusLabel;

  /// No description provided for @mRadius.
  ///
  /// In en, this message translates to:
  /// **'m radius'**
  String get mRadius;

  /// No description provided for @confirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm '**
  String get confirmAction;

  /// No description provided for @selectLeaveType.
  ///
  /// In en, this message translates to:
  /// **'Select leave type'**
  String get selectLeaveType;

  /// No description provided for @enterLeaveReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason for the leave'**
  String get enterLeaveReason;

  /// No description provided for @noEmployeeProfile.
  ///
  /// In en, this message translates to:
  /// **'No employee profile associated with this account'**
  String get noEmployeeProfile;

  /// No description provided for @invalidEmployeeId.
  ///
  /// In en, this message translates to:
  /// **'Invalid employee ID configuration'**
  String get invalidEmployeeId;

  /// No description provided for @leaveRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'✅ Leave request submitted successfully'**
  String get leaveRequestSubmitted;

  /// No description provided for @failedToSubmitLeave.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit leave request'**
  String get failedToSubmitLeave;

  /// No description provided for @requestLeave.
  ///
  /// In en, this message translates to:
  /// **'Request Leave'**
  String get requestLeave;

  /// No description provided for @submittingLeave.
  ///
  /// In en, this message translates to:
  /// **'Submitting leave request...'**
  String get submittingLeave;

  /// No description provided for @noLeaveTypesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No leave types configured for your company.'**
  String get noLeaveTypesConfigured;

  /// No description provided for @leaveTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get leaveTypeLabel;

  /// No description provided for @balanceLabel.
  ///
  /// In en, this message translates to:
  /// **' balance: '**
  String get balanceLabel;

  /// No description provided for @daysRemaining.
  ///
  /// In en, this message translates to:
  /// **' days remaining'**
  String get daysRemaining;

  /// No description provided for @noBalanceRecord.
  ///
  /// In en, this message translates to:
  /// **'No balance record found for this leave type.'**
  String get noBalanceRecord;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @requestHalfDay.
  ///
  /// In en, this message translates to:
  /// **'Request Half Day'**
  String get requestHalfDay;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// No description provided for @describeLeaveReason.
  ///
  /// In en, this message translates to:
  /// **'Describe your reason for leave...'**
  String get describeLeaveReason;

  /// No description provided for @attachmentOptional.
  ///
  /// In en, this message translates to:
  /// **'Attachment (Optional)'**
  String get attachmentOptional;

  /// No description provided for @tapToSelectFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to select file (PDF, JPG, PNG)'**
  String get tapToSelectFile;

  /// No description provided for @loadingLeaveTypes.
  ///
  /// In en, this message translates to:
  /// **'Loading leave types...'**
  String get loadingLeaveTypes;

  /// No description provided for @failedToLoadLeaveTypes.
  ///
  /// In en, this message translates to:
  /// **'Failed to load leave types'**
  String get failedToLoadLeaveTypes;

  /// No description provided for @digitalWallet.
  ///
  /// In en, this message translates to:
  /// **'Digital Wallet'**
  String get digitalWallet;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @noPayslipsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No payslips available'**
  String get noPayslipsAvailable;

  /// No description provided for @loadingSecureWallet.
  ///
  /// In en, this message translates to:
  /// **'Loading secure wallet...'**
  String get loadingSecureWallet;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// No description provided for @lastNetPay.
  ///
  /// In en, this message translates to:
  /// **'Last Net Pay'**
  String get lastNetPay;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'✅ Download started'**
  String get downloadStarted;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @basicSalary.
  ///
  /// In en, this message translates to:
  /// **'Basic Salary'**
  String get basicSalary;

  /// No description provided for @overtimePay.
  ///
  /// In en, this message translates to:
  /// **'Overtime Pay'**
  String get overtimePay;

  /// No description provided for @allowances.
  ///
  /// In en, this message translates to:
  /// **'Allowances'**
  String get allowances;

  /// No description provided for @grossPay.
  ///
  /// In en, this message translates to:
  /// **'Gross Pay'**
  String get grossPay;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @lateDeduction.
  ///
  /// In en, this message translates to:
  /// **'Late Deduction'**
  String get lateDeduction;

  /// No description provided for @earlyLeaveDeduction.
  ///
  /// In en, this message translates to:
  /// **'Early Leave Deduction'**
  String get earlyLeaveDeduction;

  /// No description provided for @totalDeductions.
  ///
  /// In en, this message translates to:
  /// **'Total Deductions'**
  String get totalDeductions;

  /// No description provided for @netPay.
  ///
  /// In en, this message translates to:
  /// **'Net Pay'**
  String get netPay;

  /// No description provided for @workingDays.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get workingDays;

  /// No description provided for @earlyOut.
  ///
  /// In en, this message translates to:
  /// **'Early Out'**
  String get earlyOut;

  /// No description provided for @otHours.
  ///
  /// In en, this message translates to:
  /// **'OT Hours'**
  String get otHours;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @downloadUrlNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Download URL is not available.'**
  String get downloadUrlNotAvailable;

  /// No description provided for @couldNotLaunchUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not launch url'**
  String get couldNotLaunchUrl;

  /// No description provided for @failedToDownloadDoc.
  ///
  /// In en, this message translates to:
  /// **'Failed to download document: '**
  String get failedToDownloadDoc;

  /// No description provided for @companyDocuments.
  ///
  /// In en, this message translates to:
  /// **'Company Documents'**
  String get companyDocuments;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: '**
  String get errorPrefix;

  /// No description provided for @noDocumentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No documents available'**
  String get noDocumentsAvailable;

  /// No description provided for @leaveManagement.
  ///
  /// In en, this message translates to:
  /// **'Leave Management'**
  String get leaveManagement;

  /// No description provided for @loadingBalances.
  ///
  /// In en, this message translates to:
  /// **'Loading balances...'**
  String get loadingBalances;

  /// No description provided for @noLeaveBalances.
  ///
  /// In en, this message translates to:
  /// **'No leave balances found'**
  String get noLeaveBalances;

  /// No description provided for @noLeaveHistory.
  ///
  /// In en, this message translates to:
  /// **'No leave history'**
  String get noLeaveHistory;

  /// No description provided for @loadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get loadingHistory;

  /// No description provided for @usedLabel.
  ///
  /// In en, this message translates to:
  /// **' used'**
  String get usedLabel;

  /// No description provided for @halfLabel.
  ///
  /// In en, this message translates to:
  /// **'HALF'**
  String get halfLabel;

  /// No description provided for @attachmentIncluded.
  ///
  /// In en, this message translates to:
  /// **'Attachment included'**
  String get attachmentIncluded;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @cancelLeaveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this leave request?'**
  String get cancelLeaveConfirm;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get yesCancel;

  /// No description provided for @leaveRequestCancelled.
  ///
  /// In en, this message translates to:
  /// **'✅ Leave request cancelled'**
  String get leaveRequestCancelled;

  /// No description provided for @noExpenseClaims.
  ///
  /// In en, this message translates to:
  /// **'No expense claims'**
  String get noExpenseClaims;

  /// No description provided for @submitFirstExpense.
  ///
  /// In en, this message translates to:
  /// **'Submit your first expense claim to get started'**
  String get submitFirstExpense;

  /// No description provided for @loadingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Loading expenses...'**
  String get loadingExpenses;

  /// No description provided for @deleteClaim.
  ///
  /// In en, this message translates to:
  /// **'Delete Claim'**
  String get deleteClaim;

  /// No description provided for @deleteClaimConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" permanently?'**
  String deleteClaimConfirm(String title);

  /// No description provided for @claimDeleted.
  ///
  /// In en, this message translates to:
  /// **'✅ Claim deleted'**
  String get claimDeleted;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get failedToDelete;

  /// No description provided for @expenseClaimDetails.
  ///
  /// In en, this message translates to:
  /// **'Expense Claim Details'**
  String get expenseClaimDetails;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @expenseDate.
  ///
  /// In en, this message translates to:
  /// **'Expense Date'**
  String get expenseDate;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @paidAt.
  ///
  /// In en, this message translates to:
  /// **'Paid At'**
  String get paidAt;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @editExpenseClaim.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense Claim'**
  String get editExpenseClaim;

  /// No description provided for @newExpenseClaim.
  ///
  /// In en, this message translates to:
  /// **'New Expense Claim'**
  String get newExpenseClaim;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Client lunch, Taxi fare'**
  String get titleHint;

  /// No description provided for @titleError.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleError;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get categoryRequired;

  /// No description provided for @amountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount *'**
  String get amountRequired;

  /// No description provided for @requiredError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredError;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @expenseDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Expense Date *'**
  String get expenseDateRequired;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @receiptOptional.
  ///
  /// In en, this message translates to:
  /// **'Receipt (optional)'**
  String get receiptOptional;

  /// No description provided for @tapToAttachReceipt.
  ///
  /// In en, this message translates to:
  /// **'Tap to attach receipt'**
  String get tapToAttachReceipt;

  /// No description provided for @cameraOrGallery.
  ///
  /// In en, this message translates to:
  /// **'Camera or Gallery  ·  JPG, PNG, WEBP'**
  String get cameraOrGallery;

  /// No description provided for @expenseClaimUpdated.
  ///
  /// In en, this message translates to:
  /// **'✅ Expense claim updated'**
  String get expenseClaimUpdated;

  /// No description provided for @expenseClaimSubmitted.
  ///
  /// In en, this message translates to:
  /// **'✅ Expense claim submitted'**
  String get expenseClaimSubmitted;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update'**
  String get failedToUpdate;

  /// No description provided for @failedToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit'**
  String get failedToSubmit;

  /// No description provided for @travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travel;

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// No description provided for @supplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get supplies;

  /// No description provided for @software.
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get software;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @accommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get accommodation;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @myTraining.
  ///
  /// In en, this message translates to:
  /// **'My Training'**
  String get myTraining;

  /// No description provided for @availableCourses.
  ///
  /// In en, this message translates to:
  /// **'Available Courses'**
  String get availableCourses;

  /// No description provided for @myEnrollments.
  ///
  /// In en, this message translates to:
  /// **'My Enrollments'**
  String get myEnrollments;

  /// No description provided for @enrollInTraining.
  ///
  /// In en, this message translates to:
  /// **'Enroll in Training'**
  String get enrollInTraining;

  /// No description provided for @enrollConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to enroll in \"{title}\"?'**
  String enrollConfirm(String title);

  /// No description provided for @enroll.
  ///
  /// In en, this message translates to:
  /// **'Enroll'**
  String get enroll;

  /// No description provided for @enrolledSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Successfully enrolled!'**
  String get enrolledSuccess;

  /// No description provided for @enrolledFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to enroll'**
  String get enrolledFailed;

  /// No description provided for @noAvailableTrainings.
  ///
  /// In en, this message translates to:
  /// **'No available trainings.'**
  String get noAvailableTrainings;

  /// No description provided for @loadingCourses.
  ///
  /// In en, this message translates to:
  /// **'Loading courses...'**
  String get loadingCourses;

  /// No description provided for @noEnrolledTrainings.
  ///
  /// In en, this message translates to:
  /// **'You have not enrolled in any trainings.'**
  String get noEnrolledTrainings;

  /// No description provided for @loadingEnrollments.
  ///
  /// In en, this message translates to:
  /// **'Loading enrollments...'**
  String get loadingEnrollments;

  /// No description provided for @companyWide.
  ///
  /// In en, this message translates to:
  /// **'Company-Wide'**
  String get companyWide;

  /// No description provided for @enrolled.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get enrolled;

  /// No description provided for @enrollNow.
  ///
  /// In en, this message translates to:
  /// **'Enroll Now'**
  String get enrollNow;

  /// No description provided for @courseProgress.
  ///
  /// In en, this message translates to:
  /// **'Course Progress'**
  String get courseProgress;

  /// No description provided for @companyPolicies.
  ///
  /// In en, this message translates to:
  /// **'Company Policies'**
  String get companyPolicies;

  /// No description provided for @actionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get actionRequired;

  /// No description provided for @acknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get acknowledged;

  /// No description provided for @allPoliciesAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'All policies have been acknowledged!'**
  String get allPoliciesAcknowledged;

  /// No description provided for @noPoliciesAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'You have not acknowledged any policies yet.'**
  String get noPoliciesAcknowledged;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version '**
  String get version;

  /// No description provided for @policyAcknowledgedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Policy acknowledged successfully.'**
  String get policyAcknowledgedSuccess;

  /// No description provided for @policyDocument.
  ///
  /// In en, this message translates to:
  /// **'Policy Document'**
  String get policyDocument;

  /// No description provided for @acknowledgedOn.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged on '**
  String get acknowledgedOn;

  /// No description provided for @iHaveReadAndAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I have read and acknowledge'**
  String get iHaveReadAndAcknowledge;

  /// No description provided for @holidayCalendar.
  ///
  /// In en, this message translates to:
  /// **'Holiday Calendar'**
  String get holidayCalendar;

  /// No description provided for @holidaysThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Holidays this month'**
  String get holidaysThisMonth;

  /// No description provided for @noHolidaysThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No holidays this month'**
  String get noHolidaysThisMonth;

  /// No description provided for @loadingHolidays.
  ///
  /// In en, this message translates to:
  /// **'Loading Holidays...'**
  String get loadingHolidays;

  /// No description provided for @performanceKpis.
  ///
  /// In en, this message translates to:
  /// **'Performance KPIs'**
  String get performanceKpis;

  /// No description provided for @platformHealth.
  ///
  /// In en, this message translates to:
  /// **'Platform Health'**
  String get platformHealth;

  /// No description provided for @myPerf.
  ///
  /// In en, this message translates to:
  /// **'My Perf.'**
  String get myPerf;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @hrDashboard.
  ///
  /// In en, this message translates to:
  /// **'HR Dashboard'**
  String get hrDashboard;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @attendanceMenu.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceMenu;

  /// No description provided for @leaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Leave Requests'**
  String get leaveRequests;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @switchingBranchView.
  ///
  /// In en, this message translates to:
  /// **'Switching Branch View…'**
  String get switchingBranchView;

  /// No description provided for @loadingBranchData.
  ///
  /// In en, this message translates to:
  /// **'Loading branch data'**
  String get loadingBranchData;

  /// No description provided for @selectBranch.
  ///
  /// In en, this message translates to:
  /// **'Select Branch'**
  String get selectBranch;

  /// No description provided for @viewAsBranchManager.
  ///
  /// In en, this message translates to:
  /// **'VIEW AS BRANCH MANAGER'**
  String get viewAsBranchManager;

  /// No description provided for @companyOverview.
  ///
  /// In en, this message translates to:
  /// **'Company Overview'**
  String get companyOverview;

  /// No description provided for @totalStaff.
  ///
  /// In en, this message translates to:
  /// **'Total Staff'**
  String get totalStaff;

  /// No description provided for @onLeave.
  ///
  /// In en, this message translates to:
  /// **'On Leave'**
  String get onLeave;

  /// No description provided for @openJobs.
  ///
  /// In en, this message translates to:
  /// **'Open Jobs'**
  String get openJobs;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @errorLoadingKpis.
  ///
  /// In en, this message translates to:
  /// **'Error loading KPIs: '**
  String get errorLoadingKpis;

  /// No description provided for @quickOperations.
  ///
  /// In en, this message translates to:
  /// **'Quick Operations'**
  String get quickOperations;

  /// No description provided for @hrStructure.
  ///
  /// In en, this message translates to:
  /// **'HR Structure'**
  String get hrStructure;

  /// No description provided for @deptsAndBranches.
  ///
  /// In en, this message translates to:
  /// **'Depts & branches'**
  String get deptsAndBranches;

  /// No description provided for @kpis.
  ///
  /// In en, this message translates to:
  /// **'KPIs'**
  String get kpis;

  /// No description provided for @manageStaff.
  ///
  /// In en, this message translates to:
  /// **'Manage staff'**
  String get manageStaff;

  /// No description provided for @viewLogs.
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get viewLogs;

  /// No description provided for @shiftRules.
  ///
  /// In en, this message translates to:
  /// **'Shift Rules'**
  String get shiftRules;

  /// No description provided for @workSchedules.
  ///
  /// In en, this message translates to:
  /// **'Work schedules'**
  String get workSchedules;

  /// No description provided for @manageCompanyHolidays.
  ///
  /// In en, this message translates to:
  /// **'Manage company holidays'**
  String get manageCompanyHolidays;

  /// No description provided for @reviewSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Review submissions'**
  String get reviewSubmissions;

  /// No description provided for @branchSettings.
  ///
  /// In en, this message translates to:
  /// **'Branch Settings'**
  String get branchSettings;

  /// No description provided for @payrollAndRules.
  ///
  /// In en, this message translates to:
  /// **'Payroll & rules'**
  String get payrollAndRules;

  /// No description provided for @branchInfoMissing.
  ///
  /// In en, this message translates to:
  /// **'Branch information is missing. Please refresh profile.'**
  String get branchInfoMissing;

  /// No description provided for @payroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get payroll;

  /// No description provided for @processRuns.
  ///
  /// In en, this message translates to:
  /// **'Process runs'**
  String get processRuns;

  /// No description provided for @expenseClaims.
  ///
  /// In en, this message translates to:
  /// **'Expense Claims'**
  String get expenseClaims;

  /// No description provided for @reviewClaims.
  ///
  /// In en, this message translates to:
  /// **'Review claims'**
  String get reviewClaims;

  /// No description provided for @devicesAndStock.
  ///
  /// In en, this message translates to:
  /// **'Devices & stock'**
  String get devicesAndStock;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @broadcastAlerts.
  ///
  /// In en, this message translates to:
  /// **'Broadcast alerts'**
  String get broadcastAlerts;

  /// No description provided for @recruitment.
  ///
  /// In en, this message translates to:
  /// **'Recruitment'**
  String get recruitment;

  /// No description provided for @jobsAndCandidates.
  ///
  /// In en, this message translates to:
  /// **'Jobs & candidates'**
  String get jobsAndCandidates;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @reviewsAndTraining.
  ///
  /// In en, this message translates to:
  /// **'Reviews & training'**
  String get reviewsAndTraining;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @analyticsAndExports.
  ///
  /// In en, this message translates to:
  /// **'Analytics & exports'**
  String get analyticsAndExports;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @companyFiles.
  ///
  /// In en, this message translates to:
  /// **'Company files'**
  String get companyFiles;

  /// No description provided for @policies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get policies;

  /// No description provided for @rulesAndGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Rules & guidelines'**
  String get rulesAndGuidelines;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @viewInbox.
  ///
  /// In en, this message translates to:
  /// **'View inbox'**
  String get viewInbox;

  /// No description provided for @hrPortalActive.
  ///
  /// In en, this message translates to:
  /// **'HR Portal Active'**
  String get hrPortalActive;

  /// No description provided for @readAll.
  ///
  /// In en, this message translates to:
  /// **'Read All'**
  String get readAll;

  /// No description provided for @loadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications...'**
  String get loadingNotifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @allMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'✅ All marked read'**
  String get allMarkedRead;

  /// No description provided for @noAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'No additional details provided.'**
  String get noAdditionalDetails;

  /// No description provided for @closeBtn.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeBtn;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @noKpisFound.
  ///
  /// In en, this message translates to:
  /// **'No KPIs found.'**
  String get noKpisFound;

  /// No description provided for @estimatedBadge.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimatedBadge;

  /// No description provided for @liveDataBadge.
  ///
  /// In en, this message translates to:
  /// **'Live Data'**
  String get liveDataBadge;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}%'**
  String scoreLabel(num score);

  /// No description provided for @overallSystemScore.
  ///
  /// In en, this message translates to:
  /// **'Overall System Score'**
  String get overallSystemScore;

  /// No description provided for @basedOnDynamicData.
  ///
  /// In en, this message translates to:
  /// **'Based on dynamic module data'**
  String get basedOnDynamicData;

  /// No description provided for @branchAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Branch Average Score'**
  String get branchAverageScore;

  /// No description provided for @aggregatedFromTeam.
  ///
  /// In en, this message translates to:
  /// **'Aggregated from team metrics'**
  String get aggregatedFromTeam;

  /// No description provided for @platformGlobalHealth.
  ///
  /// In en, this message translates to:
  /// **'Platform Global Health'**
  String get platformGlobalHealth;

  /// No description provided for @aggregatedAcrossWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Aggregated across all registered workspaces'**
  String get aggregatedAcrossWorkspaces;

  /// No description provided for @platformSummary.
  ///
  /// In en, this message translates to:
  /// **'Platform Summary'**
  String get platformSummary;

  /// No description provided for @platformSummaryDesc.
  ///
  /// In en, this message translates to:
  /// **'These are platform-wide metrics calculating the overall health, retention rates, support SLAs, and MRR (Monthly Recurring Revenue) across all active companies within the system.'**
  String get platformSummaryDesc;

  /// No description provided for @platformStrategicKpis.
  ///
  /// In en, this message translates to:
  /// **'Platform Strategic KPIs'**
  String get platformStrategicKpis;

  /// No description provided for @companyHealthScore.
  ///
  /// In en, this message translates to:
  /// **'Company Health Score'**
  String get companyHealthScore;

  /// No description provided for @scoreExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get scoreExcellent;

  /// No description provided for @scoreGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get scoreGood;

  /// No description provided for @scoreNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get scoreNeedsAttention;

  /// No description provided for @scoreCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get scoreCritical;

  /// No description provided for @kpisTrackedLiveData.
  ///
  /// In en, this message translates to:
  /// **'{count} KPIs tracked • Live Data'**
  String kpisTrackedLiveData(int count);

  /// No description provided for @targetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target: '**
  String get targetLabel;

  /// No description provided for @kpiOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get kpiOnTrack;

  /// No description provided for @kpiModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get kpiModerate;

  /// No description provided for @kpiAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At Risk'**
  String get kpiAtRisk;

  /// No description provided for @noCompanyKpisFound.
  ///
  /// In en, this message translates to:
  /// **'No company KPIs found.'**
  String get noCompanyKpisFound;

  /// No description provided for @noCompanyKpisDesc.
  ///
  /// In en, this message translates to:
  /// **'Data will appear once employees,\nattendance and payroll are set up.'**
  String get noCompanyKpisDesc;

  /// No description provided for @platformAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Admin'**
  String get platformAdminTitle;

  /// No description provided for @platformAdministratorBadge.
  ///
  /// In en, this message translates to:
  /// **'🛡️  Platform Administrator'**
  String get platformAdministratorBadge;

  /// No description provided for @menuCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get menuCompanies;

  /// No description provided for @menuCompaniesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage registers'**
  String get menuCompaniesDesc;

  /// No description provided for @menuRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get menuRoles;

  /// No description provided for @menuRolesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage access'**
  String get menuRolesDesc;

  /// No description provided for @menuSupportTickets.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get menuSupportTickets;

  /// No description provided for @menuSupportTicketsDesc.
  ///
  /// In en, this message translates to:
  /// **'User queries'**
  String get menuSupportTicketsDesc;

  /// No description provided for @menuKPIs.
  ///
  /// In en, this message translates to:
  /// **'KPIs'**
  String get menuKPIs;

  /// No description provided for @menuKPIsDesc.
  ///
  /// In en, this message translates to:
  /// **'Performance goals'**
  String get menuKPIsDesc;

  /// No description provided for @menuAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get menuAnnouncements;

  /// No description provided for @menuAnnouncementsDesc.
  ///
  /// In en, this message translates to:
  /// **'Broadcast alerts'**
  String get menuAnnouncementsDesc;

  /// No description provided for @menuAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get menuAuditLogs;

  /// No description provided for @menuAuditLogsDesc.
  ///
  /// In en, this message translates to:
  /// **'System changes'**
  String get menuAuditLogsDesc;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @menuSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Global configs'**
  String get menuSettingsDesc;

  /// No description provided for @menuAdminProfile.
  ///
  /// In en, this message translates to:
  /// **'Admin Profile'**
  String get menuAdminProfile;

  /// No description provided for @menuAdminProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Security & setup'**
  String get menuAdminProfileDesc;

  /// No description provided for @platformStatistics.
  ///
  /// In en, this message translates to:
  /// **'Platform Statistics'**
  String get platformStatistics;

  /// No description provided for @statCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get statCompanies;

  /// No description provided for @statCompaniesActive.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String statCompaniesActive(String count);

  /// No description provided for @statTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get statTotalUsers;

  /// No description provided for @statUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Across all tenants'**
  String get statUsersDesc;

  /// No description provided for @statOpenTickets.
  ///
  /// In en, this message translates to:
  /// **'Open Tickets'**
  String get statOpenTickets;

  /// No description provided for @statTicketsDesc.
  ///
  /// In en, this message translates to:
  /// **'Awaiting response'**
  String get statTicketsDesc;

  /// No description provided for @statAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get statAnnouncements;

  /// No description provided for @statAnnouncementsDesc.
  ///
  /// In en, this message translates to:
  /// **'Published and active'**
  String get statAnnouncementsDesc;

  /// No description provided for @recentCompanySignups.
  ///
  /// In en, this message translates to:
  /// **'Recent Company Signups'**
  String get recentCompanySignups;

  /// No description provided for @recentSupportTickets.
  ///
  /// In en, this message translates to:
  /// **'Recent Support Tickets'**
  String get recentSupportTickets;

  /// No description provided for @platformSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Settings'**
  String get platformSettingsTitle;

  /// No description provided for @failedToLoadSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings'**
  String get failedToLoadSettings;

  /// No description provided for @settingsSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Settings saved'**
  String get settingsSavedSuccess;

  /// No description provided for @settingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String settingsFailed(String error);

  /// No description provided for @globalSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Global Settings'**
  String get globalSettingsTitle;

  /// No description provided for @appNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Application Name'**
  String get appNameLabel;

  /// No description provided for @supportEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Support Email'**
  String get supportEmailLabel;

  /// No description provided for @defaultTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Timezone'**
  String get defaultTimezoneLabel;

  /// No description provided for @defaultCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get defaultCurrencyLabel;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @platformRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Roles'**
  String get platformRolesTitle;

  /// No description provided for @noSystemRolesFound.
  ///
  /// In en, this message translates to:
  /// **'No system roles found'**
  String get noSystemRolesFound;

  /// No description provided for @permissionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} permissions'**
  String permissionsCount(int count);

  /// No description provided for @loadingRoles.
  ///
  /// In en, this message translates to:
  /// **'Loading roles...'**
  String get loadingRoles;

  /// No description provided for @editRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Role'**
  String get editRoleTitle;

  /// No description provided for @createNewRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Role'**
  String get createNewRoleTitle;

  /// No description provided for @roleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Role Name'**
  String get roleNameLabel;

  /// No description provided for @roleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. HR Manager'**
  String get roleNameHint;

  /// No description provided for @coreSystemRolesWarning.
  ///
  /// In en, this message translates to:
  /// **'Core system role names cannot be changed.'**
  String get coreSystemRolesWarning;

  /// No description provided for @permissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissionsLabel;

  /// No description provided for @roleUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get roleUpdatedSuccess;

  /// No description provided for @roleCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Role created'**
  String get roleCreatedSuccess;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @btnCreateRole.
  ///
  /// In en, this message translates to:
  /// **'Create Role'**
  String get btnCreateRole;

  /// No description provided for @deleteRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Role'**
  String get deleteRoleTitle;

  /// No description provided for @deleteRoleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete role {name}?'**
  String deleteRoleConfirm(String name);

  /// No description provided for @roleDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role deleted'**
  String get roleDeletedSuccess;

  /// No description provided for @failedToDeleteRole.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete role'**
  String get failedToDeleteRole;

  /// No description provided for @supportTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get supportTicketsTitle;

  /// No description provided for @failedToLoadTickets.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tickets'**
  String get failedToLoadTickets;

  /// No description provided for @noSupportTickets.
  ///
  /// In en, this message translates to:
  /// **'No support tickets'**
  String get noSupportTickets;

  /// No description provided for @markInProgress.
  ///
  /// In en, this message translates to:
  /// **'Mark In Progress'**
  String get markInProgress;

  /// No description provided for @markResolved.
  ///
  /// In en, this message translates to:
  /// **'Mark Resolved'**
  String get markResolved;

  /// No description provided for @closeTicket.
  ///
  /// In en, this message translates to:
  /// **'Close Ticket'**
  String get closeTicket;

  /// No description provided for @ticketMarkedAs.
  ///
  /// In en, this message translates to:
  /// **'Ticket #{id} marked as {status}'**
  String ticketMarkedAs(int id, String status);

  /// No description provided for @platformAnnouncementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform Announcements'**
  String get platformAnnouncementsTitle;

  /// No description provided for @failedToLoadAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Failed to load announcements'**
  String get failedToLoadAnnouncements;

  /// No description provided for @noAnnouncementsYet.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet'**
  String get noAnnouncementsYet;

  /// No description provided for @statusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get statusPublished;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @deleteAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Announcement'**
  String get deleteAnnouncementTitle;

  /// No description provided for @deleteAnnouncementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String deleteAnnouncementConfirm(String title);

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get btnDelete;

  /// No description provided for @announcementDeleted.
  ///
  /// In en, this message translates to:
  /// **'Announcement deleted'**
  String get announcementDeleted;

  /// No description provided for @editAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Announcement'**
  String get editAnnouncementTitle;

  /// No description provided for @createAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Announcement'**
  String get createAnnouncementTitle;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @bodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get bodyLabel;

  /// No description provided for @targetAudienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Audience'**
  String get targetAudienceLabel;

  /// No description provided for @audienceAllEmployees.
  ///
  /// In en, this message translates to:
  /// **'🌐 All Employees (Company-Wide)'**
  String get audienceAllEmployees;

  /// No description provided for @audienceManagers.
  ///
  /// In en, this message translates to:
  /// **'👔 Managers & Team Leads'**
  String get audienceManagers;

  /// No description provided for @audienceHRTeam.
  ///
  /// In en, this message translates to:
  /// **'👥 HR Team Only'**
  String get audienceHRTeam;

  /// No description provided for @publishImmediatelyLabel.
  ///
  /// In en, this message translates to:
  /// **'Publish immediately'**
  String get publishImmediatelyLabel;

  /// No description provided for @announcementUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Announcement updated'**
  String get announcementUpdatedSuccess;

  /// No description provided for @announcementCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Announcement created'**
  String get announcementCreatedSuccess;

  /// No description provided for @btnUpdateAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Update Announcement'**
  String get btnUpdateAnnouncement;

  /// No description provided for @btnCreateAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Create Announcement'**
  String get btnCreateAnnouncement;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettingsTitle;

  /// No description provided for @profileInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInfoTitle;

  /// No description provided for @profileInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your account\'s profile information and email address.'**
  String get profileInfoDesc;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @maritalStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Marital Status'**
  String get maritalStatusLabel;

  /// No description provided for @maritalSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get maritalSingle;

  /// No description provided for @maritalMarried.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get maritalMarried;

  /// No description provided for @maritalDivorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get maritalDivorced;

  /// No description provided for @maritalWidowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get maritalWidowed;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirthLabel;

  /// No description provided for @saveProfileBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfileBtn;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @updatePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordTitle;

  /// No description provided for @updatePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Ensure your account is using a long, random password to stay secure.'**
  String get updatePasswordDesc;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @btnUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get btnUpdatePassword;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccess;

  /// No description provided for @testingDebuggingTitle.
  ///
  /// In en, this message translates to:
  /// **'Testing & Debugging'**
  String get testingDebuggingTitle;

  /// No description provided for @testingDebuggingDesc.
  ///
  /// In en, this message translates to:
  /// **'Use these tools to verify app functionality.'**
  String get testingDebuggingDesc;

  /// No description provided for @testLocalNotificationBtn.
  ///
  /// In en, this message translates to:
  /// **'Test Local Notification'**
  String get testLocalNotificationBtn;

  /// No description provided for @auditLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogsTitle;

  /// No description provided for @failedToLoadAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load audit logs'**
  String get failedToLoadAuditLogs;

  /// No description provided for @noAuditLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No audit logs yet'**
  String get noAuditLogsYet;

  /// No description provided for @byUser.
  ///
  /// In en, this message translates to:
  /// **'By {name}'**
  String byUser(String name);

  /// No description provided for @noDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No details available for this log'**
  String get noDetailsAvailable;

  /// No description provided for @changesTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get changesTitle;

  /// No description provided for @adminCompaniesTitle.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get adminCompaniesTitle;

  /// No description provided for @failedToLoadCompanies.
  ///
  /// In en, this message translates to:
  /// **'Failed to load companies'**
  String get failedToLoadCompanies;

  /// No description provided for @noCompaniesYet.
  ///
  /// In en, this message translates to:
  /// **'No companies yet'**
  String get noCompaniesYet;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get actionStats;

  /// No description provided for @actionSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get actionSuspend;

  /// No description provided for @actionActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get actionActivate;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @suspendCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend Company'**
  String get suspendCompanyTitle;

  /// No description provided for @suspendCompanyContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to suspend \"{name}\"? This will deactivate their account.'**
  String suspendCompanyContent(String name);

  /// No description provided for @companySuspendedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} has been suspended'**
  String companySuspendedSuccess(String name);

  /// No description provided for @activateCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate Company'**
  String get activateCompanyTitle;

  /// No description provided for @activateCompanyContent.
  ///
  /// In en, this message translates to:
  /// **'Activate \"{name}\"?'**
  String activateCompanyContent(String name);

  /// No description provided for @companyActivatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} activated'**
  String companyActivatedSuccess(String name);

  /// No description provided for @deleteCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Company'**
  String get deleteCompanyTitle;

  /// No description provided for @deleteCompanyContent.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete \"{name}\"? This action cannot be undone.'**
  String deleteCompanyContent(String name);

  /// No description provided for @companyDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String companyDeletedSuccess(String name);

  /// No description provided for @companyStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Stats'**
  String get companyStatsTitle;

  /// No description provided for @noStatsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No stats available'**
  String get noStatsAvailable;

  /// No description provided for @editCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Company'**
  String get editCompanyTitle;

  /// No description provided for @createCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Company'**
  String get createCompanyTitle;

  /// No description provided for @companyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyNameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailLabel;

  /// No description provided for @companyOwnerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Owner Account'**
  String get companyOwnerAccountTitle;

  /// No description provided for @companyOwnerEditDesc.
  ///
  /// In en, this message translates to:
  /// **'Update owner details or enter a new password to reset account access.'**
  String get companyOwnerEditDesc;

  /// No description provided for @companyOwnerCreateDesc.
  ///
  /// In en, this message translates to:
  /// **'Account automatically created for the owner. Leave blank to default to company email and password Password123!.'**
  String get companyOwnerCreateDesc;

  /// No description provided for @ownerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerNameLabel;

  /// No description provided for @ownerLoginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner Login Email'**
  String get ownerLoginEmailLabel;

  /// No description provided for @newPasswordOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password (Optional)'**
  String get newPasswordOptionalLabel;

  /// No description provided for @ownerPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner Password'**
  String get ownerPasswordLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneLabel;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @gettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting...'**
  String get gettingLocation;

  /// No description provided for @getLocation.
  ///
  /// In en, this message translates to:
  /// **'Get Location'**
  String get getLocation;

  /// No description provided for @timezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezoneLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @socialMediaLinksTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Media Links'**
  String get socialMediaLinksTitle;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @noSocialMediaLinks.
  ///
  /// In en, this message translates to:
  /// **'No social media links added.'**
  String get noSocialMediaLinks;

  /// No description provided for @platformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platformLabel;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get urlLabel;

  /// No description provided for @companyLogoTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Logo'**
  String get companyLogoTitle;

  /// No description provided for @tapToChangeLogo.
  ///
  /// In en, this message translates to:
  /// **'Tap to change logo'**
  String get tapToChangeLogo;

  /// No description provided for @tapToUploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload logo'**
  String get tapToUploadLogo;

  /// No description provided for @btnUpdateCompany.
  ///
  /// In en, this message translates to:
  /// **'Update Company'**
  String get btnUpdateCompany;

  /// No description provided for @btnCreateCompany.
  ///
  /// In en, this message translates to:
  /// **'Create Company'**
  String get btnCreateCompany;

  /// No description provided for @companyUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Company updated successfully'**
  String get companyUpdatedSuccess;

  /// No description provided for @companyCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Company created successfully'**
  String get companyCreatedSuccess;

  /// No description provided for @companyCreatedAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Created!'**
  String get companyCreatedAlertTitle;

  /// No description provided for @ownerCredentialsGenerated.
  ///
  /// In en, this message translates to:
  /// **'Owner credentials generated for \"{name}\"'**
  String ownerCredentialsGenerated(String name);

  /// No description provided for @ownerEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'OWNER EMAIL'**
  String get ownerEmailTitle;

  /// No description provided for @ownerPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'OWNER PASSWORD'**
  String get ownerPasswordTitle;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copiedAll.
  ///
  /// In en, this message translates to:
  /// **'Copied All'**
  String get copiedAll;

  /// No description provided for @copyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy All'**
  String get copyAll;

  /// No description provided for @hrPortalDesc.
  ///
  /// In en, this message translates to:
  /// **'Process monthly payroll runs, manage dynamic shift rosters, and approve leaves on the go.'**
  String get hrPortalDesc;

  /// No description provided for @companyAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Company Administrator'**
  String get companyAdministrator;

  /// No description provided for @branchManagerView.
  ///
  /// In en, this message translates to:
  /// **'Branch Manager View'**
  String get branchManagerView;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @viewingAs.
  ///
  /// In en, this message translates to:
  /// **'Viewing as {branch}'**
  String viewingAs(String branch);

  /// No description provided for @branchManagerModeDesc.
  ///
  /// In en, this message translates to:
  /// **'You are in Branch Manager mode — data is scoped to this branch.'**
  String get branchManagerModeDesc;

  /// No description provided for @branchOverview.
  ///
  /// In en, this message translates to:
  /// **'Branch Overview'**
  String get branchOverview;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @todaysAttendance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Attendance'**
  String get todaysAttendance;

  /// No description provided for @pendingLeaves.
  ///
  /// In en, this message translates to:
  /// **'Pending Leaves'**
  String get pendingLeaves;

  /// No description provided for @errorLoadingBranchKpis.
  ///
  /// In en, this message translates to:
  /// **'Error loading branch KPIs: '**
  String get errorLoadingBranchKpis;

  /// No description provided for @branchOperations.
  ///
  /// In en, this message translates to:
  /// **'Branch Operations'**
  String get branchOperations;

  /// No description provided for @branchStaff.
  ///
  /// In en, this message translates to:
  /// **'Branch staff'**
  String get branchStaff;

  /// No description provided for @dailyRecords.
  ///
  /// In en, this message translates to:
  /// **'Daily records'**
  String get dailyRecords;

  /// No description provided for @payrollSettings.
  ///
  /// In en, this message translates to:
  /// **'Payroll Settings'**
  String get payrollSettings;

  /// No description provided for @rulesAndOvertime.
  ///
  /// In en, this message translates to:
  /// **'Rules & overtime'**
  String get rulesAndOvertime;

  /// No description provided for @pendingLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Leave Requests'**
  String get pendingLeaveRequests;

  /// No description provided for @noPendingLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'✅  No pending leave requests'**
  String get noPendingLeaveRequests;

  /// No description provided for @viewingTapToExit.
  ///
  /// In en, this message translates to:
  /// **'👁  Viewing {branch} — Tap to Exit'**
  String viewingTapToExit(String branch);

  /// No description provided for @fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get fullTime;

  /// No description provided for @partTime.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get partTime;

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @intern.
  ///
  /// In en, this message translates to:
  /// **'Intern'**
  String get intern;

  /// No description provided for @employeeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Employee Directory'**
  String get employeeDirectory;

  /// No description provided for @manageYourWorkforce.
  ///
  /// In en, this message translates to:
  /// **'Manage your workforce'**
  String get manageYourWorkforce;

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String peopleCount(int count);

  /// No description provided for @searchEmployeesHint.
  ///
  /// In en, this message translates to:
  /// **'Search employees...'**
  String get searchEmployeesHint;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @allDepartments.
  ///
  /// In en, this message translates to:
  /// **'All Departments'**
  String get allDepartments;

  /// No description provided for @branch.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branch;

  /// No description provided for @allBranches.
  ///
  /// In en, this message translates to:
  /// **'All Branches'**
  String get allBranches;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all filters'**
  String get clearAllFilters;

  /// No description provided for @employeeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} employee{s}'**
  String employeeCount(int count, String s);

  /// No description provided for @filtered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filtered;

  /// No description provided for @loadingEmployees.
  ///
  /// In en, this message translates to:
  /// **'Loading employees...'**
  String get loadingEmployees;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @deleteEmployeeTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Employee?'**
  String get deleteEmployeeTitle;

  /// No description provided for @deleteEmployeeConfirmPrefix.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete\n'**
  String get deleteEmployeeConfirmPrefix;

  /// No description provided for @deleteEmployeeConfirmSuffix.
  ///
  /// In en, this message translates to:
  /// **'?\n\nThis action cannot be undone.'**
  String get deleteEmployeeConfirmSuffix;

  /// No description provided for @employeeDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ {name} deleted successfully'**
  String employeeDeletedSuccess(String name);

  /// No description provided for @failedMsg.
  ///
  /// In en, this message translates to:
  /// **'❌ Failed: {e}'**
  String failedMsg(String e);

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noEmployeesYet.
  ///
  /// In en, this message translates to:
  /// **'No Employees Yet'**
  String get noEmployeesYet;

  /// No description provided for @adjustFiltersHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters to find what you\'re looking for.'**
  String get adjustFiltersHint;

  /// No description provided for @startBuildingTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Start building your team by adding your first employee.'**
  String get startBuildingTeamHint;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @failedToLoadEmployees.
  ///
  /// In en, this message translates to:
  /// **'Failed to load employees'**
  String get failedToLoadEmployees;

  /// No description provided for @checkConnectionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnectionTryAgain;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @employeeProfile.
  ///
  /// In en, this message translates to:
  /// **'Employee Profile'**
  String get employeeProfile;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// No description provided for @loadingProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading profile details...'**
  String get loadingProfileDetails;

  /// No description provided for @failedToLoadProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile details.'**
  String get failedToLoadProfileDetails;

  /// No description provided for @noPosition.
  ///
  /// In en, this message translates to:
  /// **'No Position'**
  String get noPosition;

  /// No description provided for @noDepartment.
  ///
  /// In en, this message translates to:
  /// **'No Department'**
  String get noDepartment;

  /// No description provided for @tabInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get tabInfo;

  /// No description provided for @tabLeaves.
  ///
  /// In en, this message translates to:
  /// **'Leaves'**
  String get tabLeaves;

  /// No description provided for @tabLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get tabLogs;

  /// No description provided for @tabContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get tabContact;

  /// No description provided for @employmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Employment details'**
  String get employmentDetails;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @employmentType.
  ///
  /// In en, this message translates to:
  /// **'Employment Type'**
  String get employmentType;

  /// No description provided for @joinDate.
  ///
  /// In en, this message translates to:
  /// **'Join Date'**
  String get joinDate;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalDetails;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @dob.
  ///
  /// In en, this message translates to:
  /// **'DOB'**
  String get dob;

  /// No description provided for @maritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital Status'**
  String get maritalStatus;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @payrollAndSalary.
  ///
  /// In en, this message translates to:
  /// **'Payroll & Salary'**
  String get payrollAndSalary;

  /// No description provided for @monthlySalary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Salary'**
  String get monthlySalary;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @bankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankAccount;

  /// No description provided for @adminNotes.
  ///
  /// In en, this message translates to:
  /// **'Admin Notes'**
  String get adminNotes;

  /// No description provided for @leaveBalances.
  ///
  /// In en, this message translates to:
  /// **'Leave Balances'**
  String get leaveBalances;

  /// No description provided for @noLeaveBalancesAllocated.
  ///
  /// In en, this message translates to:
  /// **'No leave balances allocated.'**
  String get noLeaveBalancesAllocated;

  /// No description provided for @allocated.
  ///
  /// In en, this message translates to:
  /// **'Allocated'**
  String get allocated;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @recentLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Recent Leave Requests'**
  String get recentLeaveRequests;

  /// No description provided for @noRecentLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'No recent leave requests.'**
  String get noRecentLeaveRequests;

  /// No description provided for @recentAttendanceLogs.
  ///
  /// In en, this message translates to:
  /// **'Recent Attendance logs'**
  String get recentAttendanceLogs;

  /// No description provided for @noAttendanceLogsFound.
  ///
  /// In en, this message translates to:
  /// **'No attendance logs found.'**
  String get noAttendanceLogsFound;

  /// No description provided for @emergencyContactDetails.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact details'**
  String get emergencyContactDetails;

  /// No description provided for @noEmergencyContactInfoProvided.
  ///
  /// In en, this message translates to:
  /// **'No emergency contact info provided.'**
  String get noEmergencyContactInfoProvided;

  /// No description provided for @contactName.
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get contactName;

  /// No description provided for @relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get relationship;

  /// No description provided for @employeeCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Employee created successfully'**
  String get employeeCreatedSuccess;

  /// No description provided for @employeeUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Employee updated successfully'**
  String get employeeUpdatedSuccess;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @createEmployee.
  ///
  /// In en, this message translates to:
  /// **'Create Employee'**
  String get createEmployee;

  /// No description provided for @updateEmployee.
  ///
  /// In en, this message translates to:
  /// **'Update Employee'**
  String get updateEmployee;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @khmerName.
  ///
  /// In en, this message translates to:
  /// **'Khmer Name'**
  String get khmerName;

  /// No description provided for @addPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Add Phone Number'**
  String get addPhoneNumber;

  /// No description provided for @uploadIdImages.
  ///
  /// In en, this message translates to:
  /// **'Upload ID Images'**
  String get uploadIdImages;

  /// No description provided for @employeeIdHint.
  ///
  /// In en, this message translates to:
  /// **'Employee ID (Leave blank to auto-generate)'**
  String get employeeIdHint;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Email Address *'**
  String get emailAddressRequired;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get single;

  /// No description provided for @married.
  ///
  /// In en, this message translates to:
  /// **'Married'**
  String get married;

  /// No description provided for @divorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get divorced;

  /// No description provided for @widowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get widowed;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelect;

  /// No description provided for @nationalIdPassport.
  ///
  /// In en, this message translates to:
  /// **'National ID / Passport'**
  String get nationalIdPassport;

  /// No description provided for @employmentDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Employment Details'**
  String get employmentDetailsRequired;

  /// No description provided for @employmentTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Employment Type *'**
  String get employmentTypeRequired;

  /// No description provided for @statusRequired.
  ///
  /// In en, this message translates to:
  /// **'Status *'**
  String get statusRequired;

  /// No description provided for @hireDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Hire Date *'**
  String get hireDateRequired;

  /// No description provided for @probationEnd.
  ///
  /// In en, this message translates to:
  /// **'Probation End'**
  String get probationEnd;

  /// No description provided for @terminationDate.
  ///
  /// In en, this message translates to:
  /// **'Termination Date'**
  String get terminationDate;

  /// No description provided for @systemRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'System Role *'**
  String get systemRoleRequired;

  /// No description provided for @roleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleEmployee;

  /// No description provided for @roleBranchManager.
  ///
  /// In en, this message translates to:
  /// **'Branch Manager'**
  String get roleBranchManager;

  /// No description provided for @roleCompanyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Company Admin'**
  String get roleCompanyAdmin;

  /// No description provided for @roleCompanyOwner.
  ///
  /// In en, this message translates to:
  /// **'Company Owner'**
  String get roleCompanyOwner;

  /// No description provided for @payrollAndBank.
  ///
  /// In en, this message translates to:
  /// **'Payroll & Bank'**
  String get payrollAndBank;

  /// No description provided for @bankAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Number'**
  String get bankAccountNumber;

  /// No description provided for @emergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContact;

  /// No description provided for @systemAccess.
  ///
  /// In en, this message translates to:
  /// **'System Access'**
  String get systemAccess;

  /// No description provided for @resetPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Reset password or create login account'**
  String get resetPasswordHint;

  /// No description provided for @createAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Create a login account for this employee'**
  String get createAccountHint;

  /// No description provided for @passwordLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Employee will use their email and this password to log in.'**
  String get passwordLoginHint;

  /// No description provided for @newEmployee.
  ///
  /// In en, this message translates to:
  /// **'New Employee'**
  String get newEmployee;

  /// No description provided for @tapPhotoToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap photo to change'**
  String get tapPhotoToChange;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'— None —'**
  String get none;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @terminated.
  ///
  /// In en, this message translates to:
  /// **'Terminated'**
  String get terminated;

  /// No description provided for @resigned.
  ///
  /// In en, this message translates to:
  /// **'Resigned'**
  String get resigned;

  /// No description provided for @attendanceLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance Logs'**
  String get attendanceLogsTitle;

  /// No description provided for @attendanceLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily logs & corrections'**
  String get attendanceLogsSubtitle;

  /// No description provided for @tabDailyLogs.
  ///
  /// In en, this message translates to:
  /// **'Daily Logs'**
  String get tabDailyLogs;

  /// No description provided for @tabCorrections.
  ///
  /// In en, this message translates to:
  /// **'Corrections'**
  String get tabCorrections;

  /// No description provided for @noAttendanceRecords.
  ///
  /// In en, this message translates to:
  /// **'No attendance records'**
  String get noAttendanceRecords;

  /// No description provided for @inTime.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inTime;

  /// No description provided for @outTime.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outTime;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @approvePreShiftOT.
  ///
  /// In en, this message translates to:
  /// **'Approve Pre-shift OT'**
  String get approvePreShiftOT;

  /// No description provided for @loadingLogs.
  ///
  /// In en, this message translates to:
  /// **'Loading logs...'**
  String get loadingLogs;

  /// No description provided for @preShiftOtApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Pre-shift OT approved'**
  String get preShiftOtApprovedSuccess;

  /// No description provided for @failedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedMessage(String error);

  /// No description provided for @noPendingCorrections.
  ///
  /// In en, this message translates to:
  /// **'No pending corrections'**
  String get noPendingCorrections;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @correctionApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Correction approved'**
  String get correctionApprovedSuccess;

  /// No description provided for @correctionRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Correction rejected'**
  String get correctionRejectedSuccess;

  /// No description provided for @leaveManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Management'**
  String get leaveManagementTitle;

  /// No description provided for @leaveManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Requests, balances & types'**
  String get leaveManagementSubtitle;

  /// No description provided for @tabRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get tabRequests;

  /// No description provided for @tabBalances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get tabBalances;

  /// No description provided for @tabTypes.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get tabTypes;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// No description provided for @filterApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get filterApproved;

  /// No description provided for @filterRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get filterRejected;

  /// No description provided for @noLeaveRequests.
  ///
  /// In en, this message translates to:
  /// **'No leave requests'**
  String get noLeaveRequests;

  /// No description provided for @noRequestsByFilter.
  ///
  /// In en, this message translates to:
  /// **'No {filter} requests'**
  String noRequestsByFilter(String filter);

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequest;

  /// No description provided for @newLeaveRequest.
  ///
  /// In en, this message translates to:
  /// **'New Leave Request'**
  String get newLeaveRequest;

  /// No description provided for @submitLeaveApp.
  ///
  /// In en, this message translates to:
  /// **'Submit a leave application'**
  String get submitLeaveApp;

  /// No description provided for @employeeRequired.
  ///
  /// In en, this message translates to:
  /// **'Employee *'**
  String get employeeRequired;

  /// No description provided for @selectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select employee'**
  String get selectEmployee;

  /// No description provided for @leaveTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Leave Type *'**
  String get leaveTypeRequired;

  /// No description provided for @startDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Start Date *'**
  String get startDateRequired;

  /// No description provided for @endDateRequired.
  ///
  /// In en, this message translates to:
  /// **'End Date *'**
  String get endDateRequired;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Reason *'**
  String get reasonRequired;

  /// No description provided for @reasonForLeaveHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for leave...'**
  String get reasonForLeaveHint;

  /// No description provided for @requestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get requestSubmitted;

  /// No description provided for @halfDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Half Day'**
  String get halfDayLabel;

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get daysShort;

  /// No description provided for @requestActioned.
  ///
  /// In en, this message translates to:
  /// **'Request {action}d'**
  String requestActioned(String action);

  /// No description provided for @addBalance.
  ///
  /// In en, this message translates to:
  /// **'Add Balance'**
  String get addBalance;

  /// No description provided for @carried.
  ///
  /// In en, this message translates to:
  /// **'Carried'**
  String get carried;

  /// No description provided for @editBalance.
  ///
  /// In en, this message translates to:
  /// **'Edit Balance'**
  String get editBalance;

  /// No description provided for @editBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Balance — {name}'**
  String editBalanceTitle(String name);

  /// No description provided for @allocatedDaysRequired.
  ///
  /// In en, this message translates to:
  /// **'Allocated Days *'**
  String get allocatedDaysRequired;

  /// No description provided for @allocatedDays.
  ///
  /// In en, this message translates to:
  /// **'Allocated Days'**
  String get allocatedDays;

  /// No description provided for @carriedForward.
  ///
  /// In en, this message translates to:
  /// **'Carried Forward'**
  String get carriedForward;

  /// No description provided for @balanceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Balance updated'**
  String get balanceUpdated;

  /// No description provided for @addLeaveBalance.
  ///
  /// In en, this message translates to:
  /// **'Add Leave Balance'**
  String get addLeaveBalance;

  /// No description provided for @addLeaveBalanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allocate days to an employee'**
  String get addLeaveBalanceSubtitle;

  /// No description provided for @singleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Single Employee'**
  String get singleEmployee;

  /// No description provided for @multipleEmployees.
  ///
  /// In en, this message translates to:
  /// **'Multiple / All Employees'**
  String get multipleEmployees;

  /// No description provided for @employeesRequired.
  ///
  /// In en, this message translates to:
  /// **'Employees *'**
  String get employeesRequired;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @employeesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} employee(s) selected'**
  String employeesSelected(int count);

  /// No description provided for @yearRequired.
  ///
  /// In en, this message translates to:
  /// **'Year *'**
  String get yearRequired;

  /// No description provided for @assignToEmployees.
  ///
  /// In en, this message translates to:
  /// **'Assign to Employees'**
  String get assignToEmployees;

  /// No description provided for @leaveBalanceAssignedMulti.
  ///
  /// In en, this message translates to:
  /// **'Leave balance assigned to {count} employee(s)'**
  String leaveBalanceAssignedMulti(int count);

  /// No description provided for @leaveBalanceCreated.
  ///
  /// In en, this message translates to:
  /// **'Leave balance created'**
  String get leaveBalanceCreated;

  /// No description provided for @noLeaveTypes.
  ///
  /// In en, this message translates to:
  /// **'No leave types'**
  String get noLeaveTypes;

  /// No description provided for @loadingTypes.
  ///
  /// In en, this message translates to:
  /// **'Loading types...'**
  String get loadingTypes;

  /// No description provided for @newType.
  ///
  /// In en, this message translates to:
  /// **'New Type'**
  String get newType;

  /// No description provided for @editLeaveType.
  ///
  /// In en, this message translates to:
  /// **'Edit Leave Type'**
  String get editLeaveType;

  /// No description provided for @addLeaveType.
  ///
  /// In en, this message translates to:
  /// **'Add Leave Type'**
  String get addLeaveType;

  /// No description provided for @generalInfo.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get generalInfo;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get nameRequired;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @daysPerYear.
  ///
  /// In en, this message translates to:
  /// **'Days per year'**
  String get daysPerYear;

  /// No description provided for @sortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort Order'**
  String get sortOrder;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @accrualAndBalances.
  ///
  /// In en, this message translates to:
  /// **'Accrual & Balances'**
  String get accrualAndBalances;

  /// No description provided for @prorateAccrual.
  ///
  /// In en, this message translates to:
  /// **'Prorate Accrual (adjust for mid-year joiners)'**
  String get prorateAccrual;

  /// No description provided for @allowCarryForward.
  ///
  /// In en, this message translates to:
  /// **'Allow Carry Forward'**
  String get allowCarryForward;

  /// No description provided for @maxCarryForwardDays.
  ///
  /// In en, this message translates to:
  /// **'Max Carry Forward Days (empty = unlimited)'**
  String get maxCarryForwardDays;

  /// No description provided for @rulesAndRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Rules & Restrictions'**
  String get rulesAndRestrictions;

  /// No description provided for @noticePeriodDays.
  ///
  /// In en, this message translates to:
  /// **'Notice Period (days) *'**
  String get noticePeriodDays;

  /// No description provided for @minTenureDays.
  ///
  /// In en, this message translates to:
  /// **'Minimum Tenure (days, 0 = none)'**
  String get minTenureDays;

  /// No description provided for @maxConsecutiveDays.
  ///
  /// In en, this message translates to:
  /// **'Max Consecutive Days (empty = unlimited)'**
  String get maxConsecutiveDays;

  /// No description provided for @genderRestriction.
  ///
  /// In en, this message translates to:
  /// **'Gender Restriction'**
  String get genderRestriction;

  /// No description provided for @allGenders.
  ///
  /// In en, this message translates to:
  /// **'All Genders'**
  String get allGenders;

  /// No description provided for @maleOnly.
  ///
  /// In en, this message translates to:
  /// **'Male Only'**
  String get maleOnly;

  /// No description provided for @femaleOnly.
  ///
  /// In en, this message translates to:
  /// **'Female Only'**
  String get femaleOnly;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @paidLeave.
  ///
  /// In en, this message translates to:
  /// **'Paid Leave'**
  String get paidLeave;

  /// No description provided for @allowHalfDayRequests.
  ///
  /// In en, this message translates to:
  /// **'Allow Half-Day Requests'**
  String get allowHalfDayRequests;

  /// No description provided for @requiresDocument.
  ///
  /// In en, this message translates to:
  /// **'Requires Document'**
  String get requiresDocument;

  /// No description provided for @leaveTypeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Leave type updated'**
  String get leaveTypeUpdated;

  /// No description provided for @leaveTypeCreated.
  ///
  /// In en, this message translates to:
  /// **'Leave type created'**
  String get leaveTypeCreated;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeLabel;

  /// No description provided for @inactiveLabel.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get inactiveLabel;

  /// No description provided for @daysPerYearLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} days/year'**
  String daysPerYearLabel(String days);

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @prorated.
  ///
  /// In en, this message translates to:
  /// **'Prorated'**
  String get prorated;

  /// No description provided for @halfDayBadge.
  ///
  /// In en, this message translates to:
  /// **'Half-Day'**
  String get halfDayBadge;

  /// No description provided for @carryFwd.
  ///
  /// In en, this message translates to:
  /// **'Carry Fwd: {days}d'**
  String carryFwd(String days);

  /// No description provided for @carryForwardBadge.
  ///
  /// In en, this message translates to:
  /// **'Carry Forward'**
  String get carryForwardBadge;

  /// No description provided for @maxConsec.
  ///
  /// In en, this message translates to:
  /// **'Max Consec: {days}d'**
  String maxConsec(String days);

  /// No description provided for @requiresDoc.
  ///
  /// In en, this message translates to:
  /// **'Requires Doc'**
  String get requiresDoc;

  /// No description provided for @genderBadge.
  ///
  /// In en, this message translates to:
  /// **'Gender: {gender}'**
  String genderBadge(String gender);

  /// No description provided for @noticeSort.
  ///
  /// In en, this message translates to:
  /// **'Notice: {notice}d · Sort: {sort}'**
  String noticeSort(String notice, String sort);

  /// No description provided for @minTenureBadge.
  ///
  /// In en, this message translates to:
  /// **'Min Tenure: {days}d'**
  String minTenureBadge(String days);

  /// No description provided for @deleteLeaveType.
  ///
  /// In en, this message translates to:
  /// **'Delete Leave Type?'**
  String get deleteLeaveType;

  /// No description provided for @deleteLeaveTypeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete\n\"{name}\"?\n\nThis action cannot be undone.'**
  String deleteLeaveTypeConfirm(String name);

  /// No description provided for @leaveTypeDeleted.
  ///
  /// In en, this message translates to:
  /// **'✅ Leave type deleted successfully'**
  String get leaveTypeDeleted;

  /// No description provided for @nothingToShow.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show here yet.'**
  String get nothingToShow;

  /// No description provided for @failedToLoadData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadData;

  /// No description provided for @shiftsAndCalendars.
  ///
  /// In en, this message translates to:
  /// **'Shifts & Calendars'**
  String get shiftsAndCalendars;

  /// No description provided for @manageWorkSchedules.
  ///
  /// In en, this message translates to:
  /// **'Manage work schedules'**
  String get manageWorkSchedules;

  /// No description provided for @shiftsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} shifts'**
  String shiftsCount(String count);

  /// No description provided for @loadingShifts.
  ///
  /// In en, this message translates to:
  /// **'Loading shifts...'**
  String get loadingShifts;

  /// No description provided for @activeShiftBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get activeShiftBadge;

  /// No description provided for @inactiveShiftBadge.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get inactiveShiftBadge;

  /// No description provided for @overnightBadge.
  ///
  /// In en, this message translates to:
  /// **'OVERNIGHT'**
  String get overnightBadge;

  /// No description provided for @breakTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Break {start} – {end}'**
  String breakTimeRange(String start, String end);

  /// No description provided for @gracePeriodBadge.
  ///
  /// In en, this message translates to:
  /// **'{grace}m grace'**
  String gracePeriodBadge(String grace);

  /// No description provided for @otThresholdBadge.
  ///
  /// In en, this message translates to:
  /// **'OT≥{ot}m'**
  String otThresholdBadge(String ot);

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @deleteShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Shift?'**
  String get deleteShiftTitle;

  /// No description provided for @deleteShiftConfirmPrefix.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete\n'**
  String get deleteShiftConfirmPrefix;

  /// No description provided for @deleteShiftConfirmSuffix.
  ///
  /// In en, this message translates to:
  /// **'?\n\nThis action cannot be undone.'**
  String get deleteShiftConfirmSuffix;

  /// No description provided for @shiftDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Shift deleted'**
  String shiftDeletedSuccess(String name);

  /// No description provided for @shiftDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Failed to delete: {error}'**
  String shiftDeleteFailed(String error);

  /// No description provided for @assignEmployeesTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Employees'**
  String get assignEmployeesTitle;

  /// No description provided for @assignEmployeesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{name} · {count} selected'**
  String assignEmployeesSubtitle(String name, String count);

  /// No description provided for @noEmployeesFound.
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get noEmployeesFound;

  /// No description provided for @employeesCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} employees'**
  String employeesCountLabel(String count);

  /// No description provided for @assignedBadge.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedBadge;

  /// No description provided for @otherShiftBadge.
  ///
  /// In en, this message translates to:
  /// **'Other Shift'**
  String get otherShiftBadge;

  /// No description provided for @assignCount.
  ///
  /// In en, this message translates to:
  /// **'Assign {count}'**
  String assignCount(String count);

  /// No description provided for @assignSuccess.
  ///
  /// In en, this message translates to:
  /// **'{count} assigned'**
  String assignSuccess(String count);

  /// No description provided for @assignSuccessWithFail.
  ///
  /// In en, this message translates to:
  /// **'{success} assigned, {fail} failed'**
  String assignSuccessWithFail(String success, String fail);

  /// No description provided for @assignFailedError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String assignFailedError(String error);

  /// No description provided for @newShift.
  ///
  /// In en, this message translates to:
  /// **'New Shift'**
  String get newShift;

  /// No description provided for @noShiftsYet.
  ///
  /// In en, this message translates to:
  /// **'No Shifts Yet'**
  String get noShiftsYet;

  /// No description provided for @createFirstShiftDesc.
  ///
  /// In en, this message translates to:
  /// **'Create your first shift to start managing work schedules.'**
  String get createFirstShiftDesc;

  /// No description provided for @createFirstShiftBtn.
  ///
  /// In en, this message translates to:
  /// **'Create First Shift'**
  String get createFirstShiftBtn;

  /// No description provided for @failedToLoadShifts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load shifts'**
  String get failedToLoadShifts;

  /// No description provided for @checkConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnectionRetry;

  /// No description provided for @dayMo.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get dayMo;

  /// No description provided for @dayTu.
  ///
  /// In en, this message translates to:
  /// **'Tu'**
  String get dayTu;

  /// No description provided for @dayWe.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get dayWe;

  /// No description provided for @dayTh.
  ///
  /// In en, this message translates to:
  /// **'Th'**
  String get dayTh;

  /// No description provided for @dayFr.
  ///
  /// In en, this message translates to:
  /// **'Fr'**
  String get dayFr;

  /// No description provided for @daySa.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get daySa;

  /// No description provided for @daySu.
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get daySu;

  /// No description provided for @editScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Schedule'**
  String get editScheduleTitle;

  /// No description provided for @newScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'New Schedule'**
  String get newScheduleTitle;

  /// No description provided for @editScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update shift details'**
  String get editScheduleSubtitle;

  /// No description provided for @newScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up work hours & days'**
  String get newScheduleSubtitle;

  /// No description provided for @generalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get generalInfoTitle;

  /// No description provided for @scheduleNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule Name'**
  String get scheduleNameLabel;

  /// No description provided for @scheduleNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Standard Office Hours'**
  String get scheduleNameHint;

  /// No description provided for @nameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequiredError;

  /// No description provided for @shortCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Short Code (optional)'**
  String get shortCodeLabel;

  /// No description provided for @shortCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. STD-01'**
  String get shortCodeHint;

  /// No description provided for @weeklyScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Schedule'**
  String get weeklyScheduleTitle;

  /// No description provided for @copyMonToAll.
  ///
  /// In en, this message translates to:
  /// **'Copy Mon to all'**
  String get copyMonToAll;

  /// No description provided for @selectOneWorkingDayError.
  ///
  /// In en, this message translates to:
  /// **'Select at least one working day'**
  String get selectOneWorkingDayError;

  /// No description provided for @shiftCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Shift created'**
  String get shiftCreatedSuccess;

  /// No description provided for @shiftUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Shift updated successfully'**
  String get shiftUpdatedSuccess;

  /// No description provided for @shiftFailedError.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String shiftFailedError(String error);

  /// No description provided for @rulesAllowancesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules & Allowances'**
  String get rulesAllowancesTitle;

  /// No description provided for @gracePeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Grace Period (min)'**
  String get gracePeriodLabel;

  /// No description provided for @otThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'OT Threshold (min)'**
  String get otThresholdLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @overnightShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Overnight Shift'**
  String get overnightShiftTitle;

  /// No description provided for @overnightShiftSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This shift crosses midnight'**
  String get overnightShiftSubtitle;

  /// No description provided for @activeScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Schedule'**
  String get activeScheduleTitle;

  /// No description provided for @activeScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available for employee assignment'**
  String get activeScheduleSubtitle;

  /// No description provided for @saveChangesBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesBtn;

  /// No description provided for @createScheduleBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Schedule'**
  String get createScheduleBtn;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTimeLabel;

  /// No description provided for @scheduledDayOff.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Day Off'**
  String get scheduledDayOff;

  /// No description provided for @dayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get dayOff;

  /// No description provided for @payrollManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Payroll Management'**
  String get payrollManagementTitle;

  /// No description provided for @runsTab.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get runsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @generatePayrollBtn.
  ///
  /// In en, this message translates to:
  /// **'Generate Payroll'**
  String get generatePayrollBtn;

  /// No description provided for @noPayrollRuns.
  ///
  /// In en, this message translates to:
  /// **'No payroll runs'**
  String get noPayrollRuns;

  /// No description provided for @loadingPayrollRuns.
  ///
  /// In en, this message translates to:
  /// **'Loading payroll runs...'**
  String get loadingPayrollRuns;

  /// No description provided for @markCompletedBtn.
  ///
  /// In en, this message translates to:
  /// **'Mark Completed'**
  String get markCompletedBtn;

  /// No description provided for @payrollRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Payroll Run {period}'**
  String payrollRunTitle(String period);

  /// No description provided for @payrollRunPrompt.
  ///
  /// In en, this message translates to:
  /// **'Would you like to mark this Payroll Run as COMPLETED or view Payslips?'**
  String get payrollRunPrompt;

  /// No description provided for @viewPayslipsBtn.
  ///
  /// In en, this message translates to:
  /// **'View Payslips'**
  String get viewPayslipsBtn;

  /// No description provided for @payrollGeneratedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Payroll generated successfully'**
  String get payrollGeneratedSuccess;

  /// No description provided for @formulasHandbookTitle.
  ///
  /// In en, this message translates to:
  /// **'Formulas Handbook'**
  String get formulasHandbookTitle;

  /// No description provided for @formulasHandbookDesc.
  ///
  /// In en, this message translates to:
  /// **'View active payroll calculations'**
  String get formulasHandbookDesc;

  /// No description provided for @generalSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettingsTitle;

  /// No description provided for @payrollPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payroll Period'**
  String get payrollPeriodLabel;

  /// No description provided for @payrollStartDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Payroll Start Day (1-31)'**
  String get payrollStartDayLabel;

  /// No description provided for @workingDaysCalcTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Working Days Calculation Type'**
  String get workingDaysCalcTypeLabel;

  /// No description provided for @fixedWorkingDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed Working Days per Period'**
  String get fixedWorkingDaysLabel;

  /// No description provided for @currencySymbolLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency Symbol (e.g. \$)'**
  String get currencySymbolLabel;

  /// No description provided for @overtimeSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Overtime Settings'**
  String get overtimeSettingsTitle;

  /// No description provided for @enableOvertimePayLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Overtime Pay'**
  String get enableOvertimePayLabel;

  /// No description provided for @overtimeThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Overtime Threshold (hours/day)'**
  String get overtimeThresholdLabel;

  /// No description provided for @regularOtMultiplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Regular OT Multiplier (e.g. 1.5)'**
  String get regularOtMultiplierLabel;

  /// No description provided for @restDayOtMultiplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest Day OT Multiplier (e.g. 2.0)'**
  String get restDayOtMultiplierLabel;

  /// No description provided for @publicHolidayOtMultiplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Public Holiday OT Multiplier (e.g. 2.0)'**
  String get publicHolidayOtMultiplierLabel;

  /// No description provided for @companyHolidayOtMultiplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Holiday OT Multiplier (e.g. 1.5)'**
  String get companyHolidayOtMultiplierLabel;

  /// No description provided for @lateDeductionSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Late Deduction Settings'**
  String get lateDeductionSettingsTitle;

  /// No description provided for @enableLateDeductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Enable Late Deductions'**
  String get enableLateDeductionsLabel;

  /// No description provided for @gracePeriodMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Grace Period (minutes)'**
  String get gracePeriodMinutesLabel;

  /// No description provided for @calculationMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculation Method'**
  String get calculationMethodLabel;

  /// No description provided for @fixedPenaltyAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed Penalty Amount (\$)'**
  String get fixedPenaltyAmountLabel;

  /// No description provided for @perMinuteMultiplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Per-Minute Multiplier (e.g. 1.0 = exact salary)'**
  String get perMinuteMultiplierLabel;

  /// No description provided for @earlyLeavePenaltiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Early Leave Penalties'**
  String get earlyLeavePenaltiesTitle;

  /// No description provided for @earlyLeaveGraceLabel.
  ///
  /// In en, this message translates to:
  /// **'Early Leave Grace (minutes)'**
  String get earlyLeaveGraceLabel;

  /// No description provided for @deductionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Deduction Type'**
  String get deductionTypeLabel;

  /// No description provided for @preShiftEarlyClockInTitle.
  ///
  /// In en, this message translates to:
  /// **'Pre-Shift & Early Clock-In'**
  String get preShiftEarlyClockInTitle;

  /// No description provided for @earlyClockInPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Early Clock-In Policy'**
  String get earlyClockInPolicyLabel;

  /// No description provided for @preShiftOtMultiplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Pre-Shift OT Multiplier'**
  String get preShiftOtMultiplierLabel;

  /// No description provided for @maxAllowedEarlyMinutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Allowed Early Minutes'**
  String get maxAllowedEarlyMinutesLabel;

  /// No description provided for @halfDaySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Half-Day Settings'**
  String get halfDaySettingsTitle;

  /// No description provided for @halfDayMinHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Half-Day Minimum Hours'**
  String get halfDayMinHoursLabel;

  /// No description provided for @halfDayDeductionPctLabel.
  ///
  /// In en, this message translates to:
  /// **'Half-Day Deduction %'**
  String get halfDayDeductionPctLabel;

  /// No description provided for @saveSettingsBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettingsBtn;

  /// No description provided for @loadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading settings...'**
  String get loadingSettings;

  /// No description provided for @periodStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Period Start'**
  String get periodStartLabel;

  /// No description provided for @periodEndLabel.
  ///
  /// In en, this message translates to:
  /// **'Period End'**
  String get periodEndLabel;

  /// No description provided for @generateBtn.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generateBtn;

  /// No description provided for @payrollRunMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'🎉 Payroll Run marked as COMPLETED!'**
  String get payrollRunMarkedCompleted;

  /// No description provided for @generatePayrollPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'Select payroll period to generate employee salary records.'**
  String get generatePayrollPromptDesc;

  /// No description provided for @weeklyLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weeklyLabel;

  /// No description provided for @biWeeklyLabel.
  ///
  /// In en, this message translates to:
  /// **'Bi-Weekly'**
  String get biWeeklyLabel;

  /// No description provided for @monthlyLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthlyLabel;

  /// No description provided for @calendarDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar Days'**
  String get calendarDaysLabel;

  /// No description provided for @calendarMinusHolidaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Calendar Minus Holidays'**
  String get calendarMinusHolidaysLabel;

  /// No description provided for @fixedDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed Days'**
  String get fixedDaysLabel;

  /// No description provided for @treatAsOvertimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Treat as Overtime'**
  String get treatAsOvertimeLabel;

  /// No description provided for @paidOutsideLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid Outside (No OT Mult)'**
  String get paidOutsideLabel;

  /// No description provided for @flatAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Flat Amount'**
  String get flatAmountLabel;

  /// No description provided for @hourlyRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get hourlyRateLabel;

  /// No description provided for @perMinuteRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Per Minute Rate'**
  String get perMinuteRateLabel;

  /// No description provided for @halfDayDeductionLabel.
  ///
  /// In en, this message translates to:
  /// **'Half Day Deduction'**
  String get halfDayDeductionLabel;

  /// No description provided for @ignoreNoExtraPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Ignore (No Extra Pay)'**
  String get ignoreNoExtraPayLabel;

  /// No description provided for @payrollDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Payroll {period}'**
  String payrollDetailTitle(String period);

  /// No description provided for @exportToExcelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcelTooltip;

  /// No description provided for @loadingPayslips.
  ///
  /// In en, this message translates to:
  /// **'Loading payslips...'**
  String get loadingPayslips;

  /// No description provided for @payrollDetailError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String payrollDetailError(String error);

  /// No description provided for @totalGrossLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Gross'**
  String get totalGrossLabel;

  /// No description provided for @deductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Deductions'**
  String get deductionsLabel;

  /// No description provided for @netPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Pay'**
  String get netPayLabel;

  /// No description provided for @employeesCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'{count} employees'**
  String employeesCountSuffix(int count);

  /// No description provided for @noPayslipsFound.
  ///
  /// In en, this message translates to:
  /// **'No payslips found'**
  String get noPayslipsFound;

  /// No description provided for @exportedToPath.
  ///
  /// In en, this message translates to:
  /// **'✅ Exported to {path}'**
  String exportedToPath(String path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @basicSalaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Basic Salary'**
  String get basicSalaryLabel;

  /// No description provided for @overtimePayLabel.
  ///
  /// In en, this message translates to:
  /// **'Overtime Pay'**
  String get overtimePayLabel;

  /// No description provided for @allowancesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowances'**
  String get allowancesLabel;

  /// No description provided for @otherEarningsLabel.
  ///
  /// In en, this message translates to:
  /// **'Other Earnings'**
  String get otherEarningsLabel;

  /// No description provided for @grossSalaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross Salary'**
  String get grossSalaryLabel;

  /// No description provided for @taxDeductionLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax Deduction (10%)'**
  String get taxDeductionLabel;

  /// No description provided for @insuranceDeductionLabel.
  ///
  /// In en, this message translates to:
  /// **'Insurance (5%)'**
  String get insuranceDeductionLabel;

  /// No description provided for @lateDeductionLabel.
  ///
  /// In en, this message translates to:
  /// **'Late Deduction'**
  String get lateDeductionLabel;

  /// No description provided for @otherDeductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Other Deductions'**
  String get otherDeductionsLabel;

  /// No description provided for @totalDeductionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Deductions'**
  String get totalDeductionsLabel;

  /// No description provided for @netSalaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Salary'**
  String get netSalaryLabel;

  /// No description provided for @workingDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get workingDaysLabel;

  /// No description provided for @presentLabel.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get presentLabel;

  /// No description provided for @lateLabel2.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get lateLabel2;

  /// No description provided for @otHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'OT Hours'**
  String get otHoursLabel;

  /// No description provided for @branchPayrollTitle.
  ///
  /// In en, this message translates to:
  /// **'{branch} Payroll'**
  String branchPayrollTitle(String branch);

  /// No description provided for @branchCustomizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Branch Customization'**
  String get branchCustomizationTitle;

  /// No description provided for @branchCustomizationDesc.
  ///
  /// In en, this message translates to:
  /// **'If disabled, this branch will inherit the company-wide payroll rules.'**
  String get branchCustomizationDesc;

  /// No description provided for @useCustomBranchRulesLabel.
  ///
  /// In en, this message translates to:
  /// **'Use Custom Branch Rules'**
  String get useCustomBranchRulesLabel;

  /// No description provided for @inheritingCompanyRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Inheriting Company Rules'**
  String get inheritingCompanyRulesTitle;

  /// No description provided for @inheritingCompanyRulesDesc.
  ///
  /// In en, this message translates to:
  /// **'This branch uses the global company payroll settings. You can view how they calculate in the Formulas Handbook (top right icon).'**
  String get inheritingCompanyRulesDesc;

  /// No description provided for @saveBranchSettingsBtn.
  ///
  /// In en, this message translates to:
  /// **'Save Branch Settings'**
  String get saveBranchSettingsBtn;

  /// No description provided for @branchSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'✅ Branch settings saved'**
  String get branchSettingsSaved;

  /// No description provided for @deductionRateAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Deduction Rate / Amount'**
  String get deductionRateAmountLabel;

  /// No description provided for @formulasHandbookScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Payroll Formulas Handbook'**
  String get formulasHandbookScreenTitle;

  /// No description provided for @formulasHandbookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify how your current rules translate into mathematical formulas for payroll calculation.'**
  String get formulasHandbookSubtitle;

  /// No description provided for @formulasExampleBasis.
  ///
  /// In en, this message translates to:
  /// **'Real-World Example Basis: '**
  String get formulasExampleBasis;

  /// No description provided for @formulasExampleBasisDetail.
  ///
  /// In en, this message translates to:
  /// **'For the examples below, we assume an employee earns a base salary of '**
  String get formulasExampleBasisDetail;

  /// No description provided for @formulasSalaryExample.
  ///
  /// In en, this message translates to:
  /// **'{symbol}1,000/month'**
  String formulasSalaryExample(String symbol);

  /// No description provided for @formulasWorkHours.
  ///
  /// In en, this message translates to:
  /// **' and works 8 hours per day.'**
  String get formulasWorkHours;

  /// No description provided for @hourlyRateCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate Calculation'**
  String get hourlyRateCalcTitle;

  /// No description provided for @hourlyRateCalcDesc.
  ///
  /// In en, this message translates to:
  /// **'The hourly rate is the foundation for all overtime and deduction calculations.'**
  String get hourlyRateCalcDesc;

  /// No description provided for @hourlyRateFormulaFixed.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate = (Monthly Salary / {fixedDays} fixed days) / 8 hours'**
  String hourlyRateFormulaFixed(int fixedDays);

  /// No description provided for @hourlyRateFormulaActual.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate = (Monthly Salary / Actual working days in month) / 8 hours'**
  String get hourlyRateFormulaActual;

  /// No description provided for @hourlyRateExampleFixed.
  ///
  /// In en, this message translates to:
  /// **'Example: ({symbol}1,000 ÷ {fixedDays} days) ÷ 8 hrs = {symbol}{rate} per hour.'**
  String hourlyRateExampleFixed(String symbol, int fixedDays, String rate);

  /// No description provided for @hourlyRateExampleActual.
  ///
  /// In en, this message translates to:
  /// **'Example: ({symbol}1,000 ÷ 22 days) ÷ 8 hrs = {symbol}{rate} per hour.'**
  String hourlyRateExampleActual(String symbol, String rate);

  /// No description provided for @lateDeductionFormulaTitle.
  ///
  /// In en, this message translates to:
  /// **'Late Deduction Formula'**
  String get lateDeductionFormulaTitle;

  /// No description provided for @earlyLeaveFormulaTitle.
  ///
  /// In en, this message translates to:
  /// **'Early Leave Deduction Formula'**
  String get earlyLeaveFormulaTitle;

  /// No description provided for @lateDeductionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Late deductions are currently disabled.'**
  String get lateDeductionDisabled;

  /// No description provided for @earlyLeaveDeductionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Early leave deductions are currently disabled.'**
  String get earlyLeaveDeductionDisabled;

  /// No description provided for @lateGraceDesc.
  ///
  /// In en, this message translates to:
  /// **'Employees have a grace period of {grace} minutes. If an employee is late beyond the grace period, the deduction is calculated as follows:'**
  String lateGraceDesc(int grace);

  /// No description provided for @earlyLeaveGraceDesc.
  ///
  /// In en, this message translates to:
  /// **'Employees have a grace period of {grace} minutes. If an employee leaves early beyond the grace period, the deduction is calculated as follows:'**
  String earlyLeaveGraceDesc(int grace);

  /// No description provided for @lateFormulaPerMinute.
  ///
  /// In en, this message translates to:
  /// **'Total Deduction = (Late Minutes - {grace}) * (Hourly Rate / 60) * {rate} (multiplier)'**
  String lateFormulaPerMinute(int grace, String rate);

  /// No description provided for @lateExamplePerMinute.
  ///
  /// In en, this message translates to:
  /// **'Example (30 mins late): (30 - {grace}m grace) * ({symbol}{hourlyRate}/60) * {rate}x = {symbol}{amount} deducted.'**
  String lateExamplePerMinute(
    int grace,
    String symbol,
    String hourlyRate,
    String rate,
    String amount,
  );

  /// No description provided for @lateFormulaFixed.
  ///
  /// In en, this message translates to:
  /// **'Total Deduction = {symbol}{rate} (Fixed flat fee)'**
  String lateFormulaFixed(String symbol, String rate);

  /// No description provided for @lateExampleFixed.
  ///
  /// In en, this message translates to:
  /// **'Example: Employee is 20 minutes late (past the {grace}m grace). They are deducted exactly {symbol}{rate}.'**
  String lateExampleFixed(int grace, String symbol, String rate);

  /// No description provided for @lateFormulaHalfDay.
  ///
  /// In en, this message translates to:
  /// **'Total Deduction = Half-Day Salary (i.e. Daily Rate / 2)'**
  String get lateFormulaHalfDay;

  /// No description provided for @lateExampleHalfDay.
  ///
  /// In en, this message translates to:
  /// **'Example: Employee is 20 minutes late (past grace). Half day salary ({symbol}{amount}) is deducted.'**
  String lateExampleHalfDay(String symbol, String amount);

  /// No description provided for @earlyLeaveFormulaPerMinute.
  ///
  /// In en, this message translates to:
  /// **'Total Deduction = (Early Leave Minutes - {grace}) * (Hourly Rate / 60) * {rate} (multiplier)'**
  String earlyLeaveFormulaPerMinute(int grace, String rate);

  /// No description provided for @earlyLeaveExamplePerMinute.
  ///
  /// In en, this message translates to:
  /// **'Example (30 mins early): (30 - {grace}m grace) * ({symbol}{hourlyRate}/60) * {rate}x = {symbol}{amount} deducted.'**
  String earlyLeaveExamplePerMinute(
    int grace,
    String symbol,
    String hourlyRate,
    String rate,
    String amount,
  );

  /// No description provided for @earlyLeaveFormulaFixed.
  ///
  /// In en, this message translates to:
  /// **'Total Deduction = {symbol}{rate} (Fixed flat fee)'**
  String earlyLeaveFormulaFixed(String symbol, String rate);

  /// No description provided for @earlyLeaveExampleFixed.
  ///
  /// In en, this message translates to:
  /// **'Example: Employee leaves 20 minutes early (past the {grace}m grace). They are deducted exactly {symbol}{rate}.'**
  String earlyLeaveExampleFixed(int grace, String symbol, String rate);

  /// No description provided for @earlyLeaveFormulaHalfDay.
  ///
  /// In en, this message translates to:
  /// **'Total Deduction = Half-Day Salary (i.e. Daily Rate / 2)'**
  String get earlyLeaveFormulaHalfDay;

  /// No description provided for @earlyLeaveExampleHalfDay.
  ///
  /// In en, this message translates to:
  /// **'Example: Employee leaves 20 minutes early (past grace). Half day salary ({symbol}{amount}) is deducted.'**
  String earlyLeaveExampleHalfDay(String symbol, String amount);

  /// No description provided for @overtimeCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'Overtime Calculation'**
  String get overtimeCalcTitle;

  /// No description provided for @overtimeDisabled.
  ///
  /// In en, this message translates to:
  /// **'Overtime is currently disabled.'**
  String get overtimeDisabled;

  /// No description provided for @overtimeCalcDesc.
  ///
  /// In en, this message translates to:
  /// **'Overtime payout is calculated by multiplying the active Hourly Rate by the OT hours worked and the respective day\'s multiplier.'**
  String get overtimeCalcDesc;

  /// No description provided for @otRegularWorkDay.
  ///
  /// In en, this message translates to:
  /// **'Regular Work Day'**
  String get otRegularWorkDay;

  /// No description provided for @otRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest Day (Day Off)'**
  String get otRestDay;

  /// No description provided for @otHoliday.
  ///
  /// In en, this message translates to:
  /// **'Company / Public Holiday'**
  String get otHoliday;

  /// No description provided for @otFormulaRegular.
  ///
  /// In en, this message translates to:
  /// **'OT Payout = OT Hours * Hourly Rate * {multiplier}'**
  String otFormulaRegular(String multiplier);

  /// No description provided for @otExampleRegular.
  ///
  /// In en, this message translates to:
  /// **'Example (2 hours OT): 2 hrs * {symbol}{hourlyRate} * {multiplier}x = {symbol}{amount} total pay.'**
  String otExampleRegular(
    String symbol,
    String hourlyRate,
    String multiplier,
    String amount,
  );

  /// No description provided for @otExampleFullDay.
  ///
  /// In en, this message translates to:
  /// **'Example (8 hours worked): 8 hrs * {symbol}{hourlyRate} * {multiplier}x = {symbol}{amount} total pay.'**
  String otExampleFullDay(
    String symbol,
    String hourlyRate,
    String multiplier,
    String amount,
  );

  /// No description provided for @earlyClockInPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Early Clock-in Policy'**
  String get earlyClockInPolicyTitle;

  /// No description provided for @earlyClockInIgnoreFormula.
  ///
  /// In en, this message translates to:
  /// **'Early clock-ins do NOT generate extra pay (Ignored in payroll).'**
  String get earlyClockInIgnoreFormula;

  /// No description provided for @earlyClockInOtFormula.
  ///
  /// In en, this message translates to:
  /// **'Early clock-ins are treated as OT.\nPayout = Early OT Hours (Max {maxMins} mins) * Hourly Rate * {multiplier}'**
  String earlyClockInOtFormula(int maxMins, String multiplier);

  /// No description provided for @earlyClockInOtExample.
  ///
  /// In en, this message translates to:
  /// **'Example (1 hr early): 1 hr * {symbol}{hourlyRate} * {multiplier}x = {symbol}{amount} total pay.'**
  String earlyClockInOtExample(
    String symbol,
    String hourlyRate,
    String multiplier,
    String amount,
  );

  /// No description provided for @earlyClockInPaidOutsideFormula.
  ///
  /// In en, this message translates to:
  /// **'Early clock-ins are paid manually outside of standard payroll.'**
  String get earlyClockInPaidOutsideFormula;

  /// No description provided for @financeSection.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeSection;

  /// No description provided for @operationsSection.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operationsSection;

  /// No description provided for @talentSection.
  ///
  /// In en, this message translates to:
  /// **'Talent'**
  String get talentSection;

  /// No description provided for @systemSection.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemSection;

  /// No description provided for @branchSection.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branchSection;

  /// No description provided for @morePayroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get morePayroll;

  /// No description provided for @morePayrollDesc.
  ///
  /// In en, this message translates to:
  /// **'Process runs'**
  String get morePayrollDesc;

  /// No description provided for @moreExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get moreExpenses;

  /// No description provided for @moreExpensesDesc.
  ///
  /// In en, this message translates to:
  /// **'Review claims'**
  String get moreExpensesDesc;

  /// No description provided for @moreShifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get moreShifts;

  /// No description provided for @moreShiftsDesc.
  ///
  /// In en, this message translates to:
  /// **'Work schedules'**
  String get moreShiftsDesc;

  /// No description provided for @moreHolidays.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get moreHolidays;

  /// No description provided for @moreHolidaysDesc.
  ///
  /// In en, this message translates to:
  /// **'Company holidays'**
  String get moreHolidaysDesc;

  /// No description provided for @moreAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get moreAssets;

  /// No description provided for @moreAssetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Devices & stock'**
  String get moreAssetsDesc;

  /// No description provided for @moreAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get moreAnnouncements;

  /// No description provided for @moreAnnouncementsDesc.
  ///
  /// In en, this message translates to:
  /// **'Broadcast alerts'**
  String get moreAnnouncementsDesc;

  /// No description provided for @moreRecruitment.
  ///
  /// In en, this message translates to:
  /// **'Recruitment'**
  String get moreRecruitment;

  /// No description provided for @moreRecruitmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Jobs & candidates'**
  String get moreRecruitmentDesc;

  /// No description provided for @morePerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get morePerformance;

  /// No description provided for @morePerformanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Reviews & training'**
  String get morePerformanceDesc;

  /// No description provided for @moreReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get moreReports;

  /// No description provided for @moreReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Analytics & exports'**
  String get moreReportsDesc;

  /// No description provided for @moreDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get moreDocuments;

  /// No description provided for @moreDocumentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Company files'**
  String get moreDocumentsDesc;

  /// No description provided for @moreRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get moreRoles;

  /// No description provided for @moreRolesDesc.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get moreRolesDesc;

  /// No description provided for @moreNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get moreNotifications;

  /// No description provided for @moreNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'View inbox'**
  String get moreNotificationsDesc;

  /// No description provided for @morePolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get morePolicies;

  /// No description provided for @morePoliciesDesc.
  ///
  /// In en, this message translates to:
  /// **'Rules & guidelines'**
  String get morePoliciesDesc;

  /// No description provided for @moreHrStructure.
  ///
  /// In en, this message translates to:
  /// **'HR Structure'**
  String get moreHrStructure;

  /// No description provided for @moreHrStructureDesc.
  ///
  /// In en, this message translates to:
  /// **'Depts & branches'**
  String get moreHrStructureDesc;

  /// No description provided for @logoutBtn.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutBtn;

  /// No description provided for @rolesPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get rolesPermissionsTitle;

  /// No description provided for @noCustomRoles.
  ///
  /// In en, this message translates to:
  /// **'No custom roles'**
  String get noCustomRoles;

  /// No description provided for @createRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Role'**
  String get createRoleTitle;

  /// No description provided for @createBtn.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createBtn;

  /// No description provided for @sendNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotificationTitle;

  /// No description provided for @recipientLabel.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipientLabel;

  /// No description provided for @selectEmployeeHint.
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get selectEmployeeHint;

  /// No description provided for @notificationTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get notificationTitleLabel;

  /// No description provided for @notificationTitleHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Meeting at 3 PM'**
  String get notificationTitleHint;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Write the message details here...'**
  String get messageHint;

  /// No description provided for @sendNotificationBtn.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotificationBtn;

  /// No description provided for @pleaseSelectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Please select an employee'**
  String get pleaseSelectEmployee;

  /// No description provided for @notificationSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Notification sent!'**
  String get notificationSentSuccess;

  /// No description provided for @reportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsTitle;

  /// No description provided for @generateReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReportTitle;

  /// No description provided for @selectReportTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select a report type to generate'**
  String get selectReportTypeHint;

  /// No description provided for @generatingReport.
  ///
  /// In en, this message translates to:
  /// **'Generating report...'**
  String get generatingReport;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get filterWeek;

  /// No description provided for @filterMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get filterMonth;

  /// No description provided for @filterYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get filterYear;

  /// No description provided for @reportEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get reportEmployees;

  /// No description provided for @reportAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get reportAttendance;

  /// No description provided for @reportLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get reportLeave;

  /// No description provided for @reportPayroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get reportPayroll;

  /// No description provided for @reportExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reportExpenses;

  /// No description provided for @reportAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get reportAssets;

  /// No description provided for @reportRecruitment.
  ///
  /// In en, this message translates to:
  /// **'Recruitment'**
  String get reportRecruitment;

  /// No description provided for @reportPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get reportPerformance;

  /// No description provided for @reportFoundRecords.
  ///
  /// In en, this message translates to:
  /// **'Found {total} records'**
  String reportFoundRecords(int total);

  /// No description provided for @reportLabelSuffix.
  ///
  /// In en, this message translates to:
  /// **'{label} Report'**
  String reportLabelSuffix(String label);

  /// No description provided for @exportReportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReportTooltip;

  /// No description provided for @noRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No records found for this period.'**
  String get noRecordsFound;

  /// No description provided for @reportExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Report exported successfully!'**
  String get reportExportSuccess;

  /// No description provided for @reportExportFailed.
  ///
  /// In en, this message translates to:
  /// **'❌ Export failed: {error}'**
  String reportExportFailed(String error);

  /// No description provided for @couldNotOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Could not open file: {message}'**
  String couldNotOpenFile(String message);

  /// No description provided for @holidaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidaysTitle;

  /// No description provided for @noHolidaysOnDay.
  ///
  /// In en, this message translates to:
  /// **'No holidays on this day'**
  String get noHolidaysOnDay;

  /// No description provided for @addHoliday.
  ///
  /// In en, this message translates to:
  /// **'Add Holiday'**
  String get addHoliday;

  /// No description provided for @editHoliday.
  ///
  /// In en, this message translates to:
  /// **'Edit Holiday'**
  String get editHoliday;

  /// No description provided for @holidayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get holidayNameLabel;

  /// No description provided for @holidayDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date *'**
  String get holidayDateLabel;

  /// No description provided for @holidayTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type *'**
  String get holidayTypeLabel;

  /// No description provided for @holidayTypeCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get holidayTypeCompany;

  /// No description provided for @holidayTypeNational.
  ///
  /// In en, this message translates to:
  /// **'National (Cambodia)'**
  String get holidayTypeNational;

  /// No description provided for @holidayDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get holidayDescriptionLabel;

  /// No description provided for @createHolidayBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Holiday'**
  String get createHolidayBtn;

  /// No description provided for @deleteHolidayTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Holiday?'**
  String get deleteHolidayTitle;

  /// No description provided for @deleteHolidayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete\n\"{name}\"?\n\nThis action cannot be undone.'**
  String deleteHolidayConfirm(String name);

  /// No description provided for @holidayDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Holiday deleted successfully'**
  String get holidayDeletedSuccess;

  /// No description provided for @pleaseFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get pleaseFillRequired;

  /// No description provided for @nationalBadge.
  ///
  /// In en, this message translates to:
  /// **'National'**
  String get nationalBadge;

  /// No description provided for @companyBadge.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get companyBadge;

  /// No description provided for @policiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get policiesTitle;

  /// No description provided for @searchPoliciesHint.
  ///
  /// In en, this message translates to:
  /// **'Search policies...'**
  String get searchPoliciesHint;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @statusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get statusArchived;

  /// No description provided for @allDepts.
  ///
  /// In en, this message translates to:
  /// **'All Depts'**
  String get allDepts;

  /// No description provided for @loadingPolicies.
  ///
  /// In en, this message translates to:
  /// **'Loading Policies...'**
  String get loadingPolicies;

  /// No description provided for @noPoliciesFound.
  ///
  /// In en, this message translates to:
  /// **'No policies found.'**
  String get noPoliciesFound;

  /// No description provided for @createPolicy.
  ///
  /// In en, this message translates to:
  /// **'Create Policy'**
  String get createPolicy;

  /// No description provided for @editPolicy.
  ///
  /// In en, this message translates to:
  /// **'Edit Policy'**
  String get editPolicy;

  /// No description provided for @policyTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get policyTitleLabel;

  /// No description provided for @departmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get departmentLabel;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version *'**
  String get versionLabel;

  /// No description provided for @effectiveDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Effective Date'**
  String get effectiveDateLabel;

  /// No description provided for @nextReviewDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Review Date (Optional)'**
  String get nextReviewDateLabel;

  /// No description provided for @contentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content *'**
  String get contentLabel;

  /// No description provided for @updatePolicyBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Policy'**
  String get updatePolicyBtn;

  /// No description provided for @createPolicyBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Policy'**
  String get createPolicyBtn;

  /// No description provided for @policyEffectivePrefix.
  ///
  /// In en, this message translates to:
  /// **'Effective: {date}'**
  String policyEffectivePrefix(String date);

  /// No description provided for @policyAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged: {ack}/{target}'**
  String policyAcknowledged(int ack, int target);

  /// No description provided for @viewBtn.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewBtn;

  /// No description provided for @publishBtn.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishBtn;

  /// No description provided for @archiveBtn.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveBtn;

  /// No description provided for @editBtn.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editBtn;

  /// No description provided for @deleteBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteBtn;

  /// No description provided for @deletePolicyConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deletePolicyConfirm(String title);

  /// No description provided for @resourceDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Resource Directory'**
  String get resourceDirectoryTitle;

  /// No description provided for @tabShifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get tabShifts;

  /// No description provided for @tabHolidays.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get tabHolidays;

  /// No description provided for @tabAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announce.'**
  String get tabAnnouncements;

  /// No description provided for @tabPolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get tabPolicies;

  /// No description provided for @tabDocs.
  ///
  /// In en, this message translates to:
  /// **'Docs'**
  String get tabDocs;

  /// No description provided for @noShifts.
  ///
  /// In en, this message translates to:
  /// **'No shifts'**
  String get noShifts;

  /// No description provided for @noHolidays.
  ///
  /// In en, this message translates to:
  /// **'No holidays'**
  String get noHolidays;

  /// No description provided for @noAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'No announcements'**
  String get noAnnouncements;

  /// No description provided for @noPolicies.
  ///
  /// In en, this message translates to:
  /// **'No policies'**
  String get noPolicies;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get noDocuments;

  /// No description provided for @addShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Shift'**
  String get addShiftTitle;

  /// No description provided for @shiftNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get shiftNameLabel;

  /// No description provided for @shiftNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Morning Shift'**
  String get shiftNameHint;

  /// No description provided for @assignShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Shift'**
  String get assignShiftTitle;

  /// No description provided for @employeeIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeIdLabel;

  /// No description provided for @assignBtn.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assignBtn;

  /// No description provided for @shiftAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Shift assigned'**
  String get shiftAssignedSuccess;

  /// No description provided for @holidayCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Holiday created'**
  String get holidayCreatedSuccess;

  /// No description provided for @deletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Deleted'**
  String get deletedSuccess;

  /// No description provided for @documentDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Document deleted'**
  String get documentDeletedSuccess;

  /// No description provided for @publishedStatus.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get publishedStatus;

  /// No description provided for @addHolidayTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Holiday'**
  String get addHolidayTitle;

  /// No description provided for @recurringBadge.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringBadge;

  /// No description provided for @fileSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size: {size} KB'**
  String fileSizeLabel(String size);

  /// No description provided for @deleteShiftConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete shift \"{name}\"?'**
  String deleteShiftConfirm(String name);

  /// No description provided for @deleteHolidayConfirmSimple.
  ///
  /// In en, this message translates to:
  /// **'Delete holiday \"{name}\"?'**
  String deleteHolidayConfirmSimple(String name);

  /// No description provided for @deleteDocumentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete document \"{title}\"?'**
  String deleteDocumentConfirm(String title);

  /// No description provided for @expenseClaimsTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Claims'**
  String get expenseClaimsTitle;

  /// No description provided for @newClaimTooltip.
  ///
  /// In en, this message translates to:
  /// **'New Claim'**
  String get newClaimTooltip;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @filterPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get filterPaid;

  /// No description provided for @expenseApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Expense approved'**
  String get expenseApprovedSuccess;

  /// No description provided for @expenseMarkedPaidSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Expense marked as paid'**
  String get expenseMarkedPaidSuccess;

  /// No description provided for @deleteClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Claim'**
  String get deleteClaimTitle;

  /// No description provided for @deleteExpenseClaimConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense claim permanently?'**
  String get deleteExpenseClaimConfirm;

  /// No description provided for @claimDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Claim deleted'**
  String get claimDeletedSuccess;

  /// No description provided for @rejectClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject Claim'**
  String get rejectClaimTitle;

  /// No description provided for @rejectClaimPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejecting this claim:'**
  String get rejectClaimPrompt;

  /// No description provided for @rejectionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason *'**
  String get rejectionReasonLabel;

  /// No description provided for @rejectionReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Invalid receipt, duplicate claim'**
  String get rejectionReasonHint;

  /// No description provided for @rejectionReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason is required'**
  String get rejectionReasonRequired;

  /// No description provided for @rejectBtn.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectBtn;

  /// No description provided for @expenseRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Expense rejected'**
  String get expenseRejectedSuccess;

  /// No description provided for @reasonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reason: '**
  String get reasonPrefix;

  /// No description provided for @paidPrefix.
  ///
  /// In en, this message translates to:
  /// **'Paid: '**
  String get paidPrefix;

  /// No description provided for @markAsPaidBtn.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaidBtn;

  /// No description provided for @expenseDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense Claim Details'**
  String get expenseDetailTitle;

  /// No description provided for @employeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employeeLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @expenseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense Date'**
  String get expenseDateLabel;

  /// No description provided for @statusPrefix.
  ///
  /// In en, this message translates to:
  /// **'Status: '**
  String get statusPrefix;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @paidAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid At'**
  String get paidAtLabel;

  /// No description provided for @receiptLabel.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptLabel;

  /// No description provided for @editExpenseClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense Claim'**
  String get editExpenseClaimTitle;

  /// No description provided for @newExpenseClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'New Expense Claim'**
  String get newExpenseClaimTitle;

  /// No description provided for @titleFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleFieldLabel;

  /// No description provided for @categoryFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get categoryFieldLabel;

  /// No description provided for @catTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get catTravel;

  /// No description provided for @catMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get catMeals;

  /// No description provided for @catSupplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get catSupplies;

  /// No description provided for @catSoftware.
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get catSoftware;

  /// No description provided for @catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransport;

  /// No description provided for @catAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get catAccommodation;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @amountFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount *'**
  String get amountFieldLabel;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @updateClaimBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Claim'**
  String get updateClaimBtn;

  /// No description provided for @submitClaimBtn.
  ///
  /// In en, this message translates to:
  /// **'Submit Claim'**
  String get submitClaimBtn;

  /// No description provided for @expenseClaimUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Expense claim updated'**
  String get expenseClaimUpdatedSuccess;

  /// No description provided for @expenseClaimSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Expense claim submitted'**
  String get expenseClaimSubmittedSuccess;

  /// No description provided for @performanceTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance & Training'**
  String get performanceTrainingTitle;

  /// No description provided for @tabReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get tabReviews;

  /// No description provided for @tabTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get tabTraining;

  /// No description provided for @createReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Review'**
  String get createReviewTitle;

  /// No description provided for @editReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Review'**
  String get editReviewTitle;

  /// No description provided for @reviewerRequired.
  ///
  /// In en, this message translates to:
  /// **'Reviewer *'**
  String get reviewerRequired;

  /// No description provided for @periodRequired.
  ///
  /// In en, this message translates to:
  /// **'Period *'**
  String get periodRequired;

  /// No description provided for @periodStartRequired.
  ///
  /// In en, this message translates to:
  /// **'Period Start *'**
  String get periodStartRequired;

  /// No description provided for @periodEndRequired.
  ///
  /// In en, this message translates to:
  /// **'Period End *'**
  String get periodEndRequired;

  /// No description provided for @reviewDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Review Date *'**
  String get reviewDateRequired;

  /// No description provided for @reviewTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Review Type *'**
  String get reviewTypeRequired;

  /// No description provided for @reviewTypeManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get reviewTypeManager;

  /// No description provided for @reviewTypeSelf.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get reviewTypeSelf;

  /// No description provided for @reviewTypePeer.
  ///
  /// In en, this message translates to:
  /// **'Peer'**
  String get reviewTypePeer;

  /// No description provided for @reviewType360.
  ///
  /// In en, this message translates to:
  /// **'360 Review'**
  String get reviewType360;

  /// No description provided for @strengthsOptional.
  ///
  /// In en, this message translates to:
  /// **'Strengths (optional)'**
  String get strengthsOptional;

  /// No description provided for @areasForImprovementOptional.
  ///
  /// In en, this message translates to:
  /// **'Areas for Improvement (optional)'**
  String get areasForImprovementOptional;

  /// No description provided for @goalsOptional.
  ///
  /// In en, this message translates to:
  /// **'Goals (optional)'**
  String get goalsOptional;

  /// No description provided for @commentsOptional.
  ///
  /// In en, this message translates to:
  /// **'Comments (optional)'**
  String get commentsOptional;

  /// No description provided for @statusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statusSubmitted;

  /// No description provided for @statusAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get statusAcknowledged;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @overallRatingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Overall Rating: '**
  String get overallRatingPrefix;

  /// No description provided for @periodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Q1 2024'**
  String get periodHint;

  /// No description provided for @deleteReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Review'**
  String get deleteReviewTitle;

  /// No description provided for @deleteReviewConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this performance review?'**
  String get deleteReviewConfirm;

  /// No description provided for @reviewSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Review saved successfully'**
  String get reviewSavedSuccess;

  /// No description provided for @reviewDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Review deleted'**
  String get reviewDeletedSuccess;

  /// No description provided for @trainingMarkedCompletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Training marked as completed'**
  String get trainingMarkedCompletedSuccess;

  /// No description provided for @allPeriods.
  ///
  /// In en, this message translates to:
  /// **'All Periods'**
  String get allPeriods;

  /// No description provided for @noReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews found.'**
  String get noReviews;

  /// No description provided for @notRated.
  ///
  /// In en, this message translates to:
  /// **'Not Rated'**
  String get notRated;

  /// No description provided for @loadingReviews.
  ///
  /// In en, this message translates to:
  /// **'Loading Reviews...'**
  String get loadingReviews;

  /// No description provided for @createTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Training'**
  String get createTrainingTitle;

  /// No description provided for @editTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Training'**
  String get editTrainingTitle;

  /// No description provided for @replaceCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to replace cover image'**
  String get replaceCoverImage;

  /// No description provided for @uploadCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload cover image'**
  String get uploadCoverImage;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get levelLabel;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @statusOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get statusOngoing;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'Duration (Hours)'**
  String get durationHours;

  /// No description provided for @maxCapacity.
  ///
  /// In en, this message translates to:
  /// **'Max Capacity'**
  String get maxCapacity;

  /// No description provided for @instructorName.
  ///
  /// In en, this message translates to:
  /// **'Instructor Name'**
  String get instructorName;

  /// No description provided for @locationLink.
  ///
  /// In en, this message translates to:
  /// **'Location / Link'**
  String get locationLink;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDateLabel;

  /// No description provided for @trainingDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get trainingDescription;

  /// No description provided for @trainingContent.
  ///
  /// In en, this message translates to:
  /// **'Content / Syllabus'**
  String get trainingContent;

  /// No description provided for @trainingNotes.
  ///
  /// In en, this message translates to:
  /// **'Internal Notes'**
  String get trainingNotes;

  /// No description provided for @loadingTrainings.
  ///
  /// In en, this message translates to:
  /// **'Loading Trainings...'**
  String get loadingTrainings;

  /// No description provided for @noTrainings.
  ///
  /// In en, this message translates to:
  /// **'No trainings found.'**
  String get noTrainings;

  /// No description provided for @deleteTrainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Training'**
  String get deleteTrainingTitle;

  /// No description provided for @deleteTrainingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this training course?'**
  String get deleteTrainingConfirm;

  /// No description provided for @trainingSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Training saved successfully'**
  String get trainingSavedSuccess;

  /// No description provided for @trainingDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Training deleted'**
  String get trainingDeletedSuccess;

  /// No description provided for @searchTrainingsHint.
  ///
  /// In en, this message translates to:
  /// **'Search trainings...'**
  String get searchTrainingsHint;

  /// No description provided for @enrollmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrollments'**
  String get enrollmentsTitle;

  /// No description provided for @selectEmployeeToEnroll.
  ///
  /// In en, this message translates to:
  /// **'Select Employee to Enroll'**
  String get selectEmployeeToEnroll;

  /// No description provided for @enrollBtn.
  ///
  /// In en, this message translates to:
  /// **'Enroll'**
  String get enrollBtn;

  /// No description provided for @employeeEnrolledSuccess.
  ///
  /// In en, this message translates to:
  /// **'🎉 Employee enrolled successfully & notification sent!'**
  String get employeeEnrolledSuccess;

  /// No description provided for @enrolledParticipantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Participants'**
  String get enrolledParticipantsTitle;

  /// No description provided for @noEmployeesEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No employees enrolled yet.'**
  String get noEmployeesEnrolled;

  /// No description provided for @progressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressLabel;

  /// No description provided for @noJobPostings.
  ///
  /// In en, this message translates to:
  /// **'No job postings'**
  String get noJobPostings;

  /// No description provided for @loadingJobs.
  ///
  /// In en, this message translates to:
  /// **'Loading jobs...'**
  String get loadingJobs;

  /// No description provided for @candidatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get candidatesTitle;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied.'**
  String get locationPermissionPermDenied;

  /// No description provided for @locationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated'**
  String get locationUpdated;

  /// No description provided for @couldNotFetchLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch location'**
  String get couldNotFetchLocation;

  /// No description provided for @createJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Job Posting'**
  String get createJobTitle;

  /// No description provided for @editJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Job Posting'**
  String get editJobTitle;

  /// No description provided for @basicInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformationTitle;

  /// No description provided for @jobTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Job Title *'**
  String get jobTitleRequired;

  /// No description provided for @positionLabel.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get positionLabel;

  /// No description provided for @employmentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Employment Type'**
  String get employmentTypeLabel;

  /// No description provided for @employmentFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full Time'**
  String get employmentFullTime;

  /// No description provided for @employmentPartTime.
  ///
  /// In en, this message translates to:
  /// **'Part Time'**
  String get employmentPartTime;

  /// No description provided for @employmentContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get employmentContract;

  /// No description provided for @employmentInternship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get employmentInternship;

  /// No description provided for @jobDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetailsTitle;

  /// No description provided for @descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get descriptionRequired;

  /// No description provided for @requirementsLabel.
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirementsLabel;

  /// No description provided for @responsibilitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Responsibilities'**
  String get responsibilitiesLabel;

  /// No description provided for @locationAndSalaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Location & Salary'**
  String get locationAndSalaryTitle;

  /// No description provided for @minSalary.
  ///
  /// In en, this message translates to:
  /// **'Min Salary'**
  String get minSalary;

  /// No description provided for @maxSalary.
  ///
  /// In en, this message translates to:
  /// **'Max Salary'**
  String get maxSalary;

  /// No description provided for @jobStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Status'**
  String get jobStatusLabel;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @statusFilled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get statusFilled;

  /// No description provided for @titleAndDescRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and description required'**
  String get titleAndDescRequired;

  /// No description provided for @publishJobPosting.
  ///
  /// In en, this message translates to:
  /// **'Publish Job Posting'**
  String get publishJobPosting;

  /// No description provided for @updateJobPosting.
  ///
  /// In en, this message translates to:
  /// **'Update Job Posting'**
  String get updateJobPosting;

  /// No description provided for @noCandidatesApplied.
  ///
  /// In en, this message translates to:
  /// **'No candidates applied yet.'**
  String get noCandidatesApplied;

  /// No description provided for @loadingCandidates.
  ///
  /// In en, this message translates to:
  /// **'Loading candidates...'**
  String get loadingCandidates;

  /// No description provided for @yearsExp.
  ///
  /// In en, this message translates to:
  /// **'yrs exp'**
  String get yearsExp;

  /// No description provided for @expectedSalaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Exp'**
  String get expectedSalaryLabel;

  /// No description provided for @viewResumeBtn.
  ///
  /// In en, this message translates to:
  /// **'View Resume'**
  String get viewResumeBtn;

  /// No description provided for @stageLabel.
  ///
  /// In en, this message translates to:
  /// **'Stage'**
  String get stageLabel;

  /// No description provided for @stageApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get stageApplied;

  /// No description provided for @stageScreening.
  ///
  /// In en, this message translates to:
  /// **'Screening'**
  String get stageScreening;

  /// No description provided for @stageInterview.
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get stageInterview;

  /// No description provided for @stageOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get stageOffer;

  /// No description provided for @stageHired.
  ///
  /// In en, this message translates to:
  /// **'Hired'**
  String get stageHired;

  /// No description provided for @stageRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get stageRejected;

  /// No description provided for @companyAssetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Company Assets'**
  String get companyAssetsTitle;

  /// No description provided for @noAssetsFound.
  ///
  /// In en, this message translates to:
  /// **'No assets found'**
  String get noAssetsFound;

  /// No description provided for @addFirstAssetDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first company asset to get started'**
  String get addFirstAssetDesc;

  /// No description provided for @addAssetBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get addAssetBtn;

  /// No description provided for @editAssetTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Asset'**
  String get editAssetTitle;

  /// No description provided for @addNewAssetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Asset'**
  String get addNewAssetTitle;

  /// No description provided for @fillInDetailsDesc.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below'**
  String get fillInDetailsDesc;

  /// No description provided for @basicDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Details'**
  String get basicDetailsTitle;

  /// No description provided for @assetCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Asset Code *'**
  String get assetCodeRequired;

  /// No description provided for @conditionLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get conditionLabel;

  /// No description provided for @conditionNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get conditionNew;

  /// No description provided for @conditionGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get conditionGood;

  /// No description provided for @conditionFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get conditionFair;

  /// No description provided for @conditionPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get conditionPoor;

  /// No description provided for @conditionDamaged.
  ///
  /// In en, this message translates to:
  /// **'Damaged'**
  String get conditionDamaged;

  /// No description provided for @financialDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial Details'**
  String get financialDetailsTitle;

  /// No description provided for @purchasePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get purchasePriceLabel;

  /// No description provided for @currentValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Value'**
  String get currentValueLabel;

  /// No description provided for @depreciationMonthsLabel.
  ///
  /// In en, this message translates to:
  /// **'Depreciation (Months)'**
  String get depreciationMonthsLabel;

  /// No description provided for @purchaseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get purchaseDateLabel;

  /// No description provided for @warrantyExpiryLabel.
  ///
  /// In en, this message translates to:
  /// **'Warranty Expiry'**
  String get warrantyExpiryLabel;

  /// No description provided for @additionalNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotesTitle;

  /// No description provided for @assetCodeAndNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Asset Code and Name are required'**
  String get assetCodeAndNameRequired;

  /// No description provided for @assetUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Asset updated successfully'**
  String get assetUpdatedSuccess;

  /// No description provided for @assetCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Asset created successfully'**
  String get assetCreatedSuccess;

  /// No description provided for @createAssetBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Asset'**
  String get createAssetBtn;

  /// No description provided for @assignAssetTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Asset'**
  String get assignAssetTitle;

  /// No description provided for @transferAssetDesc.
  ///
  /// In en, this message translates to:
  /// **'Transfer asset to an employee'**
  String get transferAssetDesc;

  /// No description provided for @assignToEmployeeRequired.
  ///
  /// In en, this message translates to:
  /// **'Assign To Employee *'**
  String get assignToEmployeeRequired;

  /// No description provided for @conditionAtAssignmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Condition at Assignment'**
  String get conditionAtAssignmentLabel;

  /// No description provided for @conditionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note any scratches or damage...'**
  String get conditionNoteHint;

  /// No description provided for @assetAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Asset assigned successfully'**
  String get assetAssignedSuccess;

  /// No description provided for @confirmAssignmentBtn.
  ///
  /// In en, this message translates to:
  /// **'Confirm Assignment'**
  String get confirmAssignmentBtn;

  /// No description provided for @deleteAssetTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Asset'**
  String get deleteAssetTitle;

  /// No description provided for @deleteAssetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" ({code})?'**
  String deleteAssetConfirm(String name, String code);

  /// No description provided for @returnAssetTitle.
  ///
  /// In en, this message translates to:
  /// **'Return Asset'**
  String get returnAssetTitle;

  /// No description provided for @returnAssetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Mark \"{name}\" as returned?'**
  String returnAssetConfirm(String name);

  /// No description provided for @assetReturnedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Asset returned'**
  String get assetReturnedSuccess;

  /// No description provided for @assetDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Asset deleted'**
  String get assetDeletedSuccess;

  /// No description provided for @totalAssetsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get totalAssetsLabel;

  /// No description provided for @totalValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValueLabel;

  /// No description provided for @assignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assignedLabel;

  /// No description provided for @valueLabel.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get valueLabel;

  /// No description provided for @assignedToLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned to: {name}'**
  String assignedToLabel(String name);

  /// No description provided for @warrantyExpired.
  ///
  /// In en, this message translates to:
  /// **'Warranty Expired'**
  String get warrantyExpired;

  /// No description provided for @warrantyExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Warranty Expiring Soon'**
  String get warrantyExpiringSoon;

  /// No description provided for @returnBtn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get returnBtn;

  /// No description provided for @assignmentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignment History'**
  String get assignmentHistoryTitle;

  /// No description provided for @noAssignmentHistory.
  ///
  /// In en, this message translates to:
  /// **'No assignment history'**
  String get noAssignmentHistory;

  /// No description provided for @noAssignmentHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'This asset has never been assigned to anyone.'**
  String get noAssignmentHistoryDesc;

  /// No description provided for @assignedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {date}'**
  String assignedDateLabel(String date);

  /// No description provided for @returnedDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Returned: {date}'**
  String returnedDateLabel(String date);

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String notesLabel(String notes);

  /// No description provided for @hrStructureTitle.
  ///
  /// In en, this message translates to:
  /// **'HR Structure'**
  String get hrStructureTitle;

  /// No description provided for @tabBranches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get tabBranches;

  /// No description provided for @tabDepts.
  ///
  /// In en, this message translates to:
  /// **'Depts'**
  String get tabDepts;

  /// No description provided for @tabPositions.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get tabPositions;

  /// No description provided for @tabTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get tabTeams;

  /// No description provided for @tabOrgChart.
  ///
  /// In en, this message translates to:
  /// **'Org Chart'**
  String get tabOrgChart;

  /// No description provided for @searchBranchesHint.
  ///
  /// In en, this message translates to:
  /// **'Search branches...'**
  String get searchBranchesHint;

  /// No description provided for @loadingBranches.
  ///
  /// In en, this message translates to:
  /// **'Loading branches...'**
  String get loadingBranches;

  /// No description provided for @failedToLoadBranches.
  ///
  /// In en, this message translates to:
  /// **'Failed to load branches'**
  String get failedToLoadBranches;

  /// No description provided for @noBranchesFound.
  ///
  /// In en, this message translates to:
  /// **'No branches found matching your search.'**
  String get noBranchesFound;

  /// No description provided for @noBranchesFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search query.'**
  String get noBranchesFoundDesc;

  /// No description provided for @noBranchesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No branches available'**
  String get noBranchesAvailable;

  /// No description provided for @addFirstBranchDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first branch to get started'**
  String get addFirstBranchDesc;

  /// No description provided for @addBranchBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Branch'**
  String get addBranchBtn;

  /// No description provided for @deleteBranchTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Branch'**
  String get deleteBranchTitle;

  /// No description provided for @deleteBranchConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteBranchConfirm(String name);

  /// No description provided for @searchDeptsHint.
  ///
  /// In en, this message translates to:
  /// **'Search depts...'**
  String get searchDeptsHint;

  /// No description provided for @loadingDepts.
  ///
  /// In en, this message translates to:
  /// **'Loading departments...'**
  String get loadingDepts;

  /// No description provided for @errorLoadingDepts.
  ///
  /// In en, this message translates to:
  /// **'Error loading depts: {error}'**
  String errorLoadingDepts(String error);

  /// No description provided for @noDeptsFound.
  ///
  /// In en, this message translates to:
  /// **'No departments found'**
  String get noDeptsFound;

  /// No description provided for @failedToLoadDepts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load departments'**
  String get failedToLoadDepts;

  /// No description provided for @addFirstDeptDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first department to get started'**
  String get addFirstDeptDesc;

  /// No description provided for @addDeptBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Department'**
  String get addDeptBtn;

  /// No description provided for @deleteDeptTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Department'**
  String get deleteDeptTitle;

  /// No description provided for @deleteDeptConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete department {name}?'**
  String deleteDeptConfirm(String name);

  /// No description provided for @searchRolesHint.
  ///
  /// In en, this message translates to:
  /// **'Search roles...'**
  String get searchRolesHint;

  /// No description provided for @noRolesFound.
  ///
  /// In en, this message translates to:
  /// **'No roles found'**
  String get noRolesFound;

  /// No description provided for @failedToLoadPositions.
  ///
  /// In en, this message translates to:
  /// **'Failed to load positions'**
  String get failedToLoadPositions;

  /// No description provided for @addFirstRoleDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first role to get started'**
  String get addFirstRoleDesc;

  /// No description provided for @addRoleBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Role'**
  String get addRoleBtn;

  /// No description provided for @searchTeamsHint.
  ///
  /// In en, this message translates to:
  /// **'Search teams...'**
  String get searchTeamsHint;

  /// No description provided for @loadingTeams.
  ///
  /// In en, this message translates to:
  /// **'Loading teams...'**
  String get loadingTeams;

  /// No description provided for @noTeamsFound.
  ///
  /// In en, this message translates to:
  /// **'No teams found'**
  String get noTeamsFound;

  /// No description provided for @failedToLoadTeams.
  ///
  /// In en, this message translates to:
  /// **'Failed to load teams'**
  String get failedToLoadTeams;

  /// No description provided for @addFirstTeamDesc.
  ///
  /// In en, this message translates to:
  /// **'Add your first team to get started'**
  String get addFirstTeamDesc;

  /// No description provided for @addTeamBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Team'**
  String get addTeamBtn;

  /// No description provided for @deleteTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Team'**
  String get deleteTeamTitle;

  /// No description provided for @deleteTeamConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete team {name}?'**
  String deleteTeamConfirm(String name);

  /// No description provided for @searchOrgChartHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, position, dept...'**
  String get searchOrgChartHint;

  /// No description provided for @loadingOrgChart.
  ///
  /// In en, this message translates to:
  /// **'Loading org chart...'**
  String get loadingOrgChart;

  /// No description provided for @failedToLoadOrgChart.
  ///
  /// In en, this message translates to:
  /// **'Failed to load org chart'**
  String get failedToLoadOrgChart;

  /// No description provided for @noDataOrgChart.
  ///
  /// In en, this message translates to:
  /// **'No org chart data'**
  String get noDataOrgChart;

  /// No description provided for @noOrgChartTitle.
  ///
  /// In en, this message translates to:
  /// **'No organisation structure yet'**
  String get noOrgChartTitle;

  /// No description provided for @noOrgChartDesc.
  ///
  /// In en, this message translates to:
  /// **'Add employees and assign managers to build your org chart.'**
  String get noOrgChartDesc;

  /// No description provided for @orgChartStats.
  ///
  /// In en, this message translates to:
  /// **'{count} people · {levels} levels'**
  String orgChartStats(int count, int levels);

  /// No description provided for @expandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand All'**
  String get expandAll;

  /// No description provided for @showLevel1.
  ///
  /// In en, this message translates to:
  /// **'Show 1 Level'**
  String get showLevel1;

  /// No description provided for @showLevel2.
  ///
  /// In en, this message translates to:
  /// **'Show 2 Levels'**
  String get showLevel2;

  /// No description provided for @showLevel3.
  ///
  /// In en, this message translates to:
  /// **'Show 3 Levels'**
  String get showLevel3;

  /// No description provided for @showLevel4.
  ///
  /// In en, this message translates to:
  /// **'Show 4 Levels'**
  String get showLevel4;

  /// No description provided for @showLevel5.
  ///
  /// In en, this message translates to:
  /// **'Show 5 Levels'**
  String get showLevel5;

  /// No description provided for @branchNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch Name'**
  String get branchNameLabel;

  /// No description provided for @branchCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch Code'**
  String get branchCodeLabel;

  /// No description provided for @branchManagerLabel.
  ///
  /// In en, this message translates to:
  /// **'Branch Manager'**
  String get branchManagerLabel;

  /// No description provided for @latitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitudeLabel;

  /// No description provided for @longitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitudeLabel;

  /// No description provided for @allowedRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowed Radius (meters)'**
  String get allowedRadiusLabel;

  /// No description provided for @getCurrentLocationBtn.
  ///
  /// In en, this message translates to:
  /// **'Get Current Location'**
  String get getCurrentLocationBtn;

  /// No description provided for @customPayrollSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Payroll Settings'**
  String get customPayrollSettingsTitle;

  /// No description provided for @customPayrollSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Override company-wide overtime and late rules'**
  String get customPayrollSettingsDesc;

  /// No description provided for @workingDaysCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'Working Days Calculation'**
  String get workingDaysCalcTitle;

  /// No description provided for @calcTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculation Type'**
  String get calcTypeLabel;

  /// No description provided for @fixedDaysPerMonthLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed Days per Month'**
  String get fixedDaysPerMonthLabel;

  /// No description provided for @overtimeMultipliersTitle.
  ///
  /// In en, this message translates to:
  /// **'Overtime Multipliers'**
  String get overtimeMultipliersTitle;

  /// No description provided for @regularOtLabel.
  ///
  /// In en, this message translates to:
  /// **'Regular OT'**
  String get regularOtLabel;

  /// No description provided for @restDayOtLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest Day OT'**
  String get restDayOtLabel;

  /// No description provided for @publicHolOtLabel.
  ///
  /// In en, this message translates to:
  /// **'Public Hol. OT'**
  String get publicHolOtLabel;

  /// No description provided for @companyHolOtLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Hol. OT'**
  String get companyHolOtLabel;

  /// No description provided for @latePenaltiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Late Penalties'**
  String get latePenaltiesTitle;

  /// No description provided for @graceMinsLabel.
  ///
  /// In en, this message translates to:
  /// **'Grace Mins'**
  String get graceMinsLabel;

  /// No description provided for @dedRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Ded. Rate'**
  String get dedRateLabel;

  /// No description provided for @dedTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Deduction Type'**
  String get dedTypeLabel;

  /// No description provided for @perMinuteLabel.
  ///
  /// In en, this message translates to:
  /// **'Per Minute'**
  String get perMinuteLabel;

  /// No description provided for @fixedAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed Amount'**
  String get fixedAmountLabel;

  /// No description provided for @ignorePolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Ignore (No extra pay)'**
  String get ignorePolicyLabel;

  /// No description provided for @treatAsOtPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Treat as OT'**
  String get treatAsOtPolicyLabel;

  /// No description provided for @paidOutsidePolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid Outside (No OT multiplier)'**
  String get paidOutsidePolicyLabel;

  /// No description provided for @preShiftOtMultLabel.
  ///
  /// In en, this message translates to:
  /// **'Pre-Shift OT Mult.'**
  String get preShiftOtMultLabel;

  /// No description provided for @maxMinsAllowedLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Mins Allowed'**
  String get maxMinsAllowedLabel;

  /// No description provided for @overrideGracePeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Override Grace Period (minutes)'**
  String get overrideGracePeriodLabel;

  /// No description provided for @deptNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Department Name'**
  String get deptNameLabel;

  /// No description provided for @deptCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Department Code'**
  String get deptCodeLabel;

  /// No description provided for @officeBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'Office Branch'**
  String get officeBranchLabel;

  /// No description provided for @noBranchLabel.
  ///
  /// In en, this message translates to:
  /// **'No Branch'**
  String get noBranchLabel;

  /// No description provided for @parentDeptLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent Department'**
  String get parentDeptLabel;

  /// No description provided for @noParentLabel.
  ///
  /// In en, this message translates to:
  /// **'No Parent (Root)'**
  String get noParentLabel;

  /// No description provided for @deptManagerLabel.
  ///
  /// In en, this message translates to:
  /// **'Department Manager'**
  String get deptManagerLabel;

  /// No description provided for @noManagerLabel.
  ///
  /// In en, this message translates to:
  /// **'No Manager'**
  String get noManagerLabel;

  /// No description provided for @roleTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role Title'**
  String get roleTitleLabel;

  /// No description provided for @roleCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Role Code'**
  String get roleCodeLabel;

  /// No description provided for @noDeptLabel.
  ///
  /// In en, this message translates to:
  /// **'No Department (General)'**
  String get noDeptLabel;

  /// No description provided for @jobSeniorityLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Job Seniority Level'**
  String get jobSeniorityLevelLabel;

  /// No description provided for @noLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'No Level specified'**
  String get noLevelLabel;

  /// No description provided for @teamNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Team Name'**
  String get teamNameLabel;

  /// No description provided for @teamLeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Team Leader'**
  String get teamLeaderLabel;

  /// No description provided for @noLeaderLabel.
  ///
  /// In en, this message translates to:
  /// **'No Leader Assigned'**
  String get noLeaderLabel;

  /// No description provided for @activeStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Status'**
  String get activeStatusTitle;

  /// No description provided for @allowAssignRolesDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow assigning employees to this role'**
  String get allowAssignRolesDesc;

  /// No description provided for @allowAssignTeamsDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow assigning employees to this team'**
  String get allowAssignTeamsDesc;

  /// No description provided for @allDepartmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'All Departments'**
  String get allDepartmentsLabel;

  /// No description provided for @allDeptsLabel.
  ///
  /// In en, this message translates to:
  /// **'All Depts'**
  String get allDeptsLabel;

  /// No description provided for @allBranchesLabel.
  ///
  /// In en, this message translates to:
  /// **'All Branches'**
  String get allBranchesLabel;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @unpublishBtn.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublishBtn;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTitle;

  /// No description provided for @announcementPublished.
  ///
  /// In en, this message translates to:
  /// **'✅ Announcement published'**
  String get announcementPublished;

  /// No description provided for @announcementUnpublished.
  ///
  /// In en, this message translates to:
  /// **'✅ Announcement unpublished'**
  String get announcementUnpublished;

  /// No description provided for @operationSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Operation successful'**
  String get operationSuccess;

  /// No description provided for @myShift.
  ///
  /// In en, this message translates to:
  /// **'My Shift'**
  String get myShift;

  /// No description provided for @recentPayslip.
  ///
  /// In en, this message translates to:
  /// **'Recent Payslip'**
  String get recentPayslip;

  /// No description provided for @pendingExpenses.
  ///
  /// In en, this message translates to:
  /// **'Pending Expenses'**
  String get pendingExpenses;

  /// No description provided for @noUpcomingLeaves.
  ///
  /// In en, this message translates to:
  /// **'No upcoming leaves approved.'**
  String get noUpcomingLeaves;

  /// No description provided for @noRecentAttendance.
  ///
  /// In en, this message translates to:
  /// **'No recent attendance records.'**
  String get noRecentAttendance;

  /// No description provided for @myLearning.
  ///
  /// In en, this message translates to:
  /// **'My Learning'**
  String get myLearning;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @companyRules.
  ///
  /// In en, this message translates to:
  /// **'Company Rules'**
  String get companyRules;

  /// No description provided for @companyRulesDesc.
  ///
  /// In en, this message translates to:
  /// **'A transparent guide to your branch\'s configured payroll, attendance, and overtime rules.'**
  String get companyRulesDesc;

  /// No description provided for @viewingRulesFor.
  ///
  /// In en, this message translates to:
  /// **'Viewing rules for'**
  String get viewingRulesFor;

  /// No description provided for @noCompanyRules.
  ///
  /// In en, this message translates to:
  /// **'No company rules configured.'**
  String get noCompanyRules;

  /// No description provided for @viewCompanyDocuments.
  ///
  /// In en, this message translates to:
  /// **'Access company guidelines and forms'**
  String get viewCompanyDocuments;

  /// No description provided for @readAndAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Read and acknowledge policies'**
  String get readAndAcknowledge;

  /// No description provided for @payrollAttendanceRules.
  ///
  /// In en, this message translates to:
  /// **'Payroll, attendance & OT rules'**
  String get payrollAttendanceRules;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @companyServices.
  ///
  /// In en, this message translates to:
  /// **'Company Services'**
  String get companyServices;

  /// No description provided for @moveCloserToBranch.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the branch to clock in.'**
  String get moveCloserToBranch;

  /// No description provided for @locationNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Location needs attention'**
  String get locationNeedsAttention;

  /// No description provided for @noPayslipsYet.
  ///
  /// In en, this message translates to:
  /// **'No payslips yet'**
  String get noPayslipsYet;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @themeAndAppearance.
  ///
  /// In en, this message translates to:
  /// **'Theme & Appearance'**
  String get themeAndAppearance;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dark, light or system theme'**
  String get themeSubtitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'English • ខ្មែរ'**
  String get languageSubtitle;

  /// No description provided for @accountAndInfo.
  ///
  /// In en, this message translates to:
  /// **'Account & Info'**
  String get accountAndInfo;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get accountActions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review how we protect and process your data'**
  String get privacyPolicySubtitle;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account and personal data'**
  String get deleteAccountSubtitle;

  /// No description provided for @signOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out from this device'**
  String get signOutSubtitle;

  /// No description provided for @returnToAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to HR Admin dashboard'**
  String get returnToAdminSubtitle;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your contact and bank details'**
  String get editProfileSubtitle;

  /// No description provided for @companyServicesAndTools.
  ///
  /// In en, this message translates to:
  /// **'Company Services & Tools'**
  String get companyServicesAndTools;

  /// No description provided for @featuresCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Features'**
  String featuresCount(int count);

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @lightThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Crisp clean interface with high contrast'**
  String get lightThemeDesc;

  /// No description provided for @darkThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Deep dark interface, easier on the eyes in low light'**
  String get darkThemeDesc;

  /// No description provided for @systemThemeDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically matches your device display mode'**
  String get systemThemeDesc;

  /// No description provided for @englishDesc.
  ///
  /// In en, this message translates to:
  /// **'Default language for international operations'**
  String get englishDesc;

  /// No description provided for @khmerDesc.
  ///
  /// In en, this message translates to:
  /// **'ភាសាជាតិកម្ពុជា'**
  String get khmerDesc;

  /// No description provided for @attendkhAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0 • Production Release'**
  String get attendkhAppVersion;

  /// No description provided for @filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// No description provided for @filterAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get filterAttendance;

  /// No description provided for @filterAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get filterAnnouncements;

  /// No description provided for @filterPolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get filterPolicies;

  /// No description provided for @filterRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get filterRequests;

  /// No description provided for @filterRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get filterRead;

  /// No description provided for @timelineToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get timelineToday;

  /// No description provided for @timelineYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get timelineYesterday;

  /// No description provided for @timelineThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get timelineThisWeek;

  /// No description provided for @timelineEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get timelineEarlier;

  /// No description provided for @searchNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Search notifications by title or message...'**
  String get searchNotificationsHint;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @markAsUnread.
  ///
  /// In en, this message translates to:
  /// **'Mark as Unread'**
  String get markAsUnread;

  /// No description provided for @noMatchingNotifications.
  ///
  /// In en, this message translates to:
  /// **'No matching notifications'**
  String get noMatchingNotifications;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get allCaughtUp;

  /// No description provided for @noFilterNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications in this filter'**
  String get noFilterNotifications;

  /// No description provided for @searchSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Try searching with different keywords or clearing your query.'**
  String get searchSuggestions;

  /// No description provided for @checkOtherTabs.
  ///
  /// In en, this message translates to:
  /// **'Check other tabs or swipe down to refresh for new updates.'**
  String get checkOtherTabs;

  /// No description provided for @emptyNotificationsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Company announcements, policy updates, and attendance alerts will appear here.'**
  String get emptyNotificationsPrompt;

  /// No description provided for @moreServices.
  ///
  /// In en, this message translates to:
  /// **'More Services'**
  String get moreServices;

  /// No description provided for @hrOperations.
  ///
  /// In en, this message translates to:
  /// **'HR Operations'**
  String get hrOperations;

  /// No description provided for @financeAndAssets.
  ///
  /// In en, this message translates to:
  /// **'Finance & Assets'**
  String get financeAndAssets;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get navLeave;

  /// No description provided for @navPayslip.
  ///
  /// In en, this message translates to:
  /// **'Payslip'**
  String get navPayslip;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navHR.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get navHR;

  /// No description provided for @navPayroll.
  ///
  /// In en, this message translates to:
  /// **'Payroll'**
  String get navPayroll;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get navCompanies;

  /// No description provided for @itemAttendanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'History & clock logs'**
  String get itemAttendanceSubtitle;

  /// No description provided for @itemOvertimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Request & track OT'**
  String get itemOvertimeSubtitle;

  /// No description provided for @itemExpensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Claims & receipts'**
  String get itemExpensesSubtitle;

  /// No description provided for @itemTrainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Courses & skills'**
  String get itemTrainingSubtitle;

  /// No description provided for @itemKpisSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Performance goals'**
  String get itemKpisSubtitle;

  /// No description provided for @itemHolidaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Company calendar'**
  String get itemHolidaysSubtitle;

  /// No description provided for @itemRulesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Regulations & guide'**
  String get itemRulesSubtitle;

  /// No description provided for @itemPoliciesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & conditions'**
  String get itemPoliciesSubtitle;

  /// No description provided for @itemEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get itemEmployees;

  /// No description provided for @itemEmployeesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Directory & staff profiles'**
  String get itemEmployeesSubtitle;

  /// No description provided for @itemHrStructure.
  ///
  /// In en, this message translates to:
  /// **'HR Structure'**
  String get itemHrStructure;

  /// No description provided for @itemHrStructureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Departments & designations'**
  String get itemHrStructureSubtitle;

  /// No description provided for @itemAdminAttendanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily check-in logs & scans'**
  String get itemAdminAttendanceSubtitle;

  /// No description provided for @itemAdminLeaveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Time-off approvals & balance'**
  String get itemAdminLeaveSubtitle;

  /// No description provided for @itemAdminOvertimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Extra hours review & claims'**
  String get itemAdminOvertimeSubtitle;

  /// No description provided for @itemAdminShiftsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rosters & timing schedules'**
  String get itemAdminShiftsSubtitle;

  /// No description provided for @itemAdminPayrollSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Salaries & payslip generation'**
  String get itemAdminPayrollSubtitle;

  /// No description provided for @itemAdminExpensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt review & payouts'**
  String get itemAdminExpensesSubtitle;

  /// No description provided for @itemBranchLocations.
  ///
  /// In en, this message translates to:
  /// **'Branch Locations'**
  String get itemBranchLocations;

  /// No description provided for @itemBranchLocationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'GPS geofences & Wi-Fi'**
  String get itemBranchLocationsSubtitle;

  /// No description provided for @itemKpiPerformance.
  ///
  /// In en, this message translates to:
  /// **'KPI & Performance'**
  String get itemKpiPerformance;

  /// No description provided for @itemKpiPerformanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quarterly reviews'**
  String get itemKpiPerformanceSubtitle;

  /// No description provided for @itemAuditLogs.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get itemAuditLogs;

  /// No description provided for @itemAuditLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'System activity logs'**
  String get itemAuditLogsSubtitle;

  /// No description provided for @itemHolidayCalendar.
  ///
  /// In en, this message translates to:
  /// **'Holiday Calendar'**
  String get itemHolidayCalendar;

  /// No description provided for @itemHolidayCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Public & company days off'**
  String get itemHolidayCalendarSubtitle;

  /// No description provided for @itemAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Company Announcements'**
  String get itemAnnouncements;

  /// No description provided for @itemAnnouncementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcasts & notices'**
  String get itemAnnouncementsSubtitle;

  /// No description provided for @itemCompanyPolicies.
  ///
  /// In en, this message translates to:
  /// **'Company Policies'**
  String get itemCompanyPolicies;

  /// No description provided for @itemCompanyPoliciesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'HR handbook & docs'**
  String get itemCompanyPoliciesSubtitle;

  /// No description provided for @itemRolesPermissions.
  ///
  /// In en, this message translates to:
  /// **'Roles & Permissions'**
  String get itemRolesPermissions;

  /// No description provided for @itemRolesPermissionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access controls'**
  String get itemRolesPermissionsSubtitle;

  /// No description provided for @itemSupportTickets.
  ///
  /// In en, this message translates to:
  /// **'Support Tickets'**
  String get itemSupportTickets;

  /// No description provided for @itemSupportTicketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Client helpdesk'**
  String get itemSupportTicketsSubtitle;

  /// No description provided for @itemPlatformHealth.
  ///
  /// In en, this message translates to:
  /// **'Platform Health'**
  String get itemPlatformHealth;

  /// No description provided for @itemPlatformHealthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'KPIs & uptime'**
  String get itemPlatformHealthSubtitle;

  /// No description provided for @itemGlobalAnnouncementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Global broadcasts'**
  String get itemGlobalAnnouncementsSubtitle;

  /// No description provided for @itemPlatformSettings.
  ///
  /// In en, this message translates to:
  /// **'Platform Settings'**
  String get itemPlatformSettings;

  /// No description provided for @itemPlatformSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App configuration'**
  String get itemPlatformSettingsSubtitle;

  /// No description provided for @workShifts.
  ///
  /// In en, this message translates to:
  /// **'Work Shifts'**
  String get workShifts;

  /// No description provided for @companyAssets.
  ///
  /// In en, this message translates to:
  /// **'Company Assets'**
  String get companyAssets;

  /// No description provided for @manageAssignedAssets.
  ///
  /// In en, this message translates to:
  /// **'Track & manage equipment'**
  String get manageAssignedAssets;

  /// No description provided for @recruitmentJobsDesc.
  ///
  /// In en, this message translates to:
  /// **'Open positions & applicants'**
  String get recruitmentJobsDesc;

  /// No description provided for @performanceReviews.
  ///
  /// In en, this message translates to:
  /// **'Performance Reviews'**
  String get performanceReviews;

  /// No description provided for @performanceReviewsDesc.
  ///
  /// In en, this message translates to:
  /// **'Staff KPI & appraisals'**
  String get performanceReviewsDesc;

  /// No description provided for @summaryReports.
  ///
  /// In en, this message translates to:
  /// **'Summary Reports'**
  String get summaryReports;

  /// No description provided for @summaryReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Attendance & payroll overview'**
  String get summaryReportsDesc;

  /// No description provided for @analyticsReports.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Trends'**
  String get analyticsReports;

  /// No description provided for @analyticsReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'HR insights & statistics'**
  String get analyticsReportsDesc;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get total;
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
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
