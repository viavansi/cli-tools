#!/bin/bash

#######################################################
#Build apk and save to subdirectory in current directory
#######################################################
OUT_DIR="$PWD"
ANDROID_HOME="$HOME/Library/Android/sdk"

cd $PROJ_PATH
flutter build apk

for file in "$PWD"/build/app/outputs/apk/release/*.apk
do
    cp "$file" "$OUT_DIR"
done

cd "$OUT_DIR"
#######################################################
#######################################################

