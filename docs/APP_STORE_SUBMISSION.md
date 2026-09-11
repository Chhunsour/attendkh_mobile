# AttendKH — App Store Connect submission prep (rejection v1.0 (1), ITMS-90683 on build (2))

STATUS: applied. App 6809346156, version 1.0, state PREPARE_FOR_SUBMISSION.
Nothing has been submitted to Apple. See "What is left to click" at the end.

## What was applied via the App Store Connect API

- Description: removed the closing "visit attendkh.com to get started"
  sentence, replaced with an EXISTING ACCOUNTS ONLY paragraph stating the app
  is sign-in only with no registration, purchases or subscriptions.
  No occurrence of attendkh.com remains in the description.
- Promotional Text: rewritten around "employer-issued account".
- Marketing URL: cleared (was https://attendkh.com).
- Support URL: kept as https://attendkh.com/support (required field).
- Keywords: unchanged - already free of signup/pricing terms.
- What's New: not editable on a first version (Apple 409) - correctly absent.
- App Review Notes: rewritten. Leads with the 3.2 / 3.1.1 / registration
  rebuttal, then demo account, GPS geofence explanation, walkthrough and
  permissions. 3062 characters.
- Demo account: appreview@attendkh.com, verified working against
  POST https://dashboard.attendkh.com/api/login (HTTP 200, hr_manager role,
  company "AttendKH Demo").
- Build 1.0.0 (2) uploaded with altool, processed VALID, attached to
  version 1.0. Superseded by build (3), see the ITMS-90683 section below.
  Export compliance is exempt via ITSAppUsesNonExemptEncryption.
- Screenshots reviewed (iPhone 6.5" and 6.7", 5 each): all post-login feature
  screens. No Create Account button, no pricing, no subscription, no
  attendkh.com URL. No change needed.
- Pricing and Availability: Free, Cambodia only, distribution method Public
  (unchanged - unlisted is granted by Apple through the request form, not by a
  toggle here).

## ITMS-90683 (build 2) -> fixed in build 1.0.0 (3)

Apple accepted build 2 but warned: "Missing
NSLocationAlwaysAndWhenInUseUsageDescription in Runner.app Info.plist".

Root cause: AttendKH never requests Always/background location. Every call site
(employee dashboard clock-in, branch geofence editor, admin company editor,
job form) uses Geolocator.requestPermission -> requestWhenInUseAuthorization
only, and UIBackgroundModes contains only remote-notification. But
geolocator_apple 2.3.14 compiles an unreachable `requestAlwaysAuthorization`
fallback into its binary (PermissionHandler.m, the `else` branch taken only
when NSLocationWhenInUseUsageDescription is absent). Apple's static analysis
scans linked APIs, not reachable ones, so the dead code demanded the key.

Fix, both halves:

1. ios/Podfile post_install defines `BYPASS_PERMISSION_LOCATION_ALWAYS=1`,
   the macro geolocator_apple ships for exactly this. The Always path is
   compiled out. `strings` on the shipped IPA confirms zero
   `requestAlwaysAuthorization` references across Runner and every embedded
   framework; `requestWhenInUseAuthorization` is still present in
   geolocator_apple.framework, so clock-in geofence verification is untouched.
   (permission_handler_apple's location strategy was already compiled out -
   PERMISSION_LOCATION stays 0; only CAMERA and NOTIFICATIONS are on.)
2. Both purpose strings are declared in ios/Runner/Info.plist anyway, so the
   binary satisfies Apple's analysis regardless of how it is run:

   NSLocationWhenInUseUsageDescription
     "AttendKH uses your location only while the app is open, at the moment
      you tap Clock In or Clock Out, to confirm you are inside your employer's
      approved workplace area and to record that verified attendance. Your
      location is not collected in the background and is never used for
      advertising or tracking."

   NSLocationAlwaysAndWhenInUseUsageDescription
     "AttendKH does not track your location in the background. Location is
      used only while the app is open, when you clock in or out, to confirm
      you are inside your employer's approved workplace area for attendance.
      It is never used for advertising or tracking."

Verified on the FINAL artifact, not the source plist: both keys read back out
of build/ios/ipa/AttendKH.ipa -> Payload/Runner.app/Info.plist, alongside
CFBundleVersion 3 and CFBundleIdentifier com.attendkh.app.
`altool --validate-app` returned VERIFY SUCCEEDED with no errors, upload
succeeded (delivery eeb5a068-6987-4fdc-8b29-ee8aa342a67d) and build 3 reached
processingState VALID.

Build 3 is uploaded, processed VALID, and ATTACHED to version 1.0 (replacing
build 2) via PATCH /v1/appStoreVersions/{id}/relationships/build. Export
compliance carries over: usesNonExemptEncryption = false. Version 1.0 is still
PREPARE_FOR_SUBMISSION - NOTHING has been submitted.

## Unlisted App Distribution request

Form: https://developer.apple.com/contact/request/unlisted-app/
Filled and left open in the browser, NOT submitted. Values used:

- Organization type: Business
- App Name: AttendKH · Apple ID: 6809346156 · Submitted for review: Yes
- Distributed: Externally
- People: 500 · Organizations: 10  <-- ESTIMATES, correct before sending
- Designed for: Full-time employees, Part-time employees
- Category: Employee logistics (timecard, shift scheduling, badge reader)
- Devices: Unmanaged, 500  <-- ESTIMATE, correct before sending
- Regions: Cambodia
- The three justification texts explain the sign-in-only model, why public
  discoverability is useless and harmful for a workplace app, and why Apple
  Business Manager custom apps do not work for SMB customers in Cambodia.
- The final acknowledgement checkbox is deliberately left unticked.

## Residual risk worth knowing

attendkh.com pages all share a site nav containing "Pricing" and
"Get Started". The Support URL is a required field and points there. Apple's
3.1.1 finding was about the description, which is now clean, but a support
page without a pricing nav would remove the last bit of exposure.

## What is left to click

1. Unlisted request tab: correct the three numbers, tick the acknowledgement
   checkbox, click Submit.
2. App Store Connect version 1.0 page: Add for Review / Submit for Review.

Build selection is DONE - no longer a manual step.
