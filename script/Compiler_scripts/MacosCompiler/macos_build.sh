#!/bin/bash

cd "$proj_path"

if [[ ! -d macos ]]; then
  flutter create --platforms=macos . 
fi

flutter build macos
cd -

cp -rf "$proj_path"/build/macos/Build/Products/Release/*.app .
