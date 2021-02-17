#!/bin/bash

# aapt location, needed to extract the information from the apk. Depending of the aapt version, some steps may fail.
export PATH=$PATH:/Applications/android-sdk-macosx/build-tools/22.0.0


# Configuration
program_name=$0
apk=$1
environment=$2
url=$3
out=$4
developer=$5
scheme=$6
version_path=$7

# Configuration
project_dir=`pwd`
os="android"
aapt_dir="/Applications/android-sdk-macosx/build-tools/22.0.0/aapt"

function show_usage() {
  echo "usage: $program_name param1 param2 param3"
  echo "param1:	.apk path"
  echo "param2:	environment"
  echo "param3: base url"
  echo "param4: output directory"
  echo "param5: developer company"
  echo "param6: scheme"
  echo "param7: path to copy version"
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
  android_manifest=$($aapt_dir dump badging $apk)

  short_version_string=$($aapt_dir dump badging $apk | grep -Eo "versionName=\'.*?\'" | cut -d"=" -f2 | cut -d"-" -f1 | grep -Eo "[0-9\.]+")

  if [ "$version_path" == "" ]; then
    ver_path=$short_version_string
  else  
    ver_path=$version_path
  fi
  
  version_code=$($aapt_dir dump badging $apk | grep -Eo "versionCode=\'.*?\'" | cut -d"=" -f2 | grep -Eo "[0-9]+")
  package_name=$($aapt_dir dump badging $apk | grep -Eo "package: name=\'.+?\'" | cut -d"=" -f2 | grep -Eo "[0-9A-Za-z\.]+")
  apk_name=$(echo $apk | grep -o '[^/]*$')

  app_name=$($aapt_dir d --values badging $apk | sed -n "/^application: /s/.*label='\([^']*\).*/\1/p")

  if [ "$scheme" == "" ]; then
    scheme=$(echo $app_name | tr -d " \t\n\r" | tr '[:upper:]' '[:lower:]' | tr "áéíóúÁÉÍÓÚ" "aeiouAEIOU")
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

  artifacts_url="$url/$scheme/$os/$ver_path/$environment"

  echo "Environment: $environment"
  echo "Scheme: $scheme"
  echo "Version: $short_version_string"
  echo "Version path: $ver_path"
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
  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }
  .container {
    margin: 0 auto;
    width: 1170px;
  }
  .full, 
  .half, 
  .third, 
  .quarter {
    float: left;
  }
  .full {
    width: 100%;
  }
  .threeQuarters {
    width: 75%;
  }
  .half {
    width: 50%;
  }
  .third {
    width: 33.33%;
  }
  .quarter {
    width: 25%;
  }
  .center {
    text-align: center;
  }
  .left {
    text-align: left;
  }
  .right {
    text-align: right;
  }
  body {
  color: #444e56;
  font-family: "Open Sans", sans-serif;
  font-size: 16px;
}
li {
  list-style: none; 
  padding: .25em 0em;
}
header {
  background: #145b94;
  display: block;
  width: 100%;
  position: relative;
  float: left;
  height: 100px;
}
header .container {
  display: flex;
  align-items: center;
}
header a {
  color: white;
  float: right;
  padding: 2em 4.75em;
  text-decoration: none;
}
.logoViafirma {
  padding: 1.25em 0em;
}
.logoViafirma img {
  max-width: 200px;
}
.introText {
  padding: 1em 0em;
}
.handImage img {
  margin-top: 60px;
  margin-bottom: -5px;
}
.splash {
  position: absolute;
  height: auto;
  top: 297px;
  margin-left: 5.5px;
  width: 145px;
}
.download {
  background: #fff;
  border-radius: 4px;
  box-shadow: 0px 2px 3px #d0d0d0;
  padding: 2em 2em 0em 2em;
}
.download .info {
  background: #FBF2E1;
  border: 1px solid orange;
  border-radius: 3px;
  color: orange;
  font-size: 14px;
  font-weight: lighter;
  margin: 0 auto;
  margin-bottom: 1em;
  padding: 1em;
}
.download .info a {
  color: orange;
}
.download .appInfo .infoContainer {
  background: white;
  box-shadow: 0px 1px 10px #d0d0d0;
  border-radius: 3px;
  margin: 0 auto;
  margin-bottom: 1.5em;
  padding: 2em;
}
.download .appName {
  display: inline-block;
  margin-bottom: -1em;
  width: 100%;
}
.download .appName h2 {
  padding-left: 34px;
  margin-top: .66em;
  width: 100%;
  text-align: left;
}
.download .appName small {
  display: block;
  font-weight: lighter;
  font-style: italic;
  padding-left: 82px;
  text-align: left;
  opacity: .5;
  width: 100%;
}
.icon {
  background: #fff url(./icon-1.png) no-repeat 50% 50%;
  border: 1px solid #ddd;
  background-size: 100%;
  border-radius: 8px;
  display: block;
  float: left; 
  height: 57px;
  margin: 15px 0.5em 15px 1em;
  width: 57px;
}
.download ul {
  font-size: 10px;
  line-height: 14px;
  margin-top: 2em;
  opacity: .5;
  text-align: left;
}
.button {
  background: #145b94;
  border-radius: 4px;
  color: white;
  display: block;
  margin: 0 auto;
  padding: .75em 2em;
  text-align: center;
  text-decoration: none;
  text-transform: capitalize;
  transition: .3s;
}
.button:hover {
  background: #16466e;
  transition: .3s;
}
.help {
  background: #fafafa;
  float: left;
  padding: 2em;
  }
  .help h2 {
    font-weight: lighter;
    padding: 1.5em 0em;
    text-align: center;
  }
  .help h3 {
    font-weight: lighter;
  }
