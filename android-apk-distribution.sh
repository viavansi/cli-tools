#!/bin/bash

# Configuration
program_name=$0
apk=$1
environment=$2
url=$3
out=$4
developer=$5
scheme=$6

# Configuration
project_dir=`pwd`
os="android"

function show_usage() {
    echo "usage: $program_name param1 param2 param3"
    echo "param1:	.apk path"
    echo "param2:	environment"
    echo "param3: base url"
    echo "param4: output directory"
    echo "param5: developer company"
    echo "use \" \" in params with white spaces"
    exit 1
}

function check_params() {
    if [ "$apk" == "" ]; then
        echo "Failed: Apk empty"
        show_usage
        exit 1
    elif [ "$environment" == "" ]; then
        echo "Failed: Environment empty"
        show_usage
        exit 1
    fi
}

function set_environment()
{
  #extract versionName from the AndroidManifest.xml file
  echo "Extracting information from $apk"
  android_manifest=$(aapt dump badging $apk)

  short_version_string=$(aapt dump badging $apk | grep -Eo "versionName=\'.*?\'" | cut -d"=" -f2 | cut -d"-" -f1 | grep -Eo "[0-9\.]+")
  version_code=$(aapt dump badging $apk | grep -Eo "versionCode=\'.*?\'" | cut -d"=" -f2 | grep -Eo "[0-9]+")
  package_name=$(aapt dump badging $apk | grep -Eo "package: name=\'.+?\'" | cut -d"=" -f2 | grep -Eo "[0-9A-Za-z\.]+")
  apk_name=$(echo $apk | grep -o '[^/]*$')

  app_name=$(aapt d --values badging $apk | sed -n "/^application: /s/.*label='\([^']*\).*/\1/p")

  if [ "$scheme" == "" ]; then
    scheme=$(echo $app_name | tr -d " \t\n\r" | tr '[:upper:]' '[:lower:]')
  fi

  if [ "$developer" == "" ]; then
    developer="Viafirma"
  fi

  if [ "$out" == "" ]; then
    out="$HOME/shared/mobileapps/ci"
  fi

  if [ "$url" == "" ]; then
    url="https://descargas.viafirma.com/mobileapps/ci"
  fi

  date=$(date +"%Y")

  git_revision=`git rev-parse --short HEAD`

  artifacts_url="$url/$scheme/$os/$short_version_string/$environment"

  echo "Environment: $environment"
  echo "Scheme: $scheme"
  echo "Version: $short_version_string"
  echo "Version code: $version_code"
  echo "Package name: $package_name"
  echo "Git Revision: $git_revision"
  echo
  echo "OTA Title: $scheme"
  echo "Developer: $developer"
  echo "OTA URL: $artifacts_url"
}


