// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get myProfile => 'My Profile';

  @override
  String get loadingProfile => 'Loading profile...';

  @override
  String get failedToLoadProfile => 'Failed to load profile details.';

  @override
  String get retry => 'Retry';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get company => 'Company';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get department => 'Department';

  @override
  String get accessRoles => 'Access Roles';

  @override
  String get returnToAdminConsole => 'Return to Admin Console';

  @override
  String get logOut => 'Log Out';

  @override
  String get logoutConfirmationDesc =>
      'Are you sure you want to log out of your account?';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get khmer => 'Khmer';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get loginIdentityHint => 'user@email.com, 010123456, or EMP01';

  @override
  String get loginIdentityLabel => 'Email, Phone, or Employee ID';

  @override
  String get fieldRequired => 'Required';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Password *';

  @override
  String get signIn => 'Sign In';

  @override
  String get or => 'OR';

  @override
  String get createAccount => 'Create Account';

  @override
  String get hrManagementSystem => 'HR Management System';

  @override
  String get companyPrefix => 'Company \"';

  @override
  String get createdSuccessSuffix => '\" created successfully! Please sign in.';

  @override
  String get registerYourCompany => 'Register Your Company';

  @override
  String get companyDetails => 'Company Details';

  @override
  String get step1Of2 => 'Step 1 of 2: Create your admin account.';

  @override
  String get step2Of2 => 'Step 2 of 2: Fill in your company information.';

  @override
  String get yourFullName => 'Your Full Name';

  @override
  String get johnSmith => 'John Smith';

  @override
  String get fullNameRequired => 'Full name is required';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneNumberHint => '010 123 456';

  @override
  String get phoneRequiredForLogin => 'Phone number is required for login';

  @override
  String get workEmail => 'Work Email';

  @override
  String get emailHint => 'you@company.com';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get validEmailRequired => 'Enter a valid email';

  @override
  String get min8Chars => 'Min 8 chars';

  @override
  String get min8CharsRequired => 'Must be at least 8 characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get reEnterPassword => 'Re-enter your password';

  @override
  String get pleaseConfirmPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get continueText => 'Continue';

  @override
  String get companyName => 'Company Name';

  @override
  String get companyNameHint => 'Acme Inc.';

  @override
  String get companyNameRequired => 'Company name is required';

  @override
  String get selectCompanySize => 'Select company size';

  @override
  String get companySize => 'Company Size';

  @override
  String get companySizeRequired => 'Please select company size';

  @override
  String get phoneNumberOptional => 'Phone Number (Optional)';

  @override
  String get phoneOptionalHint => '+855 12 345 678';

  @override
  String get back => 'Back';

  @override
  String get createWorkspace => 'Create Workspace';

  @override
  String get loading => 'Loading...';

  @override
  String get verificationEmailSent => 'Verification email sent!';

  @override
  String get emailNotYetVerified => 'Email is not yet verified.';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get verifyYourEmailAddress => 'Verify your email address';

  @override
  String get verificationInstruction =>
      'To continue using the application, you must verify your email address. Please check your inbox and click the verification link.';

  @override
  String get iHaveVerifiedRefresh => 'I have verified (Refresh)';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get confirmOvertimeClockOut => 'Confirm Overtime Clock Out';

  @override
  String get confirmClockOut => 'Confirm Clock Out';

  @override
  String get endOvertimeConfirm =>
      'Are you sure you want to end your overtime?';

  @override
  String get clockOutConfirm =>
      'Are you sure you want to clock out for the day? Your work hours will be recorded.';

  @override
  String get cancel => 'Cancel';

  @override
  String get clockOutBtn => 'Clock Out';

  @override
  String get overtimeEnded => '👋 Overtime ended!';

  @override
  String get clockedOutSuccess => '👋 Clocked out successfully!';

  @override
  String get clockOutFailed => 'Clock-out failed';

  @override
  String get waitingForLocation => '⚠️ Waiting for location data...';

  @override
  String get unknownLocation => 'Unknown Location';

  @override
  String get helloPrefix => 'Hello, ';

  @override
  String get myCompany => 'My Company';

  @override
  String get loadingDashboard => 'Loading dashboard...';

  @override
  String get lateWarningTitle => 'Late Attendance Warning';

  @override
  String get lateWarningDesc1 => 'Notice: You have been late ';

  @override
  String get lateWarningDesc2 =>
      ' times this month. Please ensure you clock in on time to adhere to company policy.';

  @override
  String get overview => 'Overview';

  @override
  String get upcomingLeaves => 'Upcoming Leaves';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get activeTrainings => 'Active Trainings';

  @override
  String get companyAnnouncements => 'Company Announcements';

  @override
  String get readyToWork => 'Ready to Work?';

  @override
  String get overtimeStartedAt => 'Overtime started at ';

  @override
  String get overtimeCompleted => 'Overtime Completed';

  @override
  String get clockedInAt => 'Clocked in at ';

  @override
  String get activeDuration => 'Active duration: ';

  @override
  String get shiftCompleted => 'Shift Completed';

  @override
  String get worked => 'Worked: ';

  @override
  String get locationAccessRequired => 'Location Access Required';

  @override
  String get locationAccessDesc =>
      'We need location access to verify your check-in distance.';

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get calculatingLocation => 'Calculating location...';

  @override
  String get withinRadiusPrefix => 'Within radius (';

  @override
  String get clockOutAnywhere => 'You can clock out from anywhere.';

  @override
  String get youAreAwayPrefix => 'You are ';

  @override
  String get youAreAwaySuffix => 'm away.';

  @override
  String get mustBeWithinPrefix => 'Must be within ';

  @override
  String get mustBeWithinSuffix => 'm to clock in.';

  @override
  String get managerPortal => 'Manager Portal';

  @override
  String get teamApprovals => 'Team approvals';

  @override
  String get leaves => 'Leaves';

  @override
  String get requestOffDays => 'Request off days';

  @override
  String get expenses => 'Expenses';

  @override
  String get claimReimbursements => 'Claim reimbursements';

  @override
  String get payslips => 'Payslips';

  @override
  String get viewMonthlyStatements => 'View monthly statements';

  @override
  String get history => 'History';

  @override
  String get checkAttendanceLogs => 'Check attendance logs';

  @override
  String get training => 'Training';

  @override
  String get enrollInCourses => 'Enroll in courses';

  @override
  String get myKpis => 'My KPIs';

  @override
  String get performanceGoals => 'Performance goals';

  @override
  String get holidays => 'Holidays';

  @override
  String get companyCalendar => 'Company calendar';

  @override
  String get failedToLoadDashboard => 'Failed to load dashboard';

  @override
  String get swipeToClockOutOT => 'Swipe to Clock Out (OT)';

  @override
  String get swipeToClockInOT => 'Swipe to Clock In (OT)';

  @override
  String get swipeToClockOut => 'Swipe to Clock Out';

  @override
  String get swipeToClockIn => 'Swipe to Clock In';

  @override
  String get quickFeatures => 'Quick Features';

  @override
  String get requestCorrection => 'Request Correction';

  @override
  String get requestCorrectionDesc =>
      'Submit a request to correct an anomaly in your attendance log.';

  @override
  String get dateStr => 'Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get correctionType => 'Correction Type';

  @override
  String get missedClockIn => 'Missed Clock In';

  @override
  String get missedClockOut => 'Missed Clock Out';

  @override
  String get wrongTime => 'Wrong Time';

  @override
  String get reason => 'Reason';

  @override
  String get explainCorrectionReason =>
      'Explain why you are requesting this correction...';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get correctionSubmitted => '✅ Correction request submitted';

  @override
  String get attendanceHistory => 'Attendance History';

  @override
  String get loadingCalendar => 'Loading calendar...';

  @override
  String get noRecordForThisDay => 'No record for this day';

  @override
  String get noRecordsThisMonth => 'No attendance records this month';

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get late => 'Late';

  @override
  String get halfDay => 'Half Day';

  @override
  String get unknownDate => 'Unknown date';

  @override
  String get inLabel => 'In: ';

  @override
  String get outLabel => 'Out: ';

  @override
  String get minsBreak => ' mins break';

  @override
  String get earlyIn => 'Early In';

  @override
  String get hLabel => 'h ';

  @override
  String get mLabel => 'm';

  @override
  String get otApproved => 'OT Approved';

  @override
  String get lateLabel => ' late';

  @override
  String get simMockSelfie => '🤖 Simulator: generated mock selfie photo';

  @override
  String get cameraPermissionRequired =>
      '❌ Camera permission is required for selfie verification.';

  @override
  String get cameraException => '⚠️ Camera exception: ';

  @override
  String get outOfRange => 'Out of Range';

  @override
  String get outOfRangeDesc1 => 'You are ';

  @override
  String get outOfRangeDesc2 => 'm away from the branch (allowed: ';

  @override
  String get outOfRangeDesc3 =>
      'm). This will be flagged for manager review. Proceed?';

  @override
  String get clockInAnyway => 'Clock In Anyway';

  @override
  String get clockedInSuccessfully => 'Clocked in successfully!';

  @override
  String get clockedOutSuccessfully => 'Clocked out successfully!';

  @override
  String get attendanceRecorded => 'Your attendance has been recorded.';

  @override
  String get clockedInSuccessfullyEmoji => '🎉 Clocked in successfully!';

  @override
  String get clockedOutSuccessfullyEmoji => '🎉 Clocked out successfully!';

  @override
  String get clockInFailed => 'Clock-in failed';

  @override
  String get overtimeCheckIn => 'Overtime Check In';

  @override
  String get checkInTitle => 'Check In';

  @override
  String get overtimeCheckOut => 'Overtime Check Out';

  @override
  String get checkOutTitle => 'Check Out';

  @override
  String get takeSelfie => 'Take Selfie';

  @override
  String get tapToCapture => 'Tap to capture';

  @override
  String get takeSelfieToVerify => 'Please take Selfie to verify yourself';

  @override
  String get locationLabel => 'Location: ';

  @override
  String get withinRadiusLabel => 'Within ';

  @override
  String get mRadius => 'm radius';

  @override
  String get confirmAction => 'Confirm ';

  @override
  String get selectLeaveType => 'Select leave type';

  @override
  String get enterLeaveReason => 'Please enter a reason for the leave';

  @override
  String get noEmployeeProfile =>
      'No employee profile associated with this account';

  @override
  String get invalidEmployeeId => 'Invalid employee ID configuration';

  @override
  String get leaveRequestSubmitted => '✅ Leave request submitted successfully';

  @override
  String get failedToSubmitLeave => 'Failed to submit leave request';

  @override
  String get requestLeave => 'Request Leave';

  @override
  String get submittingLeave => 'Submitting leave request...';

  @override
  String get noLeaveTypesConfigured =>
      'No leave types configured for your company.';

  @override
  String get leaveTypeLabel => 'Leave Type';

  @override
  String get balanceLabel => ' balance: ';

  @override
  String get daysRemaining => ' days remaining';

  @override
  String get noBalanceRecord => 'No balance record found for this leave type.';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get requestHalfDay => 'Request Half Day';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get describeLeaveReason => 'Describe your reason for leave...';

  @override
  String get attachmentOptional => 'Attachment (Optional)';

  @override
  String get tapToSelectFile => 'Tap to select file (PDF, JPG, PNG)';

  @override
  String get loadingLeaveTypes => 'Loading leave types...';

  @override
  String get failedToLoadLeaveTypes => 'Failed to load leave types';

  @override
  String get digitalWallet => 'Digital Wallet';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get noPayslipsAvailable => 'No payslips available';

  @override
  String get loadingSecureWallet => 'Loading secure wallet...';

  @override
  String get employee => 'Employee';

  @override
  String get lastNetPay => 'Last Net Pay';

  @override
  String get downloadStarted => '✅ Download started';

  @override
  String get pending => 'Pending';

  @override
  String get basicSalary => 'Basic Salary';

  @override
  String get overtimePay => 'Overtime Pay';

  @override
  String get allowances => 'Allowances';

  @override
  String get grossPay => 'Gross Pay';

  @override
  String get tax => 'Tax';

  @override
  String get insurance => 'Insurance';

  @override
  String get lateDeduction => 'Late Deduction';

  @override
  String get earlyLeaveDeduction => 'Early Leave Deduction';

  @override
  String get totalDeductions => 'Total Deductions';

  @override
  String get netPay => 'Net Pay';

  @override
  String get workingDays => 'Working Days';

  @override
  String get earlyOut => 'Early Out';

  @override
  String get otHours => 'OT Hours';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get downloadUrlNotAvailable => 'Download URL is not available.';

  @override
  String get couldNotLaunchUrl => 'Could not launch url';

  @override
  String get failedToDownloadDoc => 'Failed to download document: ';

  @override
  String get companyDocuments => 'Company Documents';

  @override
  String get errorPrefix => 'Error: ';

  @override
  String get noDocumentsAvailable => 'No documents available';

  @override
  String get leaveManagement => 'Leave Management';

  @override
  String get loadingBalances => 'Loading balances...';

  @override
  String get noLeaveBalances => 'No leave balances found';

  @override
  String get noLeaveHistory => 'No leave history';

  @override
  String get loadingHistory => 'Loading history...';

  @override
  String get usedLabel => ' used';

  @override
  String get halfLabel => 'HALF';

  @override
  String get attachmentIncluded => 'Attachment included';

  @override
  String get cancelRequest => 'Cancel Request';

  @override
  String get cancelLeaveConfirm =>
      'Are you sure you want to cancel this leave request?';

  @override
  String get no => 'No';

  @override
  String get yesCancel => 'Yes, cancel';

  @override
  String get leaveRequestCancelled => '✅ Leave request cancelled';

  @override
  String get noExpenseClaims => 'No expense claims';

  @override
  String get submitFirstExpense =>
      'Submit your first expense claim to get started';

  @override
  String get loadingExpenses => 'Loading expenses...';

  @override
  String get deleteClaim => 'Delete Claim';

  @override
  String deleteClaimConfirm(String title) {
    return 'Delete \"$title\" permanently?';
  }

  @override
  String get claimDeleted => '✅ Claim deleted';

  @override
  String get failedToDelete => 'Failed to delete';

  @override
  String get expenseClaimDetails => 'Expense Claim Details';

  @override
  String get title => 'Title';

  @override
  String get category => 'Category';

  @override
  String get amount => 'Amount';

  @override
  String get expenseDate => 'Expense Date';

  @override
  String get statusLabel => 'Status';

  @override
  String get description => 'Description';

  @override
  String get rejectionReason => 'Rejection Reason';

  @override
  String get paidAt => 'Paid At';

  @override
  String get receipt => 'Receipt';

  @override
  String get editExpenseClaim => 'Edit Expense Claim';

  @override
  String get newExpenseClaim => 'New Expense Claim';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get titleHint => 'e.g. Client lunch, Taxi fare';

  @override
  String get titleError => 'Title is required';

  @override
  String get categoryRequired => 'Category *';

  @override
  String get amountRequired => 'Amount *';

  @override
  String get requiredError => 'Required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get currency => 'Currency';

  @override
  String get expenseDateRequired => 'Expense Date *';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get receiptOptional => 'Receipt (optional)';

  @override
  String get tapToAttachReceipt => 'Tap to attach receipt';

  @override
  String get cameraOrGallery => 'Camera or Gallery  ·  JPG, PNG, WEBP';

  @override
  String get expenseClaimUpdated => '✅ Expense claim updated';

  @override
  String get expenseClaimSubmitted => '✅ Expense claim submitted';

  @override
  String get failedToUpdate => 'Failed to update';

  @override
  String get failedToSubmit => 'Failed to submit';

  @override
  String get travel => 'Travel';

  @override
  String get meals => 'Meals';

  @override
  String get supplies => 'Supplies';

  @override
  String get software => 'Software';

  @override
  String get transport => 'Transport';

  @override
  String get accommodation => 'Accommodation';

  @override
  String get other => 'Other';

  @override
  String get myTraining => 'My Training';

  @override
  String get availableCourses => 'Available Courses';

  @override
  String get myEnrollments => 'My Enrollments';

  @override
  String get enrollInTraining => 'Enroll in Training';

  @override
  String enrollConfirm(String title) {
    return 'Are you sure you want to enroll in \"$title\"?';
  }

  @override
  String get enroll => 'Enroll';

  @override
  String get enrolledSuccess => '✅ Successfully enrolled!';

  @override
  String get enrolledFailed => 'Failed to enroll';

  @override
  String get noAvailableTrainings => 'No available trainings.';

  @override
  String get loadingCourses => 'Loading courses...';

  @override
  String get noEnrolledTrainings => 'You have not enrolled in any trainings.';

  @override
  String get loadingEnrollments => 'Loading enrollments...';

  @override
  String get companyWide => 'Company-Wide';

  @override
  String get enrolled => 'Enrolled';

  @override
  String get enrollNow => 'Enroll Now';

  @override
  String get courseProgress => 'Course Progress';

  @override
  String get companyPolicies => 'Company Policies';

  @override
  String get actionRequired => 'Action Required';

  @override
  String get acknowledged => 'Acknowledged';

  @override
  String get allPoliciesAcknowledged => 'All policies have been acknowledged!';

  @override
  String get noPoliciesAcknowledged =>
      'You have not acknowledged any policies yet.';

  @override
  String get version => 'Version ';

  @override
  String get policyAcknowledgedSuccess => '✅ Policy acknowledged successfully.';

  @override
  String get policyDocument => 'Policy Document';

  @override
  String get acknowledgedOn => 'Acknowledged on ';

  @override
  String get iHaveReadAndAcknowledge => 'I have read and acknowledge';

  @override
  String get holidayCalendar => 'Holiday Calendar';

  @override
  String get holidaysThisMonth => 'Holidays this month';

  @override
  String get noHolidaysThisMonth => 'No holidays this month';

  @override
  String get loadingHolidays => 'Loading Holidays...';

  @override
  String get performanceKpis => 'Performance KPIs';

  @override
  String get platformHealth => 'Platform Health';

  @override
  String get myPerf => 'My Perf.';

  @override
  String get team => 'Team';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get submit => 'Submit';

  @override
  String get remove => 'Remove';

  @override
  String get hrDashboard => 'HR Dashboard';

  @override
  String get employees => 'Employees';

  @override
  String get attendanceMenu => 'Attendance';

  @override
  String get leaveRequests => 'Leave Requests';

  @override
  String get more => 'More';

  @override
  String get home => 'Home';

  @override
  String get leave => 'Leave';

  @override
  String get switchingBranchView => 'Switching Branch View…';

  @override
  String get loadingBranchData => 'Loading branch data';

  @override
  String get selectBranch => 'Select Branch';

  @override
  String get viewAsBranchManager => 'VIEW AS BRANCH MANAGER';

  @override
  String get companyOverview => 'Company Overview';

  @override
  String get totalStaff => 'Total Staff';

  @override
  String get onLeave => 'On Leave';

  @override
  String get openJobs => 'Open Jobs';

  @override
  String get assets => 'Assets';

  @override
  String get errorLoadingKpis => 'Error loading KPIs: ';

  @override
  String get quickOperations => 'Quick Operations';

  @override
  String get hrStructure => 'HR Structure';

  @override
  String get deptsAndBranches => 'Depts & branches';

  @override
  String get kpis => 'KPIs';

  @override
  String get manageStaff => 'Manage staff';

  @override
  String get viewLogs => 'View logs';

  @override
  String get shiftRules => 'Shift Rules';

  @override
  String get workSchedules => 'Work schedules';

  @override
  String get manageCompanyHolidays => 'Manage company holidays';

  @override
  String get reviewSubmissions => 'Review submissions';

  @override
  String get branchSettings => 'Branch Settings';

  @override
  String get payrollAndRules => 'Payroll & rules';

  @override
  String get branchInfoMissing =>
      'Branch information is missing. Please refresh profile.';

  @override
  String get payroll => 'Payroll';

  @override
  String get processRuns => 'Process runs';

  @override
  String get expenseClaims => 'Expense Claims';

  @override
  String get reviewClaims => 'Review claims';

  @override
  String get devicesAndStock => 'Devices & stock';

  @override
  String get announcements => 'Announcements';

  @override
  String get broadcastAlerts => 'Broadcast alerts';

  @override
  String get recruitment => 'Recruitment';

  @override
  String get jobsAndCandidates => 'Jobs & candidates';

  @override
  String get performance => 'Performance';

  @override
  String get reviewsAndTraining => 'Reviews & training';

  @override
  String get reports => 'Reports';

  @override
  String get analyticsAndExports => 'Analytics & exports';

  @override
  String get documents => 'Documents';

  @override
  String get companyFiles => 'Company files';

  @override
  String get policies => 'Policies';

  @override
  String get rulesAndGuidelines => 'Rules & guidelines';

  @override
  String get notifications => 'Notifications';

  @override
  String get viewInbox => 'View inbox';

  @override
  String get hrPortalActive => 'HR Portal Active';

  @override
  String get readAll => 'Read All';

  @override
  String get loadingNotifications => 'Loading notifications...';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get allMarkedRead => '✅ All marked read';

  @override
  String get noAdditionalDetails => 'No additional details provided.';

  @override
  String get closeBtn => 'Close';

  @override
  String get viewDetails => 'View Details';

  @override
  String get noKpisFound => 'No KPIs found.';

  @override
  String get estimatedBadge => 'Estimated';

  @override
  String get liveDataBadge => 'Live Data';

  @override
  String scoreLabel(num score) {
    return 'Score: $score%';
  }

  @override
  String get overallSystemScore => 'Overall System Score';

  @override
  String get basedOnDynamicData => 'Based on dynamic module data';

  @override
  String get branchAverageScore => 'Branch Average Score';

  @override
  String get aggregatedFromTeam => 'Aggregated from team metrics';

  @override
  String get platformGlobalHealth => 'Platform Global Health';

  @override
  String get aggregatedAcrossWorkspaces =>
      'Aggregated across all registered workspaces';

  @override
  String get platformSummary => 'Platform Summary';

  @override
  String get platformSummaryDesc =>
      'These are platform-wide metrics calculating the overall health, retention rates, support SLAs, and MRR (Monthly Recurring Revenue) across all active companies within the system.';

  @override
  String get platformStrategicKpis => 'Platform Strategic KPIs';

  @override
  String get companyHealthScore => 'Company Health Score';

  @override
  String get scoreExcellent => 'Excellent';

  @override
  String get scoreGood => 'Good';

  @override
  String get scoreNeedsAttention => 'Needs Attention';

  @override
  String get scoreCritical => 'Critical';

  @override
  String kpisTrackedLiveData(int count) {
    return '$count KPIs tracked • Live Data';
  }

  @override
  String get targetLabel => 'Target: ';

  @override
  String get kpiOnTrack => 'On Track';

  @override
  String get kpiModerate => 'Moderate';

  @override
  String get kpiAtRisk => 'At Risk';

  @override
  String get noCompanyKpisFound => 'No company KPIs found.';

  @override
  String get noCompanyKpisDesc =>
      'Data will appear once employees,\nattendance and payroll are set up.';

  @override
  String get platformAdminTitle => 'Platform Admin';

  @override
  String get platformAdministratorBadge => '🛡️  Platform Administrator';

  @override
  String get menuCompanies => 'Companies';

  @override
  String get menuCompaniesDesc => 'Manage registers';

  @override
  String get menuRoles => 'Roles';

  @override
  String get menuRolesDesc => 'Manage access';

  @override
  String get menuSupportTickets => 'Support Tickets';

  @override
  String get menuSupportTicketsDesc => 'User queries';

  @override
  String get menuKPIs => 'KPIs';

  @override
  String get menuKPIsDesc => 'Performance goals';

  @override
  String get menuAnnouncements => 'Announcements';

  @override
  String get menuAnnouncementsDesc => 'Broadcast alerts';

  @override
  String get menuAuditLogs => 'Audit Logs';

  @override
  String get menuAuditLogsDesc => 'System changes';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuSettingsDesc => 'Global configs';

  @override
  String get menuAdminProfile => 'Admin Profile';

  @override
  String get menuAdminProfileDesc => 'Security & setup';

  @override
  String get platformStatistics => 'Platform Statistics';

  @override
  String get statCompanies => 'Companies';

  @override
  String statCompaniesActive(String count) {
    return '$count active';
  }

  @override
  String get statTotalUsers => 'Total Users';

  @override
  String get statUsersDesc => 'Across all tenants';

  @override
  String get statOpenTickets => 'Open Tickets';

  @override
  String get statTicketsDesc => 'Awaiting response';

  @override
  String get statAnnouncements => 'Announcements';

  @override
  String get statAnnouncementsDesc => 'Published and active';

  @override
  String get recentCompanySignups => 'Recent Company Signups';

  @override
  String get recentSupportTickets => 'Recent Support Tickets';

  @override
  String get platformSettingsTitle => 'Platform Settings';

  @override
  String get failedToLoadSettings => 'Failed to load settings';

  @override
  String get settingsSavedSuccess => '✅ Settings saved';

  @override
  String settingsFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String get globalSettingsTitle => 'Global Settings';

  @override
  String get appNameLabel => 'Application Name';

  @override
  String get supportEmailLabel => 'Support Email';

  @override
  String get defaultTimezoneLabel => 'Default Timezone';

  @override
  String get defaultCurrencyLabel => 'Default Currency';

  @override
  String get saving => 'Saving...';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get platformRolesTitle => 'Platform Roles';

  @override
  String get noSystemRolesFound => 'No system roles found';

  @override
  String permissionsCount(int count) {
    return '$count permissions';
  }

  @override
  String get loadingRoles => 'Loading roles...';

  @override
  String get editRoleTitle => 'Edit Role';

  @override
  String get createNewRoleTitle => 'Create New Role';

  @override
  String get roleNameLabel => 'Role Name';

  @override
  String get roleNameHint => 'e.g. HR Manager';

  @override
  String get coreSystemRolesWarning =>
      'Core system role names cannot be changed.';

  @override
  String get permissionsLabel => 'Permissions';

  @override
  String get roleUpdatedSuccess => 'Role updated';

  @override
  String get roleCreatedSuccess => '✅ Role created';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get btnCreateRole => 'Create Role';

  @override
  String get deleteRoleTitle => 'Delete Role';

  @override
  String deleteRoleConfirm(String name) {
    return 'Delete role $name?';
  }

  @override
  String get roleDeletedSuccess => 'Role deleted';

  @override
  String get failedToDeleteRole => 'Failed to delete role';

  @override
  String get supportTicketsTitle => 'Support Tickets';

  @override
  String get failedToLoadTickets => 'Failed to load tickets';

  @override
  String get noSupportTickets => 'No support tickets';

  @override
  String get markInProgress => 'Mark In Progress';

  @override
  String get markResolved => 'Mark Resolved';

  @override
  String get closeTicket => 'Close Ticket';

  @override
  String ticketMarkedAs(int id, String status) {
    return 'Ticket #$id marked as $status';
  }

  @override
  String get platformAnnouncementsTitle => 'Platform Announcements';

  @override
  String get failedToLoadAnnouncements => 'Failed to load announcements';

  @override
  String get noAnnouncementsYet => 'No announcements yet';

  @override
  String get statusPublished => 'Published';

  @override
  String get statusDraft => 'Draft';

  @override
  String get deleteAnnouncementTitle => 'Delete Announcement';

  @override
  String deleteAnnouncementConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get btnDelete => 'Delete';

  @override
  String get announcementDeleted => 'Announcement deleted';

  @override
  String get editAnnouncementTitle => 'Edit Announcement';

  @override
  String get createAnnouncementTitle => 'Create Announcement';

  @override
  String get titleLabel => 'Title';

  @override
  String get bodyLabel => 'Body';

  @override
  String get targetAudienceLabel => 'Target Audience';

  @override
  String get audienceAllEmployees => '🌐 All Employees (Company-Wide)';

  @override
  String get audienceManagers => '👔 Managers & Team Leads';

  @override
  String get audienceHRTeam => '👥 HR Team Only';

  @override
  String get publishImmediatelyLabel => 'Publish immediately';

  @override
  String get announcementUpdatedSuccess => 'Announcement updated';

  @override
  String get announcementCreatedSuccess => 'Announcement created';

  @override
  String get btnUpdateAnnouncement => 'Update Announcement';

  @override
  String get btnCreateAnnouncement => 'Create Announcement';

  @override
  String get profileSettingsTitle => 'Profile Settings';

  @override
  String get profileInfoTitle => 'Profile Information';

  @override
  String get profileInfoDesc =>
      'Update your account\'s profile information and email address.';

  @override
  String get nameLabel => 'Name';

  @override
  String get genderLabel => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get maritalStatusLabel => 'Marital Status';

  @override
  String get maritalSingle => 'Single';

  @override
  String get maritalMarried => 'Married';

  @override
  String get maritalDivorced => 'Divorced';

  @override
  String get maritalWidowed => 'Widowed';

  @override
  String get dateOfBirthLabel => 'Date of Birth';

  @override
  String get saveProfileBtn => 'Save Profile';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get updatePasswordTitle => 'Update Password';

  @override
  String get updatePasswordDesc =>
      'Ensure your account is using a long, random password to stay secure.';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get btnUpdatePassword => 'Update Password';

  @override
  String get passwordUpdatedSuccess => 'Password updated successfully';

  @override
  String get testingDebuggingTitle => 'Testing & Debugging';

  @override
  String get testingDebuggingDesc =>
      'Use these tools to verify app functionality.';

  @override
  String get testLocalNotificationBtn => 'Test Local Notification';

  @override
  String get auditLogsTitle => 'Audit Logs';

  @override
  String get failedToLoadAuditLogs => 'Failed to load audit logs';

  @override
  String get noAuditLogsYet => 'No audit logs yet';

  @override
  String byUser(String name) {
    return 'By $name';
  }

  @override
  String get noDetailsAvailable => 'No details available for this log';

  @override
  String get changesTitle => 'Changes';

  @override
  String get adminCompaniesTitle => 'Companies';

  @override
  String get failedToLoadCompanies => 'Failed to load companies';

  @override
  String get noCompaniesYet => 'No companies yet';

  @override
  String get statusActive => 'Active';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionStats => 'Stats';

  @override
  String get actionSuspend => 'Suspend';

  @override
  String get actionActivate => 'Activate';

  @override
  String get actionDelete => 'Delete';

  @override
  String get suspendCompanyTitle => 'Suspend Company';

  @override
  String suspendCompanyContent(String name) {
    return 'Are you sure you want to suspend \"$name\"? This will deactivate their account.';
  }

  @override
  String companySuspendedSuccess(String name) {
    return '$name has been suspended';
  }

  @override
  String get activateCompanyTitle => 'Activate Company';

  @override
  String activateCompanyContent(String name) {
    return 'Activate \"$name\"?';
  }

  @override
  String companyActivatedSuccess(String name) {
    return '$name activated';
  }

  @override
  String get deleteCompanyTitle => 'Delete Company';

  @override
  String deleteCompanyContent(String name) {
    return 'Permanently delete \"$name\"? This action cannot be undone.';
  }

  @override
  String companyDeletedSuccess(String name) {
    return '$name deleted';
  }

  @override
  String get companyStatsTitle => 'Company Stats';

  @override
  String get noStatsAvailable => 'No stats available';

  @override
  String get editCompanyTitle => 'Edit Company';

  @override
  String get createCompanyTitle => 'Create Company';

  @override
  String get companyNameLabel => 'Company Name';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get companyOwnerAccountTitle => 'Company Owner Account';

  @override
  String get companyOwnerEditDesc =>
      'Update owner details or enter a new password to reset account access.';

  @override
  String get companyOwnerCreateDesc =>
      'Account automatically created for the owner. Leave blank to default to company email and password Password123!.';

  @override
  String get ownerNameLabel => 'Owner Name';

  @override
  String get ownerLoginEmailLabel => 'Owner Login Email';

  @override
  String get newPasswordOptionalLabel => 'New Password (Optional)';

  @override
  String get ownerPasswordLabel => 'Owner Password';

  @override
  String get phoneLabel => 'Phone Number';

  @override
  String get addressLabel => 'Address';

  @override
  String get gettingLocation => 'Getting...';

  @override
  String get getLocation => 'Get Location';

  @override
  String get timezoneLabel => 'Timezone';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get socialMediaLinksTitle => 'Social Media Links';

  @override
  String get actionAdd => 'Add';

  @override
  String get noSocialMediaLinks => 'No social media links added.';

  @override
  String get platformLabel => 'Platform';

  @override
  String get urlLabel => 'URL';

  @override
  String get companyLogoTitle => 'Company Logo';

  @override
  String get tapToChangeLogo => 'Tap to change logo';

  @override
  String get tapToUploadLogo => 'Tap to upload logo';

  @override
  String get btnUpdateCompany => 'Update Company';

  @override
  String get btnCreateCompany => 'Create Company';

  @override
  String get companyUpdatedSuccess => 'Company updated successfully';

  @override
  String get companyCreatedSuccess => 'Company created successfully';

  @override
  String get companyCreatedAlertTitle => 'Company Created!';

  @override
  String ownerCredentialsGenerated(String name) {
    return 'Owner credentials generated for \"$name\"';
  }

  @override
  String get ownerEmailTitle => 'OWNER EMAIL';

  @override
  String get ownerPasswordTitle => 'OWNER PASSWORD';

  @override
  String get copied => 'Copied';

  @override
  String get copy => 'Copy';

  @override
  String get copiedAll => 'Copied All';

  @override
  String get copyAll => 'Copy All';

  @override
  String get hrPortalDesc =>
      'Process monthly payroll runs, manage dynamic shift rosters, and approve leaves on the go.';

  @override
  String get companyAdministrator => 'Company Administrator';

  @override
  String get branchManagerView => 'Branch Manager View';

  @override
  String get exit => 'Exit';

  @override
  String viewingAs(String branch) {
    return 'Viewing as $branch';
  }

  @override
  String get branchManagerModeDesc =>
      'You are in Branch Manager mode — data is scoped to this branch.';

  @override
  String get branchOverview => 'Branch Overview';

  @override
  String get staff => 'Staff';

  @override
  String get todaysAttendance => 'Today\'s Attendance';

  @override
  String get pendingLeaves => 'Pending Leaves';

  @override
  String get errorLoadingBranchKpis => 'Error loading branch KPIs: ';

  @override
  String get branchOperations => 'Branch Operations';

  @override
  String get branchStaff => 'Branch staff';

  @override
  String get dailyRecords => 'Daily records';

  @override
  String get payrollSettings => 'Payroll Settings';

  @override
  String get rulesAndOvertime => 'Rules & overtime';

  @override
  String get pendingLeaveRequests => 'Pending Leave Requests';

  @override
  String get noPendingLeaveRequests => '✅  No pending leave requests';

  @override
  String viewingTapToExit(String branch) {
    return '👁  Viewing $branch — Tap to Exit';
  }

  @override
  String get fullTime => 'Full-time';

  @override
  String get partTime => 'Part-time';

  @override
  String get contract => 'Contract';

  @override
  String get intern => 'Intern';

  @override
  String get employeeDirectory => 'Employee Directory';

  @override
  String get manageYourWorkforce => 'Manage your workforce';

  @override
  String peopleCount(int count) {
    return '$count people';
  }

  @override
  String get searchEmployeesHint => 'Search employees...';

  @override
  String get filter => 'Filter';

  @override
  String get allDepartments => 'All Departments';

  @override
  String get branch => 'Branch';

  @override
  String get allBranches => 'All Branches';

  @override
  String get status => 'Status';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get type => 'Type';

  @override
  String get allTypes => 'All Types';

  @override
  String get clearAllFilters => 'Clear all filters';

  @override
  String employeeCount(int count, String s) {
    return '$count employee$s';
  }

  @override
  String get filtered => 'Filtered';

  @override
  String get loadingEmployees => 'Loading employees...';

  @override
  String get addEmployee => 'Add Employee';

  @override
  String get deleteEmployeeTitle => 'Delete Employee?';

  @override
  String get deleteEmployeeConfirmPrefix =>
      'Are you sure you want to permanently delete\n';

  @override
  String get deleteEmployeeConfirmSuffix =>
      '?\n\nThis action cannot be undone.';

  @override
  String employeeDeletedSuccess(String name) {
    return '✅ $name deleted successfully';
  }

  @override
  String failedMsg(String e) {
    return '❌ Failed: $e';
  }

  @override
  String get noResultsFound => 'No results found';

  @override
  String get noEmployeesYet => 'No Employees Yet';

  @override
  String get adjustFiltersHint =>
      'Try adjusting your search or filters to find what you\'re looking for.';

  @override
  String get startBuildingTeamHint =>
      'Start building your team by adding your first employee.';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get failedToLoadEmployees => 'Failed to load employees';

  @override
  String get checkConnectionTryAgain => 'Check your connection and try again.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get employeeProfile => 'Employee Profile';

  @override
  String get editEmployee => 'Edit Employee';

  @override
  String get loadingProfileDetails => 'Loading profile details...';

  @override
  String get failedToLoadProfileDetails => 'Failed to load profile details.';

  @override
  String get noPosition => 'No Position';

  @override
  String get noDepartment => 'No Department';

  @override
  String get tabInfo => 'Info';

  @override
  String get tabLeaves => 'Leaves';

  @override
  String get tabLogs => 'Logs';

  @override
  String get tabContact => 'Contact';

  @override
  String get employmentDetails => 'Employment details';

  @override
  String get employeeId => 'Employee ID';

  @override
  String get employmentType => 'Employment Type';

  @override
  String get joinDate => 'Join Date';

  @override
  String get personalDetails => 'Personal details';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get gender => 'Gender';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get dob => 'DOB';

  @override
  String get maritalStatus => 'Marital Status';

  @override
  String get nationalId => 'National ID';

  @override
  String get address => 'Address';

  @override
  String get payrollAndSalary => 'Payroll & Salary';

  @override
  String get monthlySalary => 'Monthly Salary';

  @override
  String get bankName => 'Bank Name';

  @override
  String get bankAccount => 'Bank Account';

  @override
  String get adminNotes => 'Admin Notes';

  @override
  String get leaveBalances => 'Leave Balances';

  @override
  String get noLeaveBalancesAllocated => 'No leave balances allocated.';

  @override
  String get allocated => 'Allocated';

  @override
  String get used => 'Used';

  @override
  String get remaining => 'Remaining';

  @override
  String get recentLeaveRequests => 'Recent Leave Requests';

  @override
  String get noRecentLeaveRequests => 'No recent leave requests.';

  @override
  String get recentAttendanceLogs => 'Recent Attendance logs';

  @override
  String get noAttendanceLogsFound => 'No attendance logs found.';

  @override
  String get emergencyContactDetails => 'Emergency Contact details';

  @override
  String get noEmergencyContactInfoProvided =>
      'No emergency contact info provided.';

  @override
  String get contactName => 'Contact Name';

  @override
  String get relationship => 'Relationship';

  @override
  String get employeeCreatedSuccess => 'Employee created successfully';

  @override
  String get employeeUpdatedSuccess => 'Employee updated successfully';

  @override
  String get save => 'Save';

  @override
  String get createEmployee => 'Create Employee';

  @override
  String get updateEmployee => 'Update Employee';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get fullName => 'Full Name';

  @override
  String get khmerName => 'Khmer Name';

  @override
  String get addPhoneNumber => 'Add Phone Number';

  @override
  String get uploadIdImages => 'Upload ID Images';

  @override
  String get employeeIdHint => 'Employee ID (Leave blank to auto-generate)';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailAddressRequired => 'Email Address *';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get single => 'Single';

  @override
  String get married => 'Married';

  @override
  String get divorced => 'Divorced';

  @override
  String get widowed => 'Widowed';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get tapToSelect => 'Tap to select';

  @override
  String get nationalIdPassport => 'National ID / Passport';

  @override
  String get employmentDetailsRequired => 'Employment Details';

  @override
  String get employmentTypeRequired => 'Employment Type *';

  @override
  String get statusRequired => 'Status *';

  @override
  String get hireDateRequired => 'Hire Date *';

  @override
  String get probationEnd => 'Probation End';

  @override
  String get terminationDate => 'Termination Date';

  @override
  String get systemRoleRequired => 'System Role *';

  @override
  String get roleEmployee => 'Employee';

  @override
  String get roleBranchManager => 'Branch Manager';

  @override
  String get roleCompanyAdmin => 'Company Admin';

  @override
  String get roleCompanyOwner => 'Company Owner';

  @override
  String get payrollAndBank => 'Payroll & Bank';

  @override
  String get bankAccountNumber => 'Bank Account Number';

  @override
  String get emergencyContact => 'Emergency Contact';

  @override
  String get systemAccess => 'System Access';

  @override
  String get resetPasswordHint => 'Reset password or create login account';

  @override
  String get createAccountHint => 'Create a login account for this employee';

  @override
  String get passwordLoginHint =>
      'Employee will use their email and this password to log in.';

  @override
  String get newEmployee => 'New Employee';

  @override
  String get tapPhotoToChange => 'Tap photo to change';

  @override
  String get required => 'Required';

  @override
  String get none => '— None —';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get terminated => 'Terminated';

  @override
  String get resigned => 'Resigned';

  @override
  String get attendanceLogsTitle => 'Attendance Logs';

  @override
  String get attendanceLogsSubtitle => 'Daily logs & corrections';

  @override
  String get tabDailyLogs => 'Daily Logs';

  @override
  String get tabCorrections => 'Corrections';

  @override
  String get noAttendanceRecords => 'No attendance records';

  @override
  String get inTime => 'In';

  @override
  String get outTime => 'Out';

  @override
  String get approved => 'Approved';

  @override
  String get approvePreShiftOT => 'Approve Pre-shift OT';

  @override
  String get loadingLogs => 'Loading logs...';

  @override
  String get preShiftOtApprovedSuccess => '✅ Pre-shift OT approved';

  @override
  String failedMessage(String error) {
    return 'Failed: $error';
  }

  @override
  String get noPendingCorrections => 'No pending corrections';

  @override
  String get reject => 'Reject';

  @override
  String get approve => 'Approve';

  @override
  String get correctionApprovedSuccess => '✅ Correction approved';

  @override
  String get correctionRejectedSuccess => '✅ Correction rejected';

  @override
  String get leaveManagementTitle => 'Leave Management';

  @override
  String get leaveManagementSubtitle => 'Requests, balances & types';

  @override
  String get tabRequests => 'Requests';

  @override
  String get tabBalances => 'Balances';

  @override
  String get tabTypes => 'Types';

  @override
  String get filterAll => 'All';

  @override
  String get filterPending => 'Pending';

  @override
  String get filterApproved => 'Approved';

  @override
  String get filterRejected => 'Rejected';

  @override
  String get noLeaveRequests => 'No leave requests';

  @override
  String noRequestsByFilter(String filter) {
    return 'No $filter requests';
  }

  @override
  String get newRequest => 'New Request';

  @override
  String get newLeaveRequest => 'New Leave Request';

  @override
  String get submitLeaveApp => 'Submit a leave application';

  @override
  String get employeeRequired => 'Employee *';

  @override
  String get selectEmployee => 'Select employee';

  @override
  String get leaveTypeRequired => 'Leave Type *';

  @override
  String get startDateRequired => 'Start Date *';

  @override
  String get endDateRequired => 'End Date *';

  @override
  String get reasonRequired => 'Reason *';

  @override
  String get reasonForLeaveHint => 'Reason for leave...';

  @override
  String get requestSubmitted => 'Request submitted';

  @override
  String get halfDayLabel => 'Half Day';

  @override
  String get daysShort => 'd';

  @override
  String requestActioned(String action) {
    return 'Request ${action}d';
  }

  @override
  String get addBalance => 'Add Balance';

  @override
  String get carried => 'Carried';

  @override
  String get editBalance => 'Edit Balance';

  @override
  String editBalanceTitle(String name) {
    return 'Edit Balance — $name';
  }

  @override
  String get allocatedDaysRequired => 'Allocated Days *';

  @override
  String get allocatedDays => 'Allocated Days';

  @override
  String get carriedForward => 'Carried Forward';

  @override
  String get balanceUpdated => 'Balance updated';

  @override
  String get addLeaveBalance => 'Add Leave Balance';

  @override
  String get addLeaveBalanceSubtitle => 'Allocate days to an employee';

  @override
  String get singleEmployee => 'Single Employee';

  @override
  String get multipleEmployees => 'Multiple / All Employees';

  @override
  String get employeesRequired => 'Employees *';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String employeesSelected(int count) {
    return '$count employee(s) selected';
  }

  @override
  String get yearRequired => 'Year *';

  @override
  String get assignToEmployees => 'Assign to Employees';

  @override
  String leaveBalanceAssignedMulti(int count) {
    return 'Leave balance assigned to $count employee(s)';
  }

  @override
  String get leaveBalanceCreated => 'Leave balance created';

  @override
  String get noLeaveTypes => 'No leave types';

  @override
  String get loadingTypes => 'Loading types...';

  @override
  String get newType => 'New Type';

  @override
  String get editLeaveType => 'Edit Leave Type';

  @override
  String get addLeaveType => 'Add Leave Type';

  @override
  String get generalInfo => 'General Information';

  @override
  String get nameRequired => 'Name *';

  @override
  String get code => 'Code';

  @override
  String get daysPerYear => 'Days per year';

  @override
  String get sortOrder => 'Sort Order';

  @override
  String get color => 'Color';

  @override
  String get accrualAndBalances => 'Accrual & Balances';

  @override
  String get prorateAccrual => 'Prorate Accrual (adjust for mid-year joiners)';

  @override
  String get allowCarryForward => 'Allow Carry Forward';

  @override
  String get maxCarryForwardDays =>
      'Max Carry Forward Days (empty = unlimited)';

  @override
  String get rulesAndRestrictions => 'Rules & Restrictions';

  @override
  String get noticePeriodDays => 'Notice Period (days) *';

  @override
  String get minTenureDays => 'Minimum Tenure (days, 0 = none)';

  @override
  String get maxConsecutiveDays => 'Max Consecutive Days (empty = unlimited)';

  @override
  String get genderRestriction => 'Gender Restriction';

  @override
  String get allGenders => 'All Genders';

  @override
  String get maleOnly => 'Male Only';

  @override
  String get femaleOnly => 'Female Only';

  @override
  String get options => 'Options';

  @override
  String get paidLeave => 'Paid Leave';

  @override
  String get allowHalfDayRequests => 'Allow Half-Day Requests';

  @override
  String get requiresDocument => 'Requires Document';

  @override
  String get leaveTypeUpdated => 'Leave type updated';

  @override
  String get leaveTypeCreated => 'Leave type created';

  @override
  String get create => 'Create';

  @override
  String get activeLabel => 'ACTIVE';

  @override
  String get inactiveLabel => 'INACTIVE';

  @override
  String daysPerYearLabel(String days) {
    return '$days days/year';
  }

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get prorated => 'Prorated';

  @override
  String get halfDayBadge => 'Half-Day';

  @override
  String carryFwd(String days) {
    return 'Carry Fwd: ${days}d';
  }

  @override
  String get carryForwardBadge => 'Carry Forward';

  @override
  String maxConsec(String days) {
    return 'Max Consec: ${days}d';
  }

  @override
  String get requiresDoc => 'Requires Doc';

  @override
  String genderBadge(String gender) {
    return 'Gender: $gender';
  }

  @override
  String noticeSort(String notice, String sort) {
    return 'Notice: ${notice}d · Sort: $sort';
  }

  @override
  String minTenureBadge(String days) {
    return 'Min Tenure: ${days}d';
  }

  @override
  String get deleteLeaveType => 'Delete Leave Type?';

  @override
  String deleteLeaveTypeConfirm(String name) {
    return 'Are you sure you want to delete\n\"$name\"?\n\nThis action cannot be undone.';
  }

  @override
  String get leaveTypeDeleted => '✅ Leave type deleted successfully';

  @override
  String get nothingToShow => 'Nothing to show here yet.';

  @override
  String get failedToLoadData => 'Failed to load data';

  @override
  String get shiftsAndCalendars => 'Shifts & Calendars';

  @override
  String get manageWorkSchedules => 'Manage work schedules';

  @override
  String shiftsCount(String count) {
    return '$count shifts';
  }

  @override
  String get loadingShifts => 'Loading shifts...';

  @override
  String get activeShiftBadge => 'ACTIVE';

  @override
  String get inactiveShiftBadge => 'INACTIVE';

  @override
  String get overnightBadge => 'OVERNIGHT';

  @override
  String breakTimeRange(String start, String end) {
    return 'Break $start – $end';
  }

  @override
  String gracePeriodBadge(String grace) {
    return '${grace}m grace';
  }

  @override
  String otThresholdBadge(String ot) {
    return 'OT≥${ot}m';
  }

  @override
  String get assign => 'Assign';

  @override
  String get deleteShiftTitle => 'Delete Shift?';

  @override
  String get deleteShiftConfirmPrefix => 'Are you sure you want to delete\n';

  @override
  String get deleteShiftConfirmSuffix => '?\n\nThis action cannot be undone.';

  @override
  String shiftDeletedSuccess(String name) {
    return '✅ Shift deleted';
  }

  @override
  String shiftDeleteFailed(String error) {
    return '❌ Failed to delete: $error';
  }

  @override
  String get assignEmployeesTitle => 'Assign Employees';

  @override
  String assignEmployeesSubtitle(String name, String count) {
    return '$name · $count selected';
  }

  @override
  String get noEmployeesFound => 'No employees found';

  @override
  String employeesCountLabel(String count) {
    return '$count employees';
  }

  @override
  String get assignedBadge => 'Assigned';

  @override
  String get otherShiftBadge => 'Other Shift';

  @override
  String assignCount(String count) {
    return 'Assign $count';
  }

  @override
  String assignSuccess(String count) {
    return '$count assigned';
  }

  @override
  String assignSuccessWithFail(String success, String fail) {
    return '$success assigned, $fail failed';
  }

  @override
  String assignFailedError(String error) {
    return 'Failed: $error';
  }

  @override
  String get newShift => 'New Shift';

  @override
  String get noShiftsYet => 'No Shifts Yet';

  @override
  String get createFirstShiftDesc =>
      'Create your first shift to start managing work schedules.';

  @override
  String get createFirstShiftBtn => 'Create First Shift';

  @override
  String get failedToLoadShifts => 'Failed to load shifts';

  @override
  String get checkConnectionRetry => 'Check your connection and try again.';

  @override
  String get dayMo => 'Mo';

  @override
  String get dayTu => 'Tu';

  @override
  String get dayWe => 'We';

  @override
  String get dayTh => 'Th';

  @override
  String get dayFr => 'Fr';

  @override
  String get daySa => 'Sa';

  @override
  String get daySu => 'Su';

  @override
  String get editScheduleTitle => 'Edit Schedule';

  @override
  String get newScheduleTitle => 'New Schedule';

  @override
  String get editScheduleSubtitle => 'Update shift details';

  @override
  String get newScheduleSubtitle => 'Set up work hours & days';

  @override
  String get generalInfoTitle => 'General Information';

  @override
  String get scheduleNameLabel => 'Schedule Name';

  @override
  String get scheduleNameHint => 'e.g. Standard Office Hours';

  @override
  String get nameRequiredError => 'Name is required';

  @override
  String get shortCodeLabel => 'Short Code (optional)';

  @override
  String get shortCodeHint => 'e.g. STD-01';

  @override
  String get weeklyScheduleTitle => 'Weekly Schedule';

  @override
  String get copyMonToAll => 'Copy Mon to all';

  @override
  String get selectOneWorkingDayError => 'Select at least one working day';

  @override
  String get shiftCreatedSuccess => '✅ Shift created';

  @override
  String get shiftUpdatedSuccess => 'Shift updated successfully';

  @override
  String shiftFailedError(String error) {
    return 'Failed: $error';
  }

  @override
  String get rulesAllowancesTitle => 'Rules & Allowances';

  @override
  String get gracePeriodLabel => 'Grace Period (min)';

  @override
  String get otThresholdLabel => 'OT Threshold (min)';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get overnightShiftTitle => 'Overnight Shift';

  @override
  String get overnightShiftSubtitle => 'This shift crosses midnight';

  @override
  String get activeScheduleTitle => 'Active Schedule';

  @override
  String get activeScheduleSubtitle => 'Available for employee assignment';

  @override
  String get saveChangesBtn => 'Save Changes';

  @override
  String get createScheduleBtn => 'Create Schedule';

  @override
  String get startTimeLabel => 'Start Time';

  @override
  String get endTimeLabel => 'End Time';

  @override
  String get scheduledDayOff => 'Scheduled Day Off';

  @override
  String get dayOff => 'Day off';

  @override
  String get payrollManagementTitle => 'Payroll Management';

  @override
  String get runsTab => 'Runs';

  @override
  String get settingsTab => 'Settings';

  @override
  String get generatePayrollBtn => 'Generate Payroll';

  @override
  String get noPayrollRuns => 'No payroll runs';

  @override
  String get loadingPayrollRuns => 'Loading payroll runs...';

  @override
  String get markCompletedBtn => 'Mark Completed';

  @override
  String payrollRunTitle(String period) {
    return 'Payroll Run $period';
  }

  @override
  String get payrollRunPrompt =>
      'Would you like to mark this Payroll Run as COMPLETED or view Payslips?';

  @override
  String get viewPayslipsBtn => 'View Payslips';

  @override
  String get payrollGeneratedSuccess => '✅ Payroll generated successfully';

  @override
  String get formulasHandbookTitle => 'Formulas Handbook';

  @override
  String get formulasHandbookDesc => 'View active payroll calculations';

  @override
  String get generalSettingsTitle => 'General Settings';

  @override
  String get payrollPeriodLabel => 'Payroll Period';

  @override
  String get payrollStartDayLabel => 'Payroll Start Day (1-31)';

  @override
  String get workingDaysCalcTypeLabel => 'Working Days Calculation Type';

  @override
  String get fixedWorkingDaysLabel => 'Fixed Working Days per Period';

  @override
  String get currencySymbolLabel => 'Currency Symbol (e.g. \$)';

  @override
  String get overtimeSettingsTitle => 'Overtime Settings';

  @override
  String get enableOvertimePayLabel => 'Enable Overtime Pay';

  @override
  String get overtimeThresholdLabel => 'Overtime Threshold (hours/day)';

  @override
  String get regularOtMultiplierLabel => 'Regular OT Multiplier (e.g. 1.5)';

  @override
  String get restDayOtMultiplierLabel => 'Rest Day OT Multiplier (e.g. 2.0)';

  @override
  String get publicHolidayOtMultiplierLabel =>
      'Public Holiday OT Multiplier (e.g. 2.0)';

  @override
  String get companyHolidayOtMultiplierLabel =>
      'Company Holiday OT Multiplier (e.g. 1.5)';

  @override
  String get lateDeductionSettingsTitle => 'Late Deduction Settings';

  @override
  String get enableLateDeductionsLabel => 'Enable Late Deductions';

  @override
  String get gracePeriodMinutesLabel => 'Grace Period (minutes)';

  @override
  String get calculationMethodLabel => 'Calculation Method';

  @override
  String get fixedPenaltyAmountLabel => 'Fixed Penalty Amount (\$)';

  @override
  String get perMinuteMultiplierLabel =>
      'Per-Minute Multiplier (e.g. 1.0 = exact salary)';

  @override
  String get earlyLeavePenaltiesTitle => 'Early Leave Penalties';

  @override
  String get earlyLeaveGraceLabel => 'Early Leave Grace (minutes)';

  @override
  String get deductionTypeLabel => 'Deduction Type';

  @override
  String get preShiftEarlyClockInTitle => 'Pre-Shift & Early Clock-In';

  @override
  String get earlyClockInPolicyLabel => 'Early Clock-In Policy';

  @override
  String get preShiftOtMultiplierLabel => 'Pre-Shift OT Multiplier';

  @override
  String get maxAllowedEarlyMinutesLabel => 'Max Allowed Early Minutes';

  @override
  String get halfDaySettingsTitle => 'Half-Day Settings';

  @override
  String get halfDayMinHoursLabel => 'Half-Day Minimum Hours';

  @override
  String get halfDayDeductionPctLabel => 'Half-Day Deduction %';

  @override
  String get saveSettingsBtn => 'Save Settings';

  @override
  String get loadingSettings => 'Loading settings...';

  @override
  String get periodStartLabel => 'Period Start';

  @override
  String get periodEndLabel => 'Period End';

  @override
  String get generateBtn => 'Generate';

  @override
  String get payrollRunMarkedCompleted => '🎉 Payroll Run marked as COMPLETED!';

  @override
  String get generatePayrollPromptDesc =>
      'Select payroll period to generate employee salary records.';

  @override
  String get weeklyLabel => 'Weekly';

  @override
  String get biWeeklyLabel => 'Bi-Weekly';

  @override
  String get monthlyLabel => 'Monthly';

  @override
  String get calendarDaysLabel => 'Calendar Days';

  @override
  String get calendarMinusHolidaysLabel => 'Calendar Minus Holidays';

  @override
  String get fixedDaysLabel => 'Fixed Days';

  @override
  String get treatAsOvertimeLabel => 'Treat as Overtime';

  @override
  String get paidOutsideLabel => 'Paid Outside (No OT Mult)';

  @override
  String get flatAmountLabel => 'Flat Amount';

  @override
  String get hourlyRateLabel => 'Hourly Rate';

  @override
  String get perMinuteRateLabel => 'Per Minute Rate';

  @override
  String get halfDayDeductionLabel => 'Half Day Deduction';

  @override
  String get ignoreNoExtraPayLabel => 'Ignore (No Extra Pay)';

  @override
  String payrollDetailTitle(String period) {
    return 'Payroll $period';
  }

  @override
  String get exportToExcelTooltip => 'Export to Excel';

  @override
  String get loadingPayslips => 'Loading payslips...';

  @override
  String payrollDetailError(String error) {
    return 'Error: $error';
  }

  @override
  String get totalGrossLabel => 'Total Gross';

  @override
  String get deductionsLabel => 'Deductions';

  @override
  String get netPayLabel => 'Net Pay';

  @override
  String employeesCountSuffix(int count) {
    return '$count employees';
  }

  @override
  String get noPayslipsFound => 'No payslips found';

  @override
  String exportedToPath(String path) {
    return '✅ Exported to $path';
  }

  @override
  String exportFailed(String error) {
    return '❌ Export failed: $error';
  }

  @override
  String get basicSalaryLabel => 'Basic Salary';

  @override
  String get overtimePayLabel => 'Overtime Pay';

  @override
  String get allowancesLabel => 'Allowances';

  @override
  String get otherEarningsLabel => 'Other Earnings';

  @override
  String get grossSalaryLabel => 'Gross Salary';

  @override
  String get taxDeductionLabel => 'Tax Deduction (10%)';

  @override
  String get insuranceDeductionLabel => 'Insurance (5%)';

  @override
  String get lateDeductionLabel => 'Late Deduction';

  @override
  String get otherDeductionsLabel => 'Other Deductions';

  @override
  String get totalDeductionsLabel => 'Total Deductions';

  @override
  String get netSalaryLabel => 'Net Salary';

  @override
  String get workingDaysLabel => 'Working Days';

  @override
  String get presentLabel => 'Present';

  @override
  String get lateLabel2 => 'Late';

  @override
  String get otHoursLabel => 'OT Hours';

  @override
  String branchPayrollTitle(String branch) {
    return '$branch Payroll';
  }

  @override
  String get branchCustomizationTitle => 'Branch Customization';

  @override
  String get branchCustomizationDesc =>
      'If disabled, this branch will inherit the company-wide payroll rules.';

  @override
  String get useCustomBranchRulesLabel => 'Use Custom Branch Rules';

  @override
  String get inheritingCompanyRulesTitle => 'Inheriting Company Rules';

  @override
  String get inheritingCompanyRulesDesc =>
      'This branch uses the global company payroll settings. You can view how they calculate in the Formulas Handbook (top right icon).';

  @override
  String get saveBranchSettingsBtn => 'Save Branch Settings';

  @override
  String get branchSettingsSaved => '✅ Branch settings saved';

  @override
  String get deductionRateAmountLabel => 'Deduction Rate / Amount';

  @override
  String get formulasHandbookScreenTitle => 'Payroll Formulas Handbook';

  @override
  String get formulasHandbookSubtitle =>
      'Verify how your current rules translate into mathematical formulas for payroll calculation.';

  @override
  String get formulasExampleBasis => 'Real-World Example Basis: ';

  @override
  String get formulasExampleBasisDetail =>
      'For the examples below, we assume an employee earns a base salary of ';

  @override
  String formulasSalaryExample(String symbol) {
    return '${symbol}1,000/month';
  }

  @override
  String get formulasWorkHours => ' and works 8 hours per day.';

  @override
  String get hourlyRateCalcTitle => 'Hourly Rate Calculation';

  @override
  String get hourlyRateCalcDesc =>
      'The hourly rate is the foundation for all overtime and deduction calculations.';

  @override
  String hourlyRateFormulaFixed(int fixedDays) {
    return 'Hourly Rate = (Monthly Salary / $fixedDays fixed days) / 8 hours';
  }

  @override
  String get hourlyRateFormulaActual =>
      'Hourly Rate = (Monthly Salary / Actual working days in month) / 8 hours';

  @override
  String hourlyRateExampleFixed(String symbol, int fixedDays, String rate) {
    return 'Example: (${symbol}1,000 ÷ $fixedDays days) ÷ 8 hrs = $symbol$rate per hour.';
  }

  @override
  String hourlyRateExampleActual(String symbol, String rate) {
    return 'Example: (${symbol}1,000 ÷ 22 days) ÷ 8 hrs = $symbol$rate per hour.';
  }

  @override
  String get lateDeductionFormulaTitle => 'Late Deduction Formula';

  @override
  String get earlyLeaveFormulaTitle => 'Early Leave Deduction Formula';

  @override
  String get lateDeductionDisabled => 'Late deductions are currently disabled.';

  @override
  String get earlyLeaveDeductionDisabled =>
      'Early leave deductions are currently disabled.';

  @override
  String lateGraceDesc(int grace) {
    return 'Employees have a grace period of $grace minutes. If an employee is late beyond the grace period, the deduction is calculated as follows:';
  }

  @override
  String earlyLeaveGraceDesc(int grace) {
    return 'Employees have a grace period of $grace minutes. If an employee leaves early beyond the grace period, the deduction is calculated as follows:';
  }

  @override
  String lateFormulaPerMinute(int grace, String rate) {
    return 'Total Deduction = (Late Minutes - $grace) * (Hourly Rate / 60) * $rate (multiplier)';
  }

  @override
  String lateExamplePerMinute(
    int grace,
    String symbol,
    String hourlyRate,
    String rate,
    String amount,
  ) {
    return 'Example (30 mins late): (30 - ${grace}m grace) * ($symbol$hourlyRate/60) * ${rate}x = $symbol$amount deducted.';
  }

  @override
  String lateFormulaFixed(String symbol, String rate) {
    return 'Total Deduction = $symbol$rate (Fixed flat fee)';
  }

  @override
  String lateExampleFixed(int grace, String symbol, String rate) {
    return 'Example: Employee is 20 minutes late (past the ${grace}m grace). They are deducted exactly $symbol$rate.';
  }

  @override
  String get lateFormulaHalfDay =>
      'Total Deduction = Half-Day Salary (i.e. Daily Rate / 2)';

  @override
  String lateExampleHalfDay(String symbol, String amount) {
    return 'Example: Employee is 20 minutes late (past grace). Half day salary ($symbol$amount) is deducted.';
  }

  @override
  String earlyLeaveFormulaPerMinute(int grace, String rate) {
    return 'Total Deduction = (Early Leave Minutes - $grace) * (Hourly Rate / 60) * $rate (multiplier)';
  }

  @override
  String earlyLeaveExamplePerMinute(
    int grace,
    String symbol,
    String hourlyRate,
    String rate,
    String amount,
  ) {
    return 'Example (30 mins early): (30 - ${grace}m grace) * ($symbol$hourlyRate/60) * ${rate}x = $symbol$amount deducted.';
  }

  @override
  String earlyLeaveFormulaFixed(String symbol, String rate) {
    return 'Total Deduction = $symbol$rate (Fixed flat fee)';
  }

  @override
  String earlyLeaveExampleFixed(int grace, String symbol, String rate) {
    return 'Example: Employee leaves 20 minutes early (past the ${grace}m grace). They are deducted exactly $symbol$rate.';
  }

  @override
  String get earlyLeaveFormulaHalfDay =>
      'Total Deduction = Half-Day Salary (i.e. Daily Rate / 2)';

  @override
  String earlyLeaveExampleHalfDay(String symbol, String amount) {
    return 'Example: Employee leaves 20 minutes early (past grace). Half day salary ($symbol$amount) is deducted.';
  }

  @override
  String get overtimeCalcTitle => 'Overtime Calculation';

  @override
  String get overtimeDisabled => 'Overtime is currently disabled.';

  @override
  String get overtimeCalcDesc =>
      'Overtime payout is calculated by multiplying the active Hourly Rate by the OT hours worked and the respective day\'s multiplier.';

  @override
  String get otRegularWorkDay => 'Regular Work Day';

  @override
  String get otRestDay => 'Rest Day (Day Off)';

  @override
  String get otHoliday => 'Company / Public Holiday';

  @override
  String otFormulaRegular(String multiplier) {
    return 'OT Payout = OT Hours * Hourly Rate * $multiplier';
  }

  @override
  String otExampleRegular(
    String symbol,
    String hourlyRate,
    String multiplier,
    String amount,
  ) {
    return 'Example (2 hours OT): 2 hrs * $symbol$hourlyRate * ${multiplier}x = $symbol$amount total pay.';
  }

  @override
  String otExampleFullDay(
    String symbol,
    String hourlyRate,
    String multiplier,
    String amount,
  ) {
    return 'Example (8 hours worked): 8 hrs * $symbol$hourlyRate * ${multiplier}x = $symbol$amount total pay.';
  }

  @override
  String get earlyClockInPolicyTitle => 'Early Clock-in Policy';

  @override
  String get earlyClockInIgnoreFormula =>
      'Early clock-ins do NOT generate extra pay (Ignored in payroll).';

  @override
  String earlyClockInOtFormula(int maxMins, String multiplier) {
    return 'Early clock-ins are treated as OT.\nPayout = Early OT Hours (Max $maxMins mins) * Hourly Rate * $multiplier';
  }

  @override
  String earlyClockInOtExample(
    String symbol,
    String hourlyRate,
    String multiplier,
    String amount,
  ) {
    return 'Example (1 hr early): 1 hr * $symbol$hourlyRate * ${multiplier}x = $symbol$amount total pay.';
  }

  @override
  String get earlyClockInPaidOutsideFormula =>
      'Early clock-ins are paid manually outside of standard payroll.';

  @override
  String get financeSection => 'Finance';

  @override
  String get operationsSection => 'Operations';

  @override
  String get talentSection => 'Talent';

  @override
  String get systemSection => 'System';

  @override
  String get branchSection => 'Branch';

  @override
  String get morePayroll => 'Payroll';

  @override
  String get morePayrollDesc => 'Process runs';

  @override
  String get moreExpenses => 'Expenses';

  @override
  String get moreExpensesDesc => 'Review claims';

  @override
  String get moreShifts => 'Shifts';

  @override
  String get moreShiftsDesc => 'Work schedules';

  @override
  String get moreHolidays => 'Holidays';

  @override
  String get moreHolidaysDesc => 'Company holidays';

  @override
  String get moreAssets => 'Assets';

  @override
  String get moreAssetsDesc => 'Devices & stock';

  @override
  String get moreAnnouncements => 'Announcements';

  @override
  String get moreAnnouncementsDesc => 'Broadcast alerts';

  @override
  String get moreRecruitment => 'Recruitment';

  @override
  String get moreRecruitmentDesc => 'Jobs & candidates';

  @override
  String get morePerformance => 'Performance';

  @override
  String get morePerformanceDesc => 'Reviews & training';

  @override
  String get moreReports => 'Reports';

  @override
  String get moreReportsDesc => 'Analytics & exports';

  @override
  String get moreDocuments => 'Documents';

  @override
  String get moreDocumentsDesc => 'Company files';

  @override
  String get moreRoles => 'Roles';

  @override
  String get moreRolesDesc => 'Permissions';

  @override
  String get moreNotifications => 'Notifications';

  @override
  String get moreNotificationsDesc => 'View inbox';

  @override
  String get morePolicies => 'Policies';

  @override
  String get morePoliciesDesc => 'Rules & guidelines';

  @override
  String get moreHrStructure => 'HR Structure';

  @override
  String get moreHrStructureDesc => 'Depts & branches';

  @override
  String get logoutBtn => 'Logout';

  @override
  String get rolesPermissionsTitle => 'Roles & Permissions';

  @override
  String get noCustomRoles => 'No custom roles';

  @override
  String get createRoleTitle => 'Create Role';

  @override
  String get createBtn => 'Create';

  @override
  String get sendNotificationTitle => 'Send Notification';

  @override
  String get recipientLabel => 'Recipient';

  @override
  String get selectEmployeeHint => 'Select Employee';

  @override
  String get notificationTitleLabel => 'Notification Title';

  @override
  String get notificationTitleHint => 'E.g. Meeting at 3 PM';

  @override
  String get messageLabel => 'Message';

  @override
  String get messageHint => 'Write the message details here...';

  @override
  String get sendNotificationBtn => 'Send Notification';

  @override
  String get pleaseSelectEmployee => 'Please select an employee';

  @override
  String get notificationSentSuccess => '✅ Notification sent!';

  @override
  String get reportsTitle => 'Reports & Analytics';

  @override
  String get generateReportTitle => 'Generate Report';

  @override
  String get selectReportTypeHint => 'Select a report type to generate';

  @override
  String get generatingReport => 'Generating report...';

  @override
  String get filterToday => 'Today';

  @override
  String get filterWeek => 'Week';

  @override
  String get filterMonth => 'Month';

  @override
  String get filterYear => 'Year';

  @override
  String get reportEmployees => 'Employees';

  @override
  String get reportAttendance => 'Attendance';

  @override
  String get reportLeave => 'Leave';

  @override
  String get reportPayroll => 'Payroll';

  @override
  String get reportExpenses => 'Expenses';

  @override
  String get reportAssets => 'Assets';

  @override
  String get reportRecruitment => 'Recruitment';

  @override
  String get reportPerformance => 'Performance';

  @override
  String reportFoundRecords(int total) {
    return 'Found $total records';
  }

  @override
  String reportLabelSuffix(String label) {
    return '$label Report';
  }

  @override
  String get exportReportTooltip => 'Export Report';

  @override
  String get noRecordsFound => 'No records found for this period.';

  @override
  String get reportExportSuccess => '✅ Report exported successfully!';

  @override
  String reportExportFailed(String error) {
    return '❌ Export failed: $error';
  }

  @override
  String couldNotOpenFile(String message) {
    return 'Could not open file: $message';
  }

  @override
  String get holidaysTitle => 'Holidays';

  @override
  String get noHolidaysOnDay => 'No holidays on this day';

  @override
  String get addHoliday => 'Add Holiday';

  @override
  String get editHoliday => 'Edit Holiday';

  @override
  String get holidayNameLabel => 'Name *';

  @override
  String get holidayDateLabel => 'Date *';

  @override
  String get holidayTypeLabel => 'Type *';

  @override
  String get holidayTypeCompany => 'Company';

  @override
  String get holidayTypeNational => 'National (Cambodia)';

  @override
  String get holidayDescriptionLabel => 'Description';

  @override
  String get createHolidayBtn => 'Create Holiday';

  @override
  String get deleteHolidayTitle => 'Delete Holiday?';

  @override
  String deleteHolidayConfirm(String name) {
    return 'Are you sure you want to delete\n\"$name\"?\n\nThis action cannot be undone.';
  }

  @override
  String get holidayDeletedSuccess => '✅ Holiday deleted successfully';

  @override
  String get pleaseFillRequired => 'Please fill all required fields';

  @override
  String get nationalBadge => 'National';

  @override
  String get companyBadge => 'Company';

  @override
  String get policiesTitle => 'Policies';

  @override
  String get searchPoliciesHint => 'Search policies...';

  @override
  String get allStatus => 'All Status';

  @override
  String get statusArchived => 'Archived';

  @override
  String get allDepts => 'All Depts';

  @override
  String get loadingPolicies => 'Loading Policies...';

  @override
  String get noPoliciesFound => 'No policies found.';

  @override
  String get createPolicy => 'Create Policy';

  @override
  String get editPolicy => 'Edit Policy';

  @override
  String get policyTitleLabel => 'Title *';

  @override
  String get departmentLabel => 'Department';

  @override
  String get versionLabel => 'Version *';

  @override
  String get effectiveDateLabel => 'Effective Date';

  @override
  String get nextReviewDateLabel => 'Next Review Date (Optional)';

  @override
  String get contentLabel => 'Content *';

  @override
  String get updatePolicyBtn => 'Update Policy';

  @override
  String get createPolicyBtn => 'Create Policy';

  @override
  String policyEffectivePrefix(String date) {
    return 'Effective: $date';
  }

  @override
  String policyAcknowledged(int ack, int target) {
    return 'Acknowledged: $ack/$target';
  }

  @override
  String get viewBtn => 'View';

  @override
  String get publishBtn => 'Publish';

  @override
  String get archiveBtn => 'Archive';

  @override
  String get editBtn => 'Edit';

  @override
  String get deleteBtn => 'Delete';

  @override
  String deletePolicyConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get resourceDirectoryTitle => 'Resource Directory';

  @override
  String get tabShifts => 'Shifts';

  @override
  String get tabHolidays => 'Holidays';

  @override
  String get tabAnnouncements => 'Announce.';

  @override
  String get tabPolicies => 'Policies';

  @override
  String get tabDocs => 'Docs';

  @override
  String get noShifts => 'No shifts';

  @override
  String get noHolidays => 'No holidays';

  @override
  String get noAnnouncements => 'No announcements';

  @override
  String get noPolicies => 'No policies';

  @override
  String get noDocuments => 'No documents';

  @override
  String get addShiftTitle => 'Add Shift';

  @override
  String get shiftNameLabel => 'Name';

  @override
  String get shiftNameHint => 'e.g. Morning Shift';

  @override
  String get assignShiftTitle => 'Assign Shift';

  @override
  String get employeeIdLabel => 'Employee ID';

  @override
  String get assignBtn => 'Assign';

  @override
  String get shiftAssignedSuccess => '✅ Shift assigned';

  @override
  String get holidayCreatedSuccess => '✅ Holiday created';

  @override
  String get deletedSuccess => '✅ Deleted';

  @override
  String get documentDeletedSuccess => '✅ Document deleted';

  @override
  String get publishedStatus => 'Published';

  @override
  String get addHolidayTitle => 'Add Holiday';

  @override
  String get recurringBadge => 'Recurring';

  @override
  String fileSizeLabel(String size) {
    return 'Size: $size KB';
  }

  @override
  String deleteShiftConfirm(String name) {
    return 'Delete shift \"$name\"?';
  }

  @override
  String deleteHolidayConfirmSimple(String name) {
    return 'Delete holiday \"$name\"?';
  }

  @override
  String deleteDocumentConfirm(String title) {
    return 'Delete document \"$title\"?';
  }

  @override
  String get expenseClaimsTitle => 'Expense Claims';

  @override
  String get newClaimTooltip => 'New Claim';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get filterPaid => 'Paid';

  @override
  String get expenseApprovedSuccess => '✅ Expense approved';

  @override
  String get expenseMarkedPaidSuccess => '✅ Expense marked as paid';

  @override
  String get deleteClaimTitle => 'Delete Claim';

  @override
  String get deleteExpenseClaimConfirm =>
      'Delete this expense claim permanently?';

  @override
  String get claimDeletedSuccess => '✅ Claim deleted';

  @override
  String get rejectClaimTitle => 'Reject Claim';

  @override
  String get rejectClaimPrompt =>
      'Please provide a reason for rejecting this claim:';

  @override
  String get rejectionReasonLabel => 'Rejection Reason *';

  @override
  String get rejectionReasonHint => 'e.g. Invalid receipt, duplicate claim';

  @override
  String get rejectionReasonRequired => 'Rejection reason is required';

  @override
  String get rejectBtn => 'Reject';

  @override
  String get expenseRejectedSuccess => '✅ Expense rejected';

  @override
  String get reasonPrefix => 'Reason: ';

  @override
  String get paidPrefix => 'Paid: ';

  @override
  String get markAsPaidBtn => 'Mark as Paid';

  @override
  String get expenseDetailTitle => 'Expense Claim Details';

  @override
  String get employeeLabel => 'Employee';

  @override
  String get categoryLabel => 'Category';

  @override
  String get amountLabel => 'Amount';

  @override
  String get expenseDateLabel => 'Expense Date';

  @override
  String get statusPrefix => 'Status: ';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get paidAtLabel => 'Paid At';

  @override
  String get receiptLabel => 'Receipt';

  @override
  String get editExpenseClaimTitle => 'Edit Expense Claim';

  @override
  String get newExpenseClaimTitle => 'New Expense Claim';

  @override
  String get titleFieldLabel => 'Title *';

  @override
  String get categoryFieldLabel => 'Category *';

  @override
  String get catTravel => 'Travel';

  @override
  String get catMeals => 'Meals';

  @override
  String get catSupplies => 'Supplies';

  @override
  String get catSoftware => 'Software';

  @override
  String get catTransport => 'Transport';

  @override
  String get catAccommodation => 'Accommodation';

  @override
  String get catOther => 'Other';

  @override
  String get amountFieldLabel => 'Amount *';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get updateClaimBtn => 'Update Claim';

  @override
  String get submitClaimBtn => 'Submit Claim';

  @override
  String get expenseClaimUpdatedSuccess => '✅ Expense claim updated';

  @override
  String get expenseClaimSubmittedSuccess => '✅ Expense claim submitted';

  @override
  String get performanceTrainingTitle => 'Performance & Training';

  @override
  String get tabReviews => 'Reviews';

  @override
  String get tabTraining => 'Training';

  @override
  String get createReviewTitle => 'Create Review';

  @override
  String get editReviewTitle => 'Edit Review';

  @override
  String get reviewerRequired => 'Reviewer *';

  @override
  String get periodRequired => 'Period *';

  @override
  String get periodStartRequired => 'Period Start *';

  @override
  String get periodEndRequired => 'Period End *';

  @override
  String get reviewDateRequired => 'Review Date *';

  @override
  String get reviewTypeRequired => 'Review Type *';

  @override
  String get reviewTypeManager => 'Manager';

  @override
  String get reviewTypeSelf => 'Self';

  @override
  String get reviewTypePeer => 'Peer';

  @override
  String get reviewType360 => '360 Review';

  @override
  String get strengthsOptional => 'Strengths (optional)';

  @override
  String get areasForImprovementOptional => 'Areas for Improvement (optional)';

  @override
  String get goalsOptional => 'Goals (optional)';

  @override
  String get commentsOptional => 'Comments (optional)';

  @override
  String get statusSubmitted => 'Submitted';

  @override
  String get statusAcknowledged => 'Acknowledged';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get overallRatingPrefix => 'Overall Rating: ';

  @override
  String get periodHint => 'e.g. Q1 2024';

  @override
  String get deleteReviewTitle => 'Delete Review';

  @override
  String get deleteReviewConfirm => 'Delete this performance review?';

  @override
  String get reviewSavedSuccess => '✅ Review saved successfully';

  @override
  String get reviewDeletedSuccess => '✅ Review deleted';

  @override
  String get trainingMarkedCompletedSuccess => '✅ Training marked as completed';

  @override
  String get allPeriods => 'All Periods';

  @override
  String get noReviews => 'No reviews found.';

  @override
  String get notRated => 'Not Rated';

  @override
  String get loadingReviews => 'Loading Reviews...';

  @override
  String get createTrainingTitle => 'Create Training';

  @override
  String get editTrainingTitle => 'Edit Training';

  @override
  String get replaceCoverImage => 'Tap to replace cover image';

  @override
  String get uploadCoverImage => 'Tap to upload cover image';

  @override
  String get levelLabel => 'Level';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get statusOngoing => 'Ongoing';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get durationHours => 'Duration (Hours)';

  @override
  String get maxCapacity => 'Max Capacity';

  @override
  String get instructorName => 'Instructor Name';

  @override
  String get locationLink => 'Location / Link';

  @override
  String get startDateLabel => 'Start Date';

  @override
  String get endDateLabel => 'End Date';

  @override
  String get trainingDescription => 'Description';

  @override
  String get trainingContent => 'Content / Syllabus';

  @override
  String get trainingNotes => 'Internal Notes';

  @override
  String get loadingTrainings => 'Loading Trainings...';

  @override
  String get noTrainings => 'No trainings found.';

  @override
  String get deleteTrainingTitle => 'Delete Training';

  @override
  String get deleteTrainingConfirm => 'Delete this training course?';

  @override
  String get trainingSavedSuccess => '✅ Training saved successfully';

  @override
  String get trainingDeletedSuccess => '✅ Training deleted';

  @override
  String get searchTrainingsHint => 'Search trainings...';

  @override
  String get enrollmentsTitle => 'Enrollments';

  @override
  String get selectEmployeeToEnroll => 'Select Employee to Enroll';

  @override
  String get enrollBtn => 'Enroll';

  @override
  String get employeeEnrolledSuccess =>
      '🎉 Employee enrolled successfully & notification sent!';

  @override
  String get enrolledParticipantsTitle => 'Enrolled Participants';

  @override
  String get noEmployeesEnrolled => 'No employees enrolled yet.';

  @override
  String get progressLabel => 'Progress';

  @override
  String get noJobPostings => 'No job postings';

  @override
  String get loadingJobs => 'Loading jobs...';

  @override
  String get candidatesTitle => 'Candidates';

  @override
  String get locationServicesDisabled => 'Location services are disabled.';

  @override
  String get locationPermissionDenied => 'Location permission denied.';

  @override
  String get locationPermissionPermDenied =>
      'Location permissions are permanently denied.';

  @override
  String get locationUpdated => 'Location updated';

  @override
  String get couldNotFetchLocation => 'Could not fetch location';

  @override
  String get createJobTitle => 'Create Job Posting';

  @override
  String get editJobTitle => 'Edit Job Posting';

  @override
  String get basicInformationTitle => 'Basic Information';

  @override
  String get jobTitleRequired => 'Job Title *';

  @override
  String get positionLabel => 'Position';

  @override
  String get employmentTypeLabel => 'Employment Type';

  @override
  String get employmentFullTime => 'Full Time';

  @override
  String get employmentPartTime => 'Part Time';

  @override
  String get employmentContract => 'Contract';

  @override
  String get employmentInternship => 'Internship';

  @override
  String get jobDetailsTitle => 'Job Details';

  @override
  String get descriptionRequired => 'Description *';

  @override
  String get requirementsLabel => 'Requirements';

  @override
  String get responsibilitiesLabel => 'Responsibilities';

  @override
  String get locationAndSalaryTitle => 'Location & Salary';

  @override
  String get minSalary => 'Min Salary';

  @override
  String get maxSalary => 'Max Salary';

  @override
  String get jobStatusLabel => 'Job Status';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusClosed => 'Closed';

  @override
  String get statusFilled => 'Filled';

  @override
  String get titleAndDescRequired => 'Title and description required';

  @override
  String get publishJobPosting => 'Publish Job Posting';

  @override
  String get updateJobPosting => 'Update Job Posting';

  @override
  String get noCandidatesApplied => 'No candidates applied yet.';

  @override
  String get loadingCandidates => 'Loading candidates...';

  @override
  String get yearsExp => 'yrs exp';

  @override
  String get expectedSalaryLabel => 'Exp';

  @override
  String get viewResumeBtn => 'View Resume';

  @override
  String get stageLabel => 'Stage';

  @override
  String get stageApplied => 'Applied';

  @override
  String get stageScreening => 'Screening';

  @override
  String get stageInterview => 'Interview';

  @override
  String get stageOffer => 'Offer';

  @override
  String get stageHired => 'Hired';

  @override
  String get stageRejected => 'Rejected';

  @override
  String get companyAssetsTitle => 'Company Assets';

  @override
  String get noAssetsFound => 'No assets found';

  @override
  String get addFirstAssetDesc => 'Add your first company asset to get started';

  @override
  String get addAssetBtn => 'Add Asset';

  @override
  String get editAssetTitle => 'Edit Asset';

  @override
  String get addNewAssetTitle => 'Add New Asset';

  @override
  String get fillInDetailsDesc => 'Fill in the details below';

  @override
  String get basicDetailsTitle => 'Basic Details';

  @override
  String get assetCodeRequired => 'Asset Code *';

  @override
  String get conditionLabel => 'Condition';

  @override
  String get conditionNew => 'New';

  @override
  String get conditionGood => 'Good';

  @override
  String get conditionFair => 'Fair';

  @override
  String get conditionPoor => 'Poor';

  @override
  String get conditionDamaged => 'Damaged';

  @override
  String get financialDetailsTitle => 'Financial Details';

  @override
  String get purchasePriceLabel => 'Purchase Price';

  @override
  String get currentValueLabel => 'Current Value';

  @override
  String get depreciationMonthsLabel => 'Depreciation (Months)';

  @override
  String get purchaseDateLabel => 'Purchase Date';

  @override
  String get warrantyExpiryLabel => 'Warranty Expiry';

  @override
  String get additionalNotesTitle => 'Additional Notes';

  @override
  String get assetCodeAndNameRequired => 'Asset Code and Name are required';

  @override
  String get assetUpdatedSuccess => 'Asset updated successfully';

  @override
  String get assetCreatedSuccess => 'Asset created successfully';

  @override
  String get createAssetBtn => 'Create Asset';

  @override
  String get assignAssetTitle => 'Assign Asset';

  @override
  String get transferAssetDesc => 'Transfer asset to an employee';

  @override
  String get assignToEmployeeRequired => 'Assign To Employee *';

  @override
  String get conditionAtAssignmentLabel => 'Condition at Assignment';

  @override
  String get conditionNoteHint => 'Note any scratches or damage...';

  @override
  String get assetAssignedSuccess => 'Asset assigned successfully';

  @override
  String get confirmAssignmentBtn => 'Confirm Assignment';

  @override
  String get deleteAssetTitle => 'Delete Asset';

  @override
  String deleteAssetConfirm(String name, String code) {
    return 'Delete \"$name\" ($code)?';
  }

  @override
  String get returnAssetTitle => 'Return Asset';

  @override
  String returnAssetConfirm(String name) {
    return 'Mark \"$name\" as returned?';
  }

  @override
  String get assetReturnedSuccess => 'Asset returned';

  @override
  String get assetDeletedSuccess => 'Asset deleted';

  @override
  String get totalAssetsLabel => 'Total Assets';

  @override
  String get totalValueLabel => 'Total Value';

  @override
  String get assignedLabel => 'Assigned';

  @override
  String get valueLabel => 'Value';

  @override
  String assignedToLabel(String name) {
    return 'Assigned to: $name';
  }

  @override
  String get warrantyExpired => 'Warranty Expired';

  @override
  String get warrantyExpiringSoon => 'Warranty Expiring Soon';

  @override
  String get returnBtn => 'Return';

  @override
  String get assignmentHistoryTitle => 'Assignment History';

  @override
  String get noAssignmentHistory => 'No assignment history';

  @override
  String get noAssignmentHistoryDesc =>
      'This asset has never been assigned to anyone.';

  @override
  String assignedDateLabel(String date) {
    return 'Assigned: $date';
  }

  @override
  String returnedDateLabel(String date) {
    return 'Returned: $date';
  }

  @override
  String notesLabel(String notes) {
    return 'Notes: $notes';
  }

  @override
  String get hrStructureTitle => 'HR Structure';

  @override
  String get tabBranches => 'Branches';

  @override
  String get tabDepts => 'Depts';

  @override
  String get tabPositions => 'Positions';

  @override
  String get tabTeams => 'Teams';

  @override
  String get tabOrgChart => 'Org Chart';

  @override
  String get searchBranchesHint => 'Search branches...';

  @override
  String get loadingBranches => 'Loading branches...';

  @override
  String get failedToLoadBranches => 'Failed to load branches';

  @override
  String get noBranchesFound => 'No branches found matching your search.';

  @override
  String get noBranchesFoundDesc =>
      'Try adjusting your filters or search query.';

  @override
  String get noBranchesAvailable => 'No branches available';

  @override
  String get addFirstBranchDesc => 'Add your first branch to get started';

  @override
  String get addBranchBtn => 'Add Branch';

  @override
  String get deleteBranchTitle => 'Delete Branch';

  @override
  String deleteBranchConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get searchDeptsHint => 'Search depts...';

  @override
  String get loadingDepts => 'Loading departments...';

  @override
  String errorLoadingDepts(String error) {
    return 'Error loading depts: $error';
  }

  @override
  String get noDeptsFound => 'No departments found';

  @override
  String get failedToLoadDepts => 'Failed to load departments';

  @override
  String get addFirstDeptDesc => 'Add your first department to get started';

  @override
  String get addDeptBtn => 'Add Department';

  @override
  String get deleteDeptTitle => 'Delete Department';

  @override
  String deleteDeptConfirm(String name) {
    return 'Delete department $name?';
  }

  @override
  String get searchRolesHint => 'Search roles...';

  @override
  String get noRolesFound => 'No roles found';

  @override
  String get failedToLoadPositions => 'Failed to load positions';

  @override
  String get addFirstRoleDesc => 'Add your first role to get started';

  @override
  String get addRoleBtn => 'Add Role';

  @override
  String get searchTeamsHint => 'Search teams...';

  @override
  String get loadingTeams => 'Loading teams...';

  @override
  String get noTeamsFound => 'No teams found';

  @override
  String get failedToLoadTeams => 'Failed to load teams';

  @override
  String get addFirstTeamDesc => 'Add your first team to get started';

  @override
  String get addTeamBtn => 'Add Team';

  @override
  String get deleteTeamTitle => 'Delete Team';

  @override
  String deleteTeamConfirm(String name) {
    return 'Delete team $name?';
  }

  @override
  String get searchOrgChartHint => 'Search name, position, dept...';

  @override
  String get loadingOrgChart => 'Loading org chart...';

  @override
  String get failedToLoadOrgChart => 'Failed to load org chart';

  @override
  String get noDataOrgChart => 'No org chart data';

  @override
  String get noOrgChartTitle => 'No organisation structure yet';

  @override
  String get noOrgChartDesc =>
      'Add employees and assign managers to build your org chart.';

  @override
  String orgChartStats(int count, int levels) {
    return '$count people · $levels levels';
  }

  @override
  String get expandAll => 'Expand All';

  @override
  String get showLevel1 => 'Show 1 Level';

  @override
  String get showLevel2 => 'Show 2 Levels';

  @override
  String get showLevel3 => 'Show 3 Levels';

  @override
  String get showLevel4 => 'Show 4 Levels';

  @override
  String get showLevel5 => 'Show 5 Levels';

  @override
  String get branchNameLabel => 'Branch Name';

  @override
  String get branchCodeLabel => 'Branch Code';

  @override
  String get branchManagerLabel => 'Branch Manager';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get allowedRadiusLabel => 'Allowed Radius (meters)';

  @override
  String get getCurrentLocationBtn => 'Get Current Location';

  @override
  String get customPayrollSettingsTitle => 'Custom Payroll Settings';

  @override
  String get customPayrollSettingsDesc =>
      'Override company-wide overtime and late rules';

  @override
  String get workingDaysCalcTitle => 'Working Days Calculation';

  @override
  String get calcTypeLabel => 'Calculation Type';

  @override
  String get fixedDaysPerMonthLabel => 'Fixed Days per Month';

  @override
  String get overtimeMultipliersTitle => 'Overtime Multipliers';

  @override
  String get regularOtLabel => 'Regular OT';

  @override
  String get restDayOtLabel => 'Rest Day OT';

  @override
  String get publicHolOtLabel => 'Public Hol. OT';

  @override
  String get companyHolOtLabel => 'Company Hol. OT';

  @override
  String get latePenaltiesTitle => 'Late Penalties';

  @override
  String get graceMinsLabel => 'Grace Mins';

  @override
  String get dedRateLabel => 'Ded. Rate';

  @override
  String get dedTypeLabel => 'Deduction Type';

  @override
  String get perMinuteLabel => 'Per Minute';

  @override
  String get fixedAmountLabel => 'Fixed Amount';

  @override
  String get ignorePolicyLabel => 'Ignore (No extra pay)';

  @override
  String get treatAsOtPolicyLabel => 'Treat as OT';

  @override
  String get paidOutsidePolicyLabel => 'Paid Outside (No OT multiplier)';

  @override
  String get preShiftOtMultLabel => 'Pre-Shift OT Mult.';

  @override
  String get maxMinsAllowedLabel => 'Max Mins Allowed';

  @override
  String get overrideGracePeriodLabel => 'Override Grace Period (minutes)';

  @override
  String get deptNameLabel => 'Department Name';

  @override
  String get deptCodeLabel => 'Department Code';

  @override
  String get officeBranchLabel => 'Office Branch';

  @override
  String get noBranchLabel => 'No Branch';

  @override
  String get parentDeptLabel => 'Parent Department';

  @override
  String get noParentLabel => 'No Parent (Root)';

  @override
  String get deptManagerLabel => 'Department Manager';

  @override
  String get noManagerLabel => 'No Manager';

  @override
  String get roleTitleLabel => 'Role Title';

  @override
  String get roleCodeLabel => 'Role Code';

  @override
  String get noDeptLabel => 'No Department (General)';

  @override
  String get jobSeniorityLevelLabel => 'Job Seniority Level';

  @override
  String get noLevelLabel => 'No Level specified';

  @override
  String get teamNameLabel => 'Team Name';

  @override
  String get teamLeaderLabel => 'Team Leader';

  @override
  String get noLeaderLabel => 'No Leader Assigned';

  @override
  String get activeStatusTitle => 'Active Status';

  @override
  String get allowAssignRolesDesc => 'Allow assigning employees to this role';

  @override
  String get allowAssignTeamsDesc => 'Allow assigning employees to this team';

  @override
  String get allDepartmentsLabel => 'All Departments';

  @override
  String get allDeptsLabel => 'All Depts';

  @override
  String get allBranchesLabel => 'All Branches';

  @override
  String get loadingLabel => 'Loading...';

  @override
  String get unpublishBtn => 'Unpublish';

  @override
  String get deleteTitle => 'Delete';

  @override
  String get announcementPublished => '✅ Announcement published';

  @override
  String get announcementUnpublished => '✅ Announcement unpublished';

  @override
  String get operationSuccess => '✅ Operation successful';

  @override
  String get myShift => 'My Shift';

  @override
  String get recentPayslip => 'Recent Payslip';

  @override
  String get pendingExpenses => 'Pending Expenses';

  @override
  String get noUpcomingLeaves => 'No upcoming leaves approved.';

  @override
  String get noRecentAttendance => 'No recent attendance records.';

  @override
  String get myLearning => 'My Learning';

  @override
  String get viewAll => 'View All';

  @override
  String get available => 'Available';

  @override
  String get latest => 'Latest';

  @override
  String get progress => 'Progress';

  @override
  String get days => 'Days';

  @override
  String get today => 'Today';

  @override
  String get companyRules => 'Company Rules';

  @override
  String get companyRulesDesc =>
      'A transparent guide to your branch\'s configured payroll, attendance, and overtime rules.';

  @override
  String get viewingRulesFor => 'Viewing rules for';

  @override
  String get noCompanyRules => 'No company rules configured.';

  @override
  String get viewCompanyDocuments => 'Access company guidelines and forms';

  @override
  String get readAndAcknowledge => 'Read and acknowledge policies';

  @override
  String get payrollAttendanceRules => 'Payroll, attendance & OT rules';
}
