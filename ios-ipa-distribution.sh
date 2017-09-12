#!/bin/bash

# Configuration
program_name=$0
ipa=$1
environment=$2
url=$3
out=$4
developer=$5
ci_dir=`pwd`

function show_usage() {
    echo "usage: $program_name param1 param2 param3"
    echo "param1:	.ipa path"
    echo "param2:	environment"
    echo "param3: base url"
    echo "param4: output directory"
    echo "param5: developer company"
    echo "use \" \" in params with white spaces"
    exit 1
}

function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}

function ipa_info()
{
  cp -P $1 ./info-app.ipa
  unzip info-app.ipa > /dev/null

  expirationDate=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision 2> /dev/null) | openssl x509 -inform DER -noout -enddate | sed -e 's#notAfter=##'`

  certificateSubject=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision 2> /dev/null) | openssl x509 -inform DER -noout -subject`

  cert_uid=`echo $certificateSubject | cut -d \/ -f 2 | cut -d \= -f 2`
  cert_o=`echo $certificateSubject | cut -d \/ -f 3 | cut -d \= -f 2`  certificateSubject="$cert_o ($cert_uid)"

  expirationMobileProvision=`/usr/libexec/PlistBuddy -c 'Print ExpirationDate' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision)`

  uuidMobileProvision=`/usr/libexec/PlistBuddy -c 'Print UUID' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision)`

  #extract settings from the Info.plist file
  info_plist_domain=`ls Payload/*.app/Info.plist`
  bundle_identifier=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$info_plist_domain")
  short_version_string=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$info_plist_domain")
  app_name=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$info_plist_domain")
  app_url=`echo $app_name | tr "[:upper:]" "[:lower:]" | tr -d ' '`
  app_url=`echo $app_url | tr "áéíóúÁÉÍÓÚ" "aeiouAEIOU" | tr -d ' '`
  artifacts_url="$url/$app_url/ios/$short_version_string/$environment"
  git_revision=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$info_plist_domain")

  xcrun -sdk iphoneos pngcrush \
 -revert-iphone-optimizations -q Payload/*.app/AppIcon40x40@2x.png $ci_dir/icon-1.png
  xcrun -sdk iphoneos pngcrush \
 -revert-iphone-optimizations -q Payload/*.app/AppIcon60x60@2x.png $ci_dir/icon-2.png
 xcrun -sdk iphoneos pngcrush \
 -revert-iphone-optimizations -q Payload/*.app/LaunchImage-700-568h@2x.png $ci_dir/launchimage.png

  echo "Firmado por: $certificateSubject"
  echo "Certificado de distribución válido hasta: $expirationDate"
  echo "Mobile Provision UUID: $uuidMobileProvision"
  echo "Mobile Provision válido hasta: $expirationMobileProvision"

  echo "Environment for $bundle_identifier at version $short_version_string"
  #echo "App URL: $app_url"
  echo "Git Revision: $git_revision"
  echo "$app_name: $artifacts_url"

  rm -rf Payload
  rm info-app.ipa
}

function build_ota_plist()
{
  #echo "Generating app.plist"
  cat << EOF > $ci_dir/app.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key>
          <string>software-package</string>
          <key>url</key>
          <string>$artifacts_url/app.ipa</string>
        </dict>
        <dict>
          <key>kind</key>
          <string>full-size-image</string>
          <key>needs-shine</key>
          <true/>
          <key>url</key>
          <string>$artifacts_url/icon-1.png</string>
        </dict>
        <dict>
          <key>kind</key>
          <string>display-image</string>
          <key>needs-shine</key>
          <true/>
          <key>url</key>
          <string>$artifacts_url/icon-2.png</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key>
        <string>$bundle_identifier</string>
        <key>bundle-version</key>
        <string>$short_version_string</string>
        <key>kind</key>
        <string>software</string>
        <key>subtitle</key>
        <string>Example App</string>
        <key>title</key>
        <string>$app_name</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
EOF
}

function build_ota_page()
{
  #echo "Generating index.html"
  cat << EOF > $ci_dir/index.html
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
  position: relative;
  margin-left: -282px;
  top: -164px;
  width: 146px;
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
  background-size: 100%;
  border: 1px solid #ddd;
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
.illustration img {
    max-width: 320px;
    width: 100%;
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
@media (max-width: 830px) {
  .logoViafirma {
    text-align: center;
    width: 100%;
  }
  header .half:last-child {
    display: none;
  }
  .half,
  .third,
  .threeQuarters,
  .quarter {
    width: 100%;
  }
  .handImage,
   .splash{
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
            <p class="left introText">
            <!-- Bienvenidos a la página de descargas de Viafirma. -->
            </p>
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/splash-ios.png"/>
            <img class="splash" src="$artifacts_url/launchimage.png" />
          </div>
          <div class="half center appInfo">
            <p class="info threeQuarters">Vas a instalar una APP externa a la App Store. Es necesario <a href="#help">confiar en el certificado de distribución</a> para su ejecución.</p>
            <div class="threeQuarters infoContainer">
              <div class="appName">
                <span class="icon"></span>
                <h2>$app_name</h2>
                <small>Versión $short_version_string - $git_revision</small>
              </div>
               <img src="https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl=$artifacts_url/index.html&choe=UTF-8">
              <a class="button"  href="itms-services://?action=download-manifest&url=$artifacts_url/app.plist">Instalar aplicación</a>
              <ul>
                <li>Aplicación compilada el: `date +%d/%m/%Y`</li>
                <li>Firmado por: $certificateSubject</li>
                <li>Certificado de distribución válido hasta: $expirationDate</li>
                <li>Mobile Provision válido hasta: $expirationMobileProvision</li>
                <li>Mobile Provision UUID: $uuidMobileProvision</li>
              </ul>
            </div>
          </div>
        </div>
      </section>
      <section class="full help center" id="help">
        <h2 class="left">Cómo confiar en viafirma como desarrollador</h3> 
        <ul>
          <li class="illustration quarter">
            <h3>1. Accede a Settings</h3>
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/step-2.png"/>
          </li>
          <li class="illustration quarter">
            <h3>2. Gestión de Dispositivos</h3>
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/step-3.png"/>
          </li>
          <li class="illustration quarter">
            <h3>3. Confiar en "VIAFIRMA S.L."</h3>
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/step-4.png"/>
          </li>
          <li class="illustration quarter">
            <h3>4. Aceptar mensaje de confirmación</h3>
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/step-5.png"/>
          </li>
        </ul>
        <a href="http://doc.viafirma.com/documents/ios/ios_viafirma_dev_trusted.html">Ayuda para confiar en el certificado de distribución</a>
      </section>
    </main>
    <footer class="full">
      <div class="container center">
        <p>&copy; $developer - `date +%Y`</p>
      </div>
    </footer>
  </body>
  </html>
EOF
}

function distribute_app()
{
    mkdir -p $out/$app_url/ios/$short_version_string/$environment/
    cp -f $ipa $out/$app_url/ios/$short_version_string/$environment/app.ipa
    cp -f $ci_dir/app.plist  $out/$app_url/ios/$short_version_string/$environment/app.plist
    cp -f $ci_dir/index.html $out/$app_url/ios/$short_version_string/$environment/index.html
    cp -f $ci_dir/icon-1.png $out/$app_url/ios/$short_version_string/$environment/icon-1.png
    cp -f $ci_dir/icon-2.png $out/$app_url/ios/$short_version_string/$environment/icon-2.png
    cp -f $ci_dir/launchimage.png $out/$app_url/ios/$short_version_string/$environment/launchimage.png
    rm $ci_dir/app.plist
    rm $ci_dir/index.html
    #echo "Create OTA URL: $artifacts_url"
}

function jenkins_summary()
{
  #https://wiki.jenkins-ci.org/display/JENKINS/Summary+Display+Plugin
  #echo "Write jenkins_summary.xml"
  cat << EOF > ipa_distribution_jenkins_summary.xml
<?xml version="1.0" encoding="UTF-8"?>
<section name="Air Distribution Summary" fontcolor="#3D3D3D">
<field name="Información para la distribución">
<![CDATA[
  <a href="$artifacts_url">URL de instalación</a>
  <a href="$artifacts_url/app.ipa">URL de descarga del .ipa</a>
 ]]>
</field>
</section>

EOF
}

if [ "$#" -ne 5 ]; then
    show_usage
else
  echo
  echo "....... Distribution Info ......."
  echo
  ipa_info $ipa
  build_ota_plist
  build_ota_page
  distribute_app
  jenkins_summary
  echo
  echo "................................."
fi
