cd /Users/rohitsainier/Documents/Apple/CaptionsApp

# Clean and build with ad-hoc signing
xcodebuild clean build \
  -project Subs.xcodeproj \
  -scheme Subs \
  -configuration Release \
  -derivedDataPath ./build

# Ad-hoc sign the app
codesign --force --deep --sign - ./build/Build/Products/Release/Subs.app

# Create DMG staging folder
mkdir -p dmg_staging
cp -R ./build/Build/Products/Release/Subs.app dmg_staging/
ln -s /Applications dmg_staging/Applications

# Create DMG
hdiutil create -volname "Subs" \
  -srcfolder ./dmg_staging \
  -ov \
  -format UDZO \
  ~/Desktop/Subs.dmg

# Clean up
rm -rf dmg_staging

echo "DMG created at ~/Desktop/Subs.dmg"