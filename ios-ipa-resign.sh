#!/bin/bash

# Config
program_name=$0
app=$1
cetificate=$2
mobileprovision=$3
entitlements=$4
bundle_id=$5
version=$6

project_dir=`pwd`

function show_usage() {
    echo "usage: $program_name param1 param2 param3"
    echo "param1:	.ipa path"
    echo "param2:	Distribution certificate alias"
    echo "param3:	Distribution mobileprovision path"
    echo "param4: (optional) entitlements.plist path"
    echo "param5: (optional) new bundle id"
    echo "param6: (optional) new version number"
    echo "use \" \" in params with white spaces"
    exit 1
}

function resign_app()
{
  echo "unzip app.ipa"
  unzip "$app"
  target=`ls Payload`

  echo "remove old CodeSignature"
  rm -r "Payload/$target/_CodeSignature" "Payload/$target/CodeResources" 2> /dev/null | true

  echo "replace embedded mobile provisioning profile"
  cp "$mobileprovision" "Payload/$target/embedded.mobileprovision"

  if [ $bundle_id != '' ]; then
    echo "change the BUNDLE_ID to $bundle_id"
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundle_id" "Payload/$target/Info.plist"
  fi

  if [ $version != '' ]; then
    echo "change the version to $version"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $version" "Payload/$target/Info.plist"
  fi

  echo "re-sign"
  if [ $entitlements != '' ]; then
    echo "resign with $entitlements"
    /usr/bin/codesign -f -s "iPhone Distribution: $cetificate" --entitlements="$entitlements" "Payload/$target"
  else
    echo "resign without entitlements.plist"
    /usr/bin/codesign -f -s "iPhone Distribution: $cetificate" "Payload/$target"
  fi

  echo "re-package"
  zip -qr "app-resigned.ipa" Payload
  mv "app-resigned.ipa" "$app"

  echo "remove unzip folder"
  rm -rf Payload

  echo "ReSign Complete!"
}

function app_backup()
{
  fileName=`basename $app`
  timestamp=$(date +%s)
  fileNameCopy="app_backup_$timestamp.ipa"
  backup=`echo ${app//$fileName/$fileNameCopy}`
  cp "$app" "$backup"
  echo "copy $app in $backup"
}

function ipa_info()
{
  echo "copy $1"
  cp -P $1 ./info-app.ipa
  unzip info-app.ipa

  expirationDate=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision) | openssl x509 -inform DER -noout -enddate | sed -e 's#notAfter=##'`

  certificateSubject=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision) | openssl x509 -inform DER -noout -subject`

  cert_uid=`echo $certificateSubject | cut -d \/ -f 2 | cut -d \= -f 2`
  cert_o=`echo $certificateSubject | cut -d \/ -f 4 | cut -d \= -f 2`  certificateSubject="$cert_o ($cert_uid)"

  expirationMobileProvision=`/usr/libexec/PlistBuddy -c 'Print ExpirationDate' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision)`

  uuidMobileProvision=`/usr/libexec/PlistBuddy -c 'Print UUID' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision)`

  rm -rf Payload
  rm info-app.ipa
}

if [ "$#" -lt 3 ]; then
    show_usage
else
  echo
  echo "ReSign App $app"
  app_backup
  resign_app
  echo "App Info"
  ipa_info $app
  echo
  echo "Firmado por: $certificateSubject"
  echo "Certificado de distribución válido hasta: $expirationDate"
  echo "Mobile Provision UUID: $uuidMobileProvision"
  echo "Mobile Provision válido hasta: $expirationMobileProvision"
fi
