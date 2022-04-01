#!/bin/bash

export PROJ_PATH=""
MY_FILES_PATH = "$PWD"

#If running mac os
#Create subdirectory for android files
if [[ -d ./android ]]
then
    rm -r "android"
    mkdir "android"
else
    mkdir "android"
fi
cd "android"
build_apk.sh 
constr_apk_html.sh 
cd .. 

#build ipa
#construct html

#build dmg
#construct html

#If running linux
#build linux-desktop
#construct html

#If running windows
#build windows-desktop
#construct html

