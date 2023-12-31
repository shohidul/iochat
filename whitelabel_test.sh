#! /bin/bash

# whitelabel_test_script

DEFAULT_BUNDLE_ID_IOS="org.iochat.app"

# envirowater:
APP_NAME="IO Chat"
SHORT_NAME="iochat"
URL_SCHEME="iochat"
SHARE_PATH="/share"
BASE_URL="iochat.netlify.app"
APP_HOST="app.iochat.com"
CUSTOM_DOMAINS=$(cat ./app_client/$SHORT_NAME/domains.txt 2>/dev/null || echo $APP_HOST)
BUILD_NAME=1.0.0
PACKAGE_NAME="app.iochat.com"
BUNDLE_ID_ANDROID="app.iochat.com"
BUNDLE_ID_IOS="app.iochat.com"
APPLICATION_APPLE_ID=123456789 
BEHIND_APP_BAR="false"

# viadesk:
# APP_NAME="Viadesk_test"
# SHORT_NAME="viadesk"
# URL_SCHEME="viadesk"
# SHARE_PATH="/do/sharetoiochat"
# BASE_URL="login.viadesk.com"
# APP_HOST="*.viadesk.com"
# CUSTOM_DOMAINS=$(cat ./app_client/viadesk/domains.txt 2>/dev/null || echo $APP_HOST)
# BUILD_NAME=5.0.1
# PACKAGE_NAME="com.viadesk.app"
# BUNDLE_ID_ANDROID="com.viadesk.app"
# BUNDLE_ID_IOS="com.viadesk.Viadesk"
# APPLICATION_APPLE_ID=455647635
# BEHIND_APP_BAR="false"

#fellow
# APP_NAME="Fellow_test"
# SHORT_NAME="fellow"
# URL_SCHEME="dorsia"
# SHARE_PATH:"/share"
# BASE_URL="login.coursepath.com"
# APP_HOST:"*.coursepath.com"
# BUILD_NAME=5.0.0
# PACKAGE_NAME="host.fellow.app"
# BUNDLE_ID_ANDROID="host.fellow.app"
# BUNDLE_ID_IOS="host.fellow.app"
# APPLICATION_APPLE_ID=6444327421        
# BEHIND_APP_BAR="true"

echo APP_NAME = $APP_NAME
echo PACKAGE_NAME = $PACKAGE_NAME
echo DEFAULT_BUNDLE_ID_IOS = $DEFAULT_BUNDLE_ID_IOS
echo BUNDLE_ID_IOS = $BUNDLE_ID_IOS
echo BUNDLE_ID_ANDROID = $BUNDLE_ID_ANDROID

cat > "./.env" <<EOF
APP_NAME=$APP_NAME
SHORT_NAME=$SHORT_NAME
URL_SCHEME=$URL_SCHEME
SHARE_PATH=$SHARE_PATH
BASE_URL=$BASE_URL
APP_HOST=$APP_HOST
CUSTOM_DOMAINS=$(echo "$CUSTOM_DOMAINS" | tr '\n' ',' | sed 's/,$//')
BEHIND_APP_BAR=$BEHIND_APP_BAR
EOF

# Loop through the domain names and add them to the entitlements file
# for DOMAIN in $CUSTOM_DOMAINS
# do
#   /usr/libexec/PlistBuddy -c "Add :com.apple.developer.associated-domains:1 string 'applinks:$DOMAIN'" ./ios/Runner/Runner.entitlements
# done

# Loop through the domain names and add them to the AndroidManifest.xml file
# for DOMAIN in $CUSTOM_DOMAINS
# do
#   sed -i '' "/<data android:host=\"@string\/APP_HOST\" \/>/a \\
#                 <data android:host=\"$DOMAIN\" \/>" android/app/src/main/AndroidManifest.xml
# done


sed -i '' 's/'$DEFAULT_BUNDLE_ID_IOS'/'$BUNDLE_ID_IOS'/g'  ./ios/Runner.xcodeproj/project.pbxproj
sed -i '' 's/'$DEFAULT_BUNDLE_ID_IOS'/'$BUNDLE_ID_IOS'/g'  ./ios/Runner/Runner.entitlements
sed -i '' 's/'$DEFAULT_BUNDLE_ID_IOS'/'$BUNDLE_ID_IOS'/g'  ./ios/ShareExtension/ShareViewController.swift                
sed -i '' 's/'$DEFAULT_BUNDLE_ID_IOS'/'$BUNDLE_ID_IOS'/g'  ./ios/ShareExtension/ShareExtension.entitlements
dart run activate rename
# flutter pub global run rename --bundleId $BUNDLE_ID_IOS -t ios
dart run rename setBundleId --targets android --value $BUNDLE_ID_ANDROID 
dart run rename setAppName --targets ios,android --value "$APP_NAME"
dart run change_app_package_name:main $PACKAGE_NAME



# sed -i '' 's/5.0.0+1/'$BUILD_NAME+$BUILD_NUMBER'/g' ./pubspec.yaml