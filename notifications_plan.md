# System-Wide Notifications Implementation Plan

This document outlines the master plan for implementing the remaining core notifications across the MPG HR system. We will tackle these in phases, starting with the most critical workflows.

## Phase 1: Core Workflow Notifications
These are the notifications that directly impact daily operations and reduce HR friction.

### 1. Leave Management Notifications
*   **Target:** `LeaveRequestController.php` & `LeaveService.php`
*   **Actions:**
    *   Create `LeaveRequestSubmittedNotification` (Sent to Managers/HR when an employee applies).
    *   Create `LeaveStatusUpdatedNotification` (Sent to Employee when approved/rejected).
    *   **Logic:** Trigger these notifications upon creation and status update of a `LeaveRequest`.

### 2. Expense Claim Notifications
*   **Target:** `ExpenseController.php` & `ExpenseService.php`
*   **Actions:**
    *   Create `ExpenseSubmittedNotification` (Sent to Finance/Admin).
    *   Create `ExpenseStatusUpdatedNotification` (Sent to Employee on approval/rejection/reimbursement).
    *   **Logic:** Trigger on creation and status update of an `ExpenseClaim`.

### 3. Payroll Notifications
*   **Target:** `PayslipController.php` or `PayrollService.php`
*   **Actions:**
    *   Create `NewPayslipAvailableNotification` (Sent to Employee).
    *   **Logic:** Trigger when a payslip is generated or explicitly "published" by HR.

---

## Phase 2: Automated Reminders (Scheduled Jobs)
These notifications require scheduled tasks (cron jobs) running on the backend to check conditions based on time.

### 4. Attendance Reminders
*   **Target:** Laravel Console Kernel (`app/Console/Kernel.php`)
*   **Actions:**
    *   Create a daily scheduled command: `php artisan schedule:run`.
    *   **Clock-in Reminder:** Check if the current time is 5 minutes before shift start, and if the employee hasn't clocked in, send `ClockInReminderNotification`.
    *   **Clock-out Reminder:** Check if the current time is past shift end, and if the employee hasn't clocked out, send `ClockOutReminderNotification`.

### 5. Training Reminders
*   **Target:** Laravel Console Kernel
*   **Actions:**
    *   Check for `TrainingEnrollment` records where the deadline is within 3 days and `progress_percentage < 100`.
    *   Send `TrainingDeadlineReminderNotification`.

---

## Frontend Integration (Mobile App)
To fully utilize these backend notifications, the mobile app needs to be able to display them.

1.  **Notification Screen:**
    *   Create a new screen (`notification_screen.dart`) to fetch and display a list of notifications from the backend (`GET /api/user/notifications`).
2.  **Dashboard Icon:**
    *   Add a bell icon to the `DashboardScreen` AppBar with an unread badge count.
3.  **Push Notifications (Future Enhancement):**
    *   Integrate Firebase Cloud Messaging (FCM) to deliver these Laravel notifications natively to the iOS/Android devices as push notifications.
