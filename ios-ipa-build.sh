#!/bin/bash

# Remove CODE_SIGN_RESOURCE_RULES_PATH=$(SDKROOT)/ResourceRules.plist
# Find the   /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/PackageApplication script and update it.

# Find the lines including the following code in the script

# my @codesign_args = ("/usr/bin/codesign", "--force", "--preserve-metadata=identifier,entitlements,resource-rules",
#                   "--sign", $opt{sign},
#                   "--resource-rules=$destApp/ResourceRules.plist");
# change it to:
# my @codesign_args = ("/usr/bin/codesign", "--force", "--preserve-metadata=identifier,entitlements",
#                 "--sign", $opt{sign});

# Configuration
keychain=${1}
password=${2}
workspace=${3}
scheme=${4}
certificate=${5}
app_plist=${6}
mobileprovision=${7}
releases_dir=${8}
export_options=${9}

#devired_data_path="/tmp/DerivedData"
devired_data_path="$releases_dir/DerivedData"

function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}

function validate_keychain()
{
  # unlock the keychain containing the provisioning profile's private key and set it as the default keychain
  security unlock-keychain -p "$password" "$keychain"
  security default-keychain -s "$keychain"

  #describe the available provisioning profiles
  #echo "Available provisioning profiles"
  #security find-identity -p codesigning -v

  #verify that the requested provisioning profile can be found
  (security find-certificate -a -c "$certificate" -Z | grep ^SHA-1) || failed certificate
}

function describe_sdks()
{
  #list the installed sdks
  echo "Available SDKs"
  xcodebuild -showsdks
}

function describe_workspace()
{
  #describe the project workspace
  echo "Available schemes"
  xcodebuild -list -workspace $workspace
}

function set_environment()
{
  #extract settings from the Info.plist file
  info_plist_domain=$(ls $app_plist | sed -e 's/\.plist//')
  short_version_string=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app_plist")
  bundle_identifier=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" "$app_plist")
  echo "$bundle_identifier ($scheme) version $short_version_string"
}

function archive_app()
{
  echo "Archive as \"$certificate\", embedding provisioning profile $mobileprovision ..."

#PROVISIONING_PROFILE="$mobileprovision"

  xcodebuild -workspace $workspace -scheme $scheme -sdk "iphoneos" -configuration Distribution CODE_SIGN_IDENTITY="$certificate" OTHER_CODE_SIGN_FLAGS="--keychain $keychain" -archivePath app.xcarchive archive >| output

  if [ $? -ne 0 ]
  then
    cat output
    failed xcodebuild_archive
  fi

  rm -rf output
}

function export_ipa()
{
  echo "Export as \"$certificate\", embedding provisioning profile $mobileprovision ..."

  xcodebuild -exportArchive -archivePath app.xcarchive -exportPath $releases_dir  -exportOptionsPlist $export_options
  PROVISIONING_PROFILE_SPECIFIER="$mobileprovision" >| output

  if [ $? -ne 0 ]
  then
    cat output
    failed xcodebuild_export
  fi

  rm -rf output
}

function check_ipa()
{
  echo "Checking $releases_dir/$scheme-$short_version_string.ipa ..."

  cp $releases_dir/$scheme.ipa $releases_dir/$scheme-$short_version_string.ipa

  mv $releases_dir/$scheme.ipa $releases_dir/$scheme.zip
  unzip -qq $releases_dir/$scheme.zip -d $releases_dir/
  xcrun codesign -dv $releases_dir/Payload/documents.app >| output

  if [ $? -ne 0 ]
  then
    cat output
    failed xcodebuild_export
  fi

  rm -rf output
  rm -rf app.xcarchive
  rm -rf $releases_dir/$scheme.zip
  rm -rf $releases_dir/Payload
}

echo "........ Validate Keychain ........"
echo
validate_keychain
echo
echo "........ Set Environment ........"
echo
set_environment
echo
echo "........ Archive ........"
echo
archive_app
echo
echo "........ Export ........"
echo
export_ipa
echo
echo "........ Check ........"
echo
check_ipa
echo
echo "......................."
