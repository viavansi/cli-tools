#!/bin/bash

# Config
program_name=$0
app=$1
certificate=$2
mobileprovision=$3
entitlements=$4
bundle_id=$5
version=$6
compilation=$7

project_dir=`pwd`

function show_usage() {
    echo "usage: $program_name param1 param2 param3"
    echo "param1:	.ipa path"
    echo "param2:	Distribution certificate alias"
    echo "param3:	(optional) Distribution mobileprovision path"
    echo "param4: (optional) entitlements.plist path"
    echo "param5: (optional) new bundle id"
    echo "param6: (optional) new version number"
    echo "param7: (optional) new build number"
    echo "use \" \" in params with white spaces"
    exit 1
}

function resign_app()
{
  #echo "unzip app.ipa"
  unzip "$app" > /dev/null
  target=`ls Payload`

  #echo "remove old CodeSignature"
  rm -r "Payload/$target/_CodeSignature" "Payload/$target/CodeResources" 2> /dev/null | true

  # Provisioning profile used for signature is inside the .ipa, renamed as embedded.mobileprovision
  if [ -f "${mobileprovision}" ]; then 
    echo "replace embedded mobile new provisioning profile"
    cp "$mobileprovision" "Payload/$target/embedded.mobileprovision"
  else
    echo "reuse provisioning profile"
  fi

  # For version, build number and app_id, we can modify the inner .plist with the new values.
  if [ -n "${bundle_id}" ]; then
    echo "change the BUNDLE_ID to $bundle_id"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundle_id" "Payload/$target/Info.plist"
  fi
  if [ -n "${version}" ]; then
    echo "change the version to $version"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "Payload/$target/Info.plist"
  fi
  if [ -n "${compilation}" ]; then
    echo "change the build version to $compilation"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $compilation" "Payload/$target/Info.plist"
  fi

  # The entitlements, if provided, is an additional parameter to codesign command.
  if [ -f "${entitlements}" ]; then
    echo "resign with $entitlements"
    rm Payload/$target/entitlements.plist
    cp $entitlements Payload/$target/entitlements.plist
    /usr/bin/codesign -f -s "$certificate" --entitlements="$entitlements" "Payload/$target"
  else
    echo "resign without entitlements.plist"
    /usr/bin/codesign -f -s "$certificate" "Payload/$target"
  fi

  #echo "re-package"
  zip -qr "app-resigned.ipa" Payload SwiftSupport > /dev/null
  mv "app-resigned.ipa" "$app" > /dev/null

  #echo "remove unzip folder"
  rm -rf Payload > /dev/null
  rm -rf SwiftSupport > /dev/null # Only if the project uses Swift

  #echo "ReSign Complete!"
}

function app_backup()
{
  fileName=`basename $app`
  timestamp=$(date +%s)
  fileNameCopy="app_backup_$timestamp.ipa"
  backup=`echo ${app//$fileName/$fileNameCopy}`
  cp "$app" "$backup"
  #echo "copy $app in $backup"
}

if [ "$#" -lt 2 ]; then
    show_usage
else
  echo
  echo "....... ReSign ......."
  echo
  #app_backup
  resign_app
  echo "......................"
  echo
  echo
fi