.illustration img {
  max-width: 320px;
  width: 100%;
}
  footer {
    background: #145b94;
    color: white;
    display: inline-block;
    font-size: 12px;
    padding: 1em 3em;
}
@media (max-width: 1170px) {
  .container {
    width: 100%;
  }
  .quarter {
    width: 50%;
  }
}
@media (max-width: 768px) {
  .logoViafirma {
    text-align: center;
    width: 100%;
  }
  header .half:last-child {
    display: none;
  }
  .half,
  .third,
  .quarter,
  .threeQuarters {
    width: 100%;
  }
  .handImage,
  .splash {
    display: none;
  }
  .download {
    margin: 0;
    padding: 2em 1em;
  }
  .appInfo .appName + img {
    display: none;
  }
  .download .button {
    margin: 2em 0em;
  }
  .illustration {
    padding: 2em 0em;
  }
}
</style>
</head>
<body>
    <header class="full">
      <div class="container">
        <div class="half logoViafirma">
          <img alt="logoViafirma" src="https://descargas.viafirma.com/afuentes/img/descargas/logo-viafirma-white.png"/>
        </div>
        <div class="half">
          <a href="https://www.viafirma.com" target="_blank">Web viafirma</a>
        </div>
      </div>
    </header>
    <main>
      <section class="full download">
        <div class="container">
          <div class="half center handImage">
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/splash-android.png"/>
          </div>
          <div class="half center appInfo">
            <p class="info threeQuarters">Vas a descargar una APP externa al Google Play. Es necesario <a href="#help">activar orígenes desconocidos</a> para su ejecución.</p>
            <div class="threeQuarters infoContainer">
              <div class="appName">
                <span class="icon"></span>
                <h2>$app_name</h2>
                <small>Versión $short_version_string - $git_revision</small>
              </div>
              <img src="https://quickchart.io/qr?text=$artifacts_url/index.html">
              <a class="button" href=$artifacts_url/$apk_name>Instalar aplicación</a>
              <ul>
                <li>Sistema operativo: $os</li>
                <li>Código de aplicación: $package_name</li>
                <li>Aplicación compilada el: `date +%d/%m/%Y`</li>
                <li>Código de versión: $version_code</li>
              </ul>
            </div>
          </div>
        </div>
      </section>
      <section class="full help center" id="help">
        <h2 class="left">Cómo instalar aplicaciones desde orígenes desconocidos</h3> 
        <ul>
          <li class="illustration third">
            <h3>1. Accede a Settings</h3>
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/android-step-1.png"/>
          </li>
          <li class="illustration third">
            <h3>2. Entramos en Seguridad</h3>
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/android-step-2.png"/>
          </li>
          <li class="illustration third">
            <h3>3. Activamos Orígenes desconocidos</h3>
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/android-step-3.png"/>
          </li>
        </ul>
        <a href="http://doc.viafirma.com/documents/ios/ios_viafirma_dev_trusted.html">Ayuda para confiar en el certificado de distribución</a>
      </section>
    </main>
    <footer class="full">
      <div class="container center">
          <p>&copy; Viafirma - 2017</p>
      </div>
    </footer>
  </body>
</html>
EOF
}


function distribute_app()
{
  mkdir -p $out/$scheme/$os/$ver_path/$environment
  cp -f $apk $out/$scheme/$os/$ver_path/$environment/$apk_name
  cp -f $project_dir/index.html $out/$scheme/$os/$ver_path/$environment/index.html
  cp -f $project_dir/icon.png $out/$scheme/$os/$ver_path/$environment/icon-1.png
  cp -f $project_dir/icon.png $out/$scheme/$os/$ver_path/$environment/icon-2.png
  echo "Create OTA dir: $out/$scheme/$os/$ver_path/$environment"
  echo $artifacts_url/index.html
}

function clean_up() {
  rm -rf ./apk_zip
  rm -rf $project_dir/index.html
  rm -rf $project_dir/icon.png
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
  image_folder=$($aapt_dir d --values badging $apk | sed -n "/^application: /s/.*icon='\([^']*xml\).*/\1/p")
  if [ $image_folder != "" ]; then
    # Case XML defined as launch icon.
    name_icon=$($aapt_dir d --values badging $apk | sed -n "/^application: /s/.*icon='.*\/\([^']*\).xml'*/\1/p")
    image_folder="res/mipmap-hdpi-v4/$name_icon.png"
  else 
    # Case png defined as main icon.
    image_folder=$($aapt_dir d --values badging $apk | sed -n "/^application: /s/.*icon='\([^']*\).*/\1/p")
  fi
  cp ./apk_zip/$image_folder $project_dir/icon.png
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