function build_ota_page()
{
  echo "Generating index.html"
  cat << EOF > $project_dir/index.html
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="initial-scale=1, maximum-scale=1, user-scalable=no">
    <title>$app_name - $short_version_string</title>

    <style>
      body {
        background: #eee;
        font-family: "Lucida Grande",Verdana, Arial, Helvetica, sans-serif;
        font-size: 16px;
        margin: 0;
        padding: 0;
      }

      p {
        color: #777;
        font-size: 11px;
        font-style: italic;
        margin: 0 1.5em;
        text-align: center;
      }

      #wrapper {
        background-color: #fff;
        border: 1px solid #ccc;
        border-radius: 10px;
        margin: 1em 1em 0.5em 1em;
        padding: 0.25em;
      }

        #wrapper h1 {
          float: left;
          font-size: 18px;
          font-weight: normal;
          text-align: center;
          margin-right: 1em;
          line-height: 45px;
        }

        #wrapper h1 span {
          display: block;
          font-size: 12px;
          color: #999797;
          font-style: italic;
          line-height: 1;
          text-align: left;
        }

        #wrapper .icon {
          background: #fff url(./icon-1.png) no-repeat 50% 50%;
          border: 1px solid #ccc;
          border-radius: 3px;
          display: block;
          height: 57px;
          margin: 15px 0.5em 15px 1em;
          width: 57px;
          padding: 2px;
          float: left;
        }

        #wrapper a {
          clear: both;
          background-color: #006DCC;
          background-image: linear-gradient(to bottom, #0088CC, #0044CC);
          background-repeat: repeat-x;
          border-color: rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.1) rgba(0, 0, 0, 0.25);
          color: #FFFFFF;
          text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.25);
          border: 0 none;
          border-radius: 6px 6px 6px 6px;
          box-shadow: 0 1px 0 rgba(255, 255, 255, 0.1) inset, 0 1px 5px rgba(0, 0, 0, 0.25);
          color: #FFFFFF;
          font-size: 18px;
          font-weight: 200;
          padding: 19px 24px;
          transition: none 0s ease 0s;

          display: block;
          margin: 1em;
          text-decoration: none;
          text-align: center;
        }

        #wrapper a:focus, #wrapper a:hover, #wrapper a:active {
          background-color: #0044CC;
          box-shadow: none;
          background-image: none;
        }

        @media (-webkit-min-device-pixel-ratio: 2),	 (min-resolution: 192dpi) {
          #wrapper .icon {
            background-image: url(./icon-2.png);
            background-size: 57px 57px;
          }
        }
    </style>
  </head>
  <body>
    <div id="wrapper">
      <span class="icon"></span>
      <h1>$app_name <span>Versión $short_version_string - $git_revision</span></h1>
      <a href=$artifacts_url/$apk_name>Instalar aplicación</a>
      <ul style="font-size: 11px;color: gray;">
      <li>Sistema operativo: $os</li>
      <li>Código de aplicación: $package_name</li>
      <li>Aplicación compilada el: `date +%d/%m/%Y`</li>
      <li>Código de versión: $version_code</li>
    </ul>
    <p>
    <img src="https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl=$artifacts_url/index.html&choe=UTF-8"></p>
    </div>
    <p>&copy; $developer - `date +%Y`</p>
  </body>
  </html>
EOF
}


function distribute_app()
{
    mkdir -p $out/$scheme/$os/$short_version_string/$environment
    cp -f $apk $out/$scheme/$os/$short_version_string/$environment/$apk_name
    cp -f $project_dir/index.html $out/$scheme/$os/$short_version_string/$environment/index.html
    cp -f $project_dir/icon.png $out/$scheme/$os/$short_version_string/$environment/icon-1.png
    cp -f $project_dir/icon.png $out/$scheme/$os/$short_version_string/$environment/icon-2.png
    echo "Create OTA dir: $out/$scheme/$os/$short_version_string/$environment"
    echo $artifacts_url/index.html
}

function clean_up() {
    rm -rf ./apk_zip
    rm -f $project_dir/index.html
    rm -f $project_dir/icon.png
}

function f_gradle() {
  if [ "$versionCode" != "" ]; then
    versionCode="-PbuildVersionCode=$versionCode"
  else
    versionCode="-s"
  fi

  mode="Release"
  assemble="assemble$scheme"
  assemble="$assemble$environment"
  assemble="$assemble$mode"
  echo "> gradle clean $assemble"
  ../gradlew "$versionCode" clean $assemble

  echo "Generated apk $apk"
}

function f_image_apk() {
    unzip -o -d ./apk_zip $apk
    image_folder=$(aapt d --values badging $apk | sed -n "/^application: /s/.*icon='\([^']*\).*/\1/p")
    mv ./apk_zip/$image_folder $project_dir/icon.png
}

echo
check_params
echo
echo "**** Set Environment"
set_environment
echo
# Execute in jenkins
# echo "**** Run Gradle"
# f_gradle
# echo
echo "**** Prepare Install Page"
f_image_apk
build_ota_page
echo
echo "**** Distribute App"
distribute_app
echo
clean_up
echo "**** Complete!"
