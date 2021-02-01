#!/bin/bash -l

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
module_name=${10} # The name of the target in XCode.

cli_tools="$HOME/cli-tools"
# cli_tools="/Users/elage/Developer/Utilities/cli-tools"

if [ -z "$module_name" ]
then
    module_name="documents"
fi

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
  $cli_tools/xcbuild-safe.sh -showsdks
}

function describe_workspace()
{
  #describe the project workspace
  echo "Available schemes"
  $cli_tools/xcbuild-safe.sh -list -workspace "$workspace"
}

function change_pbid()
{
  pbxproj_path=$1
  new_bundle_id=$2
  old_bundle_id=$(awk -F '=' '/PRODUCT_BUNDLE_IDENTIFIER/ {print $2; exit}' $pbxproj_path)
  echo "Change bundle id from $old_bundle_id to $new_bundle_id"
  sed -i "" "s/$old_bundle_id/$new_bundle_id;/g" "$pbxproj_path"
}

function set_environment()
{
  #extract settings from the Info.plist file
  info_plist_domain=$(ls "$app_plist" | sed -e 's/\.plist//')
  
  short_version_string=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app_plist")
  display_name=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" "$app_plist")
  bundle_identifier=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_plist")
  echo "$display_name ($scheme) version $short_version_string ; with BundleId ($bundle_identifier)"
  # change_pbid 'ViafirmaDocuments.xcodeproj/project.pbxproj' $bundle_identifier
}

function archive_app()
{
  echo "Archive as \"$certificate\", embedding provisioning profile $mobileprovision ..."

#PROVISIONING_PROFILE="$mobileprovision"
  
  # Retrieve provision name
  security cms -D -i "$mobileprovision" > prov.plist
  provision_name=$(/usr/libexec/PlistBuddy -c 'print ":Name"' prov.plist)

  $cli_tools/xcbuild-safe.sh -workspace "$workspace" -scheme "$scheme" -sdk "iphoneos" -configuration Distribution CODE_SIGN_IDENTITY="$certificate" PRODUCT_BUNDLE_IDENTIFIER="$bundle_identifier" PROVISIONING_PROFILE_SPECIFIER="$provision_name" OTHER_CODE_SIGN_FLAGS="--keychain $keychain" -archivePath app.xcarchive archive >| output

  if [ $? -ne 0 ]
  then
    cat output
    failed "$current_dir/xcodebuild_archive"
  fi

  rm -rf output
}

function export_ipa()
{
  echo "Export as \"$certificate\", embedding provisioning profile $mobileprovision ..."

  $cli_tools/xcbuild-safe.sh -exportArchive -archivePath app.xcarchive -exportPath "$releases_dir"  -exportOptionsPlist "$export_options"
  PROVISIONING_PROFILE_SPECIFIER="$mobileprovision" >| output

  if [ $? -ne 0 ]
  then
    cat output
    failed "$cli_tools/xcodebuild_export"
  fi

  rm -rf output
}

function check_ipa()
{
  echo "Checking $releases_dir/$module_name.ipa ..."

  # Version copy of the .ipa
  ipa_file="$scheme.ipa"
  # ipa_file="$module_name.ipa"

  cp "$releases_dir/$ipa_file" "$releases_dir/$scheme-$short_version_string.ipa"

  # Verify .app inside .ipa
  unzip -qq "$releases_dir/$ipa_file" -d $releases_dir/content
  xcrun codesign -dv "$releases_dir/content/Payload/$module_name.app" >| output

  if [ $? -ne 0 ]
  then
    cat output
    failed $cli_tools/xcodebuild_export
  fi

  rm -rf output
  rm -rf app.xcarchive
  rm -rf "$releases_dir/$ipa_file"
  rm -rf "$releases_dir/content"
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
