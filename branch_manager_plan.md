# Branch Manager Role: Implementation Plan

Adding a **Branch Manager** role is a massive upgrade for an HR system. It decentralizes management, taking the load off HR and the Super Admin by allowing local managers to handle their own teams.

## 1. What Can a Branch Manager Do? (Capabilities)

Here is a recommended feature set for the Branch Manager role:

### ✅ Permitted Actions
*   **Attendance Tracking:** View attendance logs, late reports, and overtime records *only for employees in their specific branch*.
*   **Approvals:** Approve or reject Leave Requests and Expense Claims submitted by employees in their branch.
*   **Shift Management:** Assign shifts and manage the working schedules for their branch staff.
*   **Notifications:** Receive the notifications (like the Late Warning or Leave Submitted notifications) when triggered by an employee in their branch.

### ❌ Restricted Actions (What they CANNOT do)
*   **Global Settings:** Cannot change company-wide payroll rules, holiday calendars, or global geofencing settings.
*   **Cross-Branch Visibility:** Cannot see data, salaries, or attendance for employees in other branches.
*   **System Admin:** Cannot delete the company account or add other Admins.

---

## 2. Technical Implementation Plan

If you agree with the capabilities above, here is how we will build it:

### Phase 1: Roles & Permissions (Backend)
*   **Seeder Update:** Add the `branch_manager` role using the Spatie Permission package (which your backend is currently using).
*   **Permissions:** Create specific permissions like `manage-branch-attendance`, `approve-branch-leaves`, and `manage-branch-shifts`, and assign them to this new role.
*   **User Assignment:** Update the user creation/edit API to allow Admins to assign the `branch_manager` role to a user and link them to a specific `branch_id`.

### Phase 2: Data Scoping (Security)
*   **Query Scopes:** Update the backend controllers (e.g., `AttendanceController`, `LeaveRequestController`). 
    *   *Logic:* If the user is an `admin`, return all records. If the user is a `branch_manager`, filter the database queries to only return records where the `employee.branch_id` matches the manager's `branch_id`.

### Phase 3: Mobile / Web UI Updates
*   **Manager Dashboard (Mobile App):** Add a special "Manager View" or "Team" tab on the mobile app that only appears for users with the `branch_manager` role. This tab will show pending Leave/Expense approvals for their team.
*   **Action Buttons:** Ensure the "Approve/Reject" buttons are visible to Branch Managers for their team's requests.

---

> **Next Steps:** Review the capabilities listed in Section 1. Are there any other specific tasks you want the Branch Manager to handle (e.g., Payroll generation for their branch)? Let me know and we can refine this plan!
