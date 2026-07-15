# Owner "Switch to Branch" Feature Plan

## What do I think about this feature?
This is a **fantastic** idea! In enterprise software, this is often called "Role Impersonation" or "View As". 

It is incredibly useful because:
1.  **Troubleshooting:** The Owner can see *exactly* what the Branch Manager sees, making it easy to guide them or fix issues.
2.  **Coverage:** If a Branch Manager is sick or on leave, the Owner can instantly switch into their view to approve leaves and manage shifts without needing to create a dummy account.
3.  **Clean UX:** It keeps the Owner's main dashboard clean and high-level, while allowing them to drill down into a specific branch when needed.

---

## Technical Implementation Plan

Here is how we can build this feature with the premium UI transition you described:

### 1. Backend Logic (`mpg-hr-web-system`)
We have two ways to do this on the backend:
*   **Option A (Frontend Driven - Recommended):** The backend APIs for "Manager Dashboard" accept an optional `?branch_id=X` parameter. If an Owner passes this parameter, the backend returns data *only* for that branch.
*   **Option B (Session Driven):** Create an endpoint `POST /api/company/switch-branch` that temporarily saves the `active_branch_id` in the user's session or token context.

### 2. Mobile App UI (`mpg-hr-mobile-app`)
*   **Branch Selector:** On the Owner's main dashboard, add a sleek dropdown or bottom sheet button labeled **"View as Branch Manager"**. Tapping this shows a list of their branches.
*   **The Transition (Blur & Loading):** When they select a branch, we trigger the transition:
    *   We use Flutter's `BackdropFilter` with `ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0)` to create a smooth, frosted glass blur over the entire screen.
    *   In the center of the blurred screen, we place a custom, styled `CircularProgressIndicator`.
*   **State Update:** While the loading spinner is active, the app fetches the selected branch's data.
*   **Navigation:** Once the data is loaded (or after a 1.5-second minimum delay for a premium feel), the blur fades away, and the app pushes the `BranchManagerDashboardScreen`, populated with that specific branch's data.
*   **Floating "Switch Back" Button:** When they are in the Branch Manager view, there should be a floating button or a prominent banner at the top saying *"Viewing as [Branch Name] - Tap to Exit"* so they can easily return to their Owner dashboard.

### 3. Web System UI
*   Similar to the mobile app, we can add a branch selector in the top navigation bar for Owners.
*   When a branch is selected, a full-screen CSS blur overlay (e.g., `backdrop-filter: blur(8px)`) is applied with a central loading spinner while the dashboard data re-fetches for the specific branch context.
