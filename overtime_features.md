# Overtime Clock In/Out Feature Plan

This document outlines the required tasks to implement the Overtime Clock In/Out functionality for tomorrow's development session.

## 1. Backend Updates (mpg-hr-web-system)
Although the endpoints for overtime already exist (`POST /api/company/attendance/overtime-in` and `overtime-out`), they need to be verified to ensure they return the expected data format.
- [ ] Verify `AttendanceController@overtimeIn` correctly processes geofencing and saves the timestamp.
- [ ] Verify `AttendanceController@overtimeOut` correctly calculates `overtime_minutes` and saves the checkout time.
- [ ] Ensure the backend allows overtime even if a user clocked out early during their regular shift.
- [ ] Expose `overtime_in` and `overtime_out` properties securely to the API response so the mobile app can read them.

## 2. Mobile Data Models & Repository (mpg-hr-mobile-app)
The mobile app currently lacks the methods to interact with the overtime endpoints.
- [ ] Update `TodayAttendance` model to include `overtimeIn` and `overtimeOut` fields.
- [ ] Add `overtimeIn({lat, lng, deviceId, photoPath})` method to `AttendanceRepository`.
- [ ] Add `overtimeOut({lat, lng, deviceId, photoPath})` method to `AttendanceRepository`.

## 3. Mobile UI Updates (Dashboard)
The dashboard currently hides the clocking button completely once `isCompleted` (clocked out) is true. We need to introduce a new state for Overtime.
- [ ] **State Logic Update**: Modify `_buildClockCard` in `dashboard_screen.dart` to check if regular shift is completed AND if the current time is **after the shift end time** (e.g., 5:00 PM). 
- [ ] **Delayed Overtime Appearance**: If a user clocks out early (e.g., 3:00 PM), the overtime button should remain hidden. Once the clock hits their official shift end time (5:00 PM), the **"Swipe to Clock In (Overtime)"** button will become visible.
- [ ] **Overtime Clock In Button**: Show a distinct button (perhaps a different color, like purple or deep orange) saying **"Swipe to Clock In (Overtime)"**.
- [ ] **Overtime Clock Out Button**: If `overtimeIn` is set but `overtimeOut` is null, show **"Swipe to Clock Out (Overtime)"**.
- [ ] **Completed State**: If both `overtimeIn` and `overtimeOut` are set, show a final completion message: *"Overtime Completed"*.

## 4. UI Polish & Testing
- [ ] Update the `_handleSimpleClockOut` equivalent for Overtime (with specific popup confirmation dialogs).
- [ ] Test the full daily lifecycle: Clock In -> Clock Out -> Overtime In -> Overtime Out.
- [ ] Verify that UI handles edge cases (e.g., trying to start overtime without having clocked out of the regular shift first).
