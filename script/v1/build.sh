#!/bin/bash

###################################################
#Help
Help()
{
   # Display Help
   echo "Syntax: script [-a|i|h]"
   echo "options:"
   echo "a     Compile android apk"
   echo "i     Compile ios ipa"
   echo "h     Print this Help."
   echo
}

Filename="app"

###################################################
while getopts ":aid:n:h" option; do
   case $option in
      a) #Compile android (optional)
	 Android=1;;
      i) #Compile IOS (optional)
	 Ios=1;;
      d) #Set the project directory
         Dir=${OPTARG};;
      n) #Set the name of the app file
         Filename=${OPTARG};;
      h) #Display Help
         Help
         exit;;
      
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done
###################################################

if [[ -n "$Dir" ]]
then
    read -p 'Enter directory path: ' Dir
fi

#Build apps
cd $Dir
if [[ -n "$Android" ]]
then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    flutter build apk
fi

#Copy all built files to builds directory 
cd -
if [[ ! -d "builds" ]]
then
    echo "creating builds dir"
    mkdir builds
fi

ITER=0
for file in "$Dir"/build/app/outputs/apk/release/*.apk
do
    echo "${file} -> ${ITER}_${Filename}.apk"
    cp ${file} ./builds/${ITER}_${Filename}.apk
    ITER=$(expr $ITER + 1)
done

#Generate html with the files that were built
./index_files.sh
