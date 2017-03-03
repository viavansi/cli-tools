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

function build_app()
{
  #build the app
  echo "Running xcodebuild ..."

  xcodebuild -workspace "$workspace" -scheme "$scheme" -sdk iphoneos -resource-rules='$(SDKROOT)/ResourceRules.plist' -configuration Release -derivedDataPath "$devired_data_path" clean build >| xcodebuild_output

  if [ $? -ne 0 ]
  then
    tail -n20 xcodebuild_output
    failed xcodebuild
  fi

  rm -rf xcodebuild_output

  #get the name of the workspace to be build, used as the prefix of the DerivedData directory for this build
  local workspace_name=$(echo "$workspace" | sed -n 's/\([^\.]\{1,\}\)\.xcworkspace/\1/p')

  #locate this project's DerivedData directory
  local project_derived_data_directory=$(grep -oE "$workspace_name-([a-zA-Z0-9]+)[/]" xcodebuild_output | sed -n "s/\($workspace_name-[a-z]\{1,\}\)\//\1/p" | head -n1)
  local project_derived_data_path="$devired_data_path/$project_derived_data_directory"
  #locate the .app file

  #  infer app name since it cannot currently be set using the product name, see comment above
  #  project_app="$product_name.app"
  project_app=$(ls -1 "$project_derived_data_path/Build/Products/Release-iphoneos/" | grep ".*\.app$" | head -n1)

  if [ $(ls -1 "$project_derived_data_path/Build/Products/Release-iphoneos/" | grep ".*\.app$" | wc -l) -ne 1 ]
  then
    echo "Failed to find a single .app build product."
    # echo "Failed to locate $project_derived_data_path/Build/Products/Release-iphoneos/$project_app"
    failed locate_built_product
  fi

  #copy app and dSYM files to the working directory
  cp -Rf "$project_derived_data_path/Build/Products/Release-iphoneos/$project_app" $releases_dir
  cp -Rf "$project_derived_data_path/Build/Products/Release-iphoneos/$project_app.dSYM" $releases_dir

  #rename app and dSYM so that multiple environments with the same product name are identifiable
  #echo "Retrieving build products..."
  #rm -rf $project_dir/$bundle_identifier.app
  #rm -rf $project_dir/$bundle_identifier.app.dSYM
  #mv -f "$project_dir/$project_app" "$project_dir/$bundle_identifier.app"

  #echo "$project_dir/$bundle_identifier.app"
  #mv -f "$project_dir/$project_app.dSYM" "$project_dir/$bundle_identifier.app.dSYM"
  #echo "$project_dir/$bundle_identifier.app.dSYM"
  #project_app=$bundle_identifier.app

  #relink CodeResources, xcodebuild does not reliably construct the appropriate symlink
  #rm "$project_app/CodeResources"
  #ln -s "$project_app/_CodeSignature/CodeResources" "$project_app/CodeResources"
}

function sign_app()
{
  echo "Codesign as \"$certificate\", embedding provisioning profile $mobileprovision"
  #sign build for distribution and package as a .ipa
  xcrun -sdk iphoneos PackageApplication "$releases_dir/$project_app" -o "$releases_dir/app.ipa" --sign "$certificate" --embed "$mobileprovision" || failed codesign
}

function verify_app()
{
  #verify the resulting app
  codesign -d -vvv --file-list - "$releases_dir/$project_app" || failed verification
  mv $releases_dir/app.ipa $releases_dir/$scheme-$short_version_string.ipa
  rm -rf $releases_dir/$project_app
  rm -rf $releases_dir/$project_app.dSYM
}

echo "........ Validate Keychain ........"
echo
validate_keychain
echo
#echo
#describe_sdks
#echo
#echo "........ Describe Workspace ........"
#echo
#describe_workspace
#echo
echo "........ Set Environment ........"
echo
set_environment
echo
echo "........ Build ........"
echo
build_app
echo
echo "........ Package Application ........"
echo
sign_app
echo
echo "........ Verify ........"
echo
verify_app
