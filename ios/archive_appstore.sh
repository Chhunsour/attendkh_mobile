#!/bin/bash
# App Store archive + export for com.attendkh.app (team AX5SUA48CM).
#
# Why not plain `flutter build ipa`:
#   Automatic signing asks Apple for an iOS App *Development* profile at archive
#   time (Release inherits CODE_SIGN_IDENTITY = "Apple Development"), and this
#   team has no registered devices. Switching to manual signing fails too,
#   because the only local App Store profile is Xcode-managed and Xcode rejects
#   Xcode-managed profiles under manual signing.
# So: archive unsigned, sign the archive with the distribution identity +
# entitlements, then let `xcodebuild -exportArchive` produce the IPA.
#
# ponytail: delete this whole script and use `flutter build ipa` once a
# *manually managed* App Store profile for com.attendkh.app is installed —
# then CODE_SIGN_STYLE=Manual works and none of this is needed.
set -euo pipefail
cd "$(dirname "$0")"
ROOT=".."
ARCHIVE="$ROOT/build/ios/archive/Runner.xcarchive"
IDENTITY="8FDDCBC491AC1A52D9AA5105B6F6781512A53F63"   # Apple Distribution: Chhunsour Seng (AX5SUA48CM)
PROFILE="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles/61ebddee-a77e-43fc-b494-6150293dc178.mobileprovision"

rm -rf "$ROOT/build/ios/archive" "$ROOT/build/ios/ipa"
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ROOT/build/ios/archive/Runner" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" archive

APP="$ARCHIVE/Products/Applications/Runner.app"
cp "$PROFILE" "$APP/embedded.mobileprovision"
find "$APP/Frameworks" -maxdepth 1 -name "*.framework" -print0 \
  | xargs -0 -I{} codesign -f -s "$IDENTITY" -o runtime {}
codesign -f -s "$IDENTITY" --entitlements Runner/Runner.entitlements "$APP"
/usr/libexec/PlistBuddy -c "Set :ApplicationProperties:SigningIdentity Apple Distribution: Chhunsour Seng (AX5SUA48CM)" \
  -c "Set :ApplicationProperties:Team AX5SUA48CM" "$ARCHIVE/Info.plist"

xcodebuild -exportArchive -archivePath "$ARCHIVE" \
  -exportOptionsPlist ExportOptions.plist -exportPath "$ROOT/build/ios/ipa" \
  -allowProvisioningUpdates
