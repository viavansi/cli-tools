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
entitlements_plist=${11}

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
  # See extension: workspace or project
  arrIN=(${workspace//./ })
  if [[ "${arrIN[1]}" == "xcodeproj" ]]; then
    project="$workspace"
    echo "Using project: $project instead of workspace."
  fi

  #extract settings from the Info.plist file
  info_plist_domain=$(ls "$app_plist" | sed -e 's/\.plist//')

  # Read versions and identifiers for distribution.
  short_version_string=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app_plist")
  # If the version number (from Xcode 11) is MARKETING_VERSION, look for version in xcodeproj.
  if [[ "$short_version_string" =~ "MARKETING_VERSION" ]]; then
    arrIN=(${workspace//./ })
    short_version_string=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' ${arrIN[0]}.xcodeproj/project.pbxproj)
  fi

  compilation=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "$app_plist")
  # If the bundle id (from Xcode 11) is CURRENT_PROJECT_VERSION, look for version in xcodeproj.
  if [[ "$compilation" =~ "CURRENT_PROJECT_VERSION" ]]; then
    arrIN=(${workspace//./ })
    compilation=$(sed -n '/CURRENT_PROJECT_VERSION/{s/CURRENT_PROJECT_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' ${arrIN[0]}.xcodeproj/project.pbxproj)
  fi

  bundle_identifier=$(/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" "$app_plist")
  # If the bundle id (from Xcode 11) is BUNDLE_IDENTIFIER, look for version in xcodeproj.
  if [[ "$bundle_identifier" =~ "BUNDLE_IDENTIFIER" ]]; then
    arrIN=(${workspace//./ })
    bundle_identifier=$(sed -n '/PRODUCT_BUNDLE_IDENTIFIER/{s/PRODUCT_BUNDLE_IDENTIFIER = //;s/;//;s/^[[:space:]]*//;p;q;}' ${arrIN[0]}.xcodeproj/project.pbxproj)
  fi

  display_name=$(/usr/libexec/PlistBuddy -c "Print CFBundleDisplayName" "$app_plist")
  
  echo "$display_name ($scheme) version $short_version_string , compilation $compilation and with BundleId ($bundle_identifier)"
  # change_pbid 'ViafirmaDocuments.xcodeproj/project.pbxproj' $bundle_identifier
}

function archive_app()
{
  echo "Archive as \"$certificate\", embedding provisioning profile $mobileprovision ..."

#PROVISIONING_PROFILE="$mobileprovision"
  
  # Retrieve provision name
  security cms -D -i "$mobileprovision" > prov.plist
  provision_name=$(/usr/libexec/PlistBuddy -c 'print ":Name"' prov.plist)
  declare -a team_identifiers=$(/usr/libexec/PlistBuddy -c 'print ":TeamIdentifier"' prov.plist | sed -e 1d -e '$d')
  team_identifier=`echo ${team_identifiers[0]}`

  # Extract entitlements from provisioning if not provided
  if [ -z "$entitlements_plist" ]; then
    entitlements_plist="entitlements_tmp.plist"
    /usr/libexec/PlistBuddy -x -c 'Print:Entitlements' prov.plist > $entitlements_plist
  fi

  if [ $project ]; then
    $cli_tools/xcbuild-safe.sh -project "$project" -scheme "$scheme" -sdk "iphoneos" CODE_SIGN_IDENTITY="$certificate" DEVELOPMENT_TEAM=$team_identifier CODE_SIGN_ENTITLEMENTS="$entitlements_plist" PROVISIONING_PROFILE_SPECIFIER="$provision_name" OTHER_CODE_SIGN_FLAGS="--keychain $keychain" -archivePath app.xcarchive archive >| output
  else
    $cli_tools/xcbuild-safe.sh -workspace "$workspace" -scheme "$scheme" -sdk "iphoneos" -configuration Distribution CODE_SIGN_IDENTITY="$certificate" PRODUCT_BUNDLE_IDENTIFIER="$bundle_identifier" DEVELOPMENT_TEAM=$team_identifier CODE_SIGN_ENTITLEMENTS="$entitlements_plist" PROVISIONING_PROFILE_SPECIFIER="$provision_name" OTHER_CODE_SIGN_FLAGS="--keychain $keychain" -archivePath app.xcarchive archive >| output
  fi

  if [ $? -ne 0 ]
  then
    cat output
    failed "$current_dir/xcodebuild_archive"
  fi

  rm -rf prov.plist
  rm -rf entitlements_tmp.plist
  rm -rf output
}

function export_ipa()
{
  echo "Export as \"$certificate\", embedding provisioning profile $mobileprovision ..."
  /usr/libexec/PlistBuddy -c "Set :teamID $team_identifier" "$export_options"

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
  # Archived IPA name changes for different Xcode version!!
  xcode_version=$(/usr/bin/xcodebuild -version | sed -En 's/Xcode[[:space:]]+([0-9\.]*)/\1/p')
  requiredver="12.0"
  if [ "$(printf '%s\n' "$requiredver" "$xcode_version" | sort -V | head -n1)" = "$requiredver" ]; then
    ipa_file="$module_name.ipa"  #Xcode 12: Documents.ipa, Fortress.ipa...
    echo "Checking $releases_dir/$module_name.ipa ..."
    echo "Xcode version greater than or equal to ${requiredver}. Reading ipa file: ${ipa_file}"
  else
    ipa_file="$scheme.ipa" #Xcode 11.
    echo "Checking $releases_dir/$module_name.ipa ..."
    echo "Xcode version less than ${requiredver}. Reading ipa file: ${ipa_file}"
  fi

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
security unlock-keychain -p "$password" "$keychain"
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
