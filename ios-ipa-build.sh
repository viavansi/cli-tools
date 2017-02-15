#!/bin/bash

current=`pwd`
path=$1
workspace=$2
scheme=$3
profile=$4
certificate=$5
keychain=$6
password=$7
dest=$8

cd $path

security unlock-keychain -p $password $keychain

echo "Codesign as \"$certificate\", embedding provisioning profile $profile"

xcodebuild -workspace $workspace -scheme $scheme -sdk "iphoneos" -configuration Distribution CODE_SIGN_IDENTITY="$certificate" PROVISIONING_PROFILE="$profile" OTHER_CODE_SIGN_FLAGS="--keychain $keychain" -archivePath app.xcarchive archive

xcodebuild -exportArchive -exportFormat ipa -archivePath app.xcarchive -exportPath ./app.ipa

rm -rf app.xcarchive
mv app.ipa $dest
rm app.ipa

cd $current
