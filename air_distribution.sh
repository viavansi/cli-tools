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

  expirationDate=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision) | openssl x509 -inform DER -noout -enddate | sed -e 's#notAfter=##'`

  certificateSubject=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision) | openssl x509 -inform DER -noout -subject`

  cert_uid=`echo $certificateSubject | cut -d \/ -f 2 | cut -d \= -f 2`
  cert_o=`echo $certificateSubject | cut -d \/ -f 4 | cut -d \= -f 2`  certificateSubject="$cert_o ($cert_uid)"

  expirationMobileProvision=`/usr/libexec/PlistBuddy -c 'Print ExpirationDate' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision)`

  uuidMobileProvision=`/usr/libexec/PlistBuddy -c 'Print UUID' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision)`

  #extract settings from the Info.plist file
  info_plist_domain=`ls Payload/*.app/Info.plist`
  bundle_identifier=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$info_plist_domain")
  short_version_string=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$info_plist_domain")
  app_name=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$info_plist_domain")
  app_url=`echo $app_name | tr "[:upper:]" "[:lower:]" | tr -d ' '`
  artifacts_url="$url/$app_url/ios/$short_version_string/$environment"
  git_revision=`git rev-parse --short HEAD`

  cp -f Payload/*.app/AppIcon40x40@2x.png $ci_dir/icon-1.png
  cp -f Payload/*.app/AppIcon60x60@2x.png $ci_dir/icon-2.png

  echo "Firmado por: $certificateSubject"
  echo "Certificado de distribución válido hasta: $expirationDate"
  echo "Mobile Provision UUID: $uuidMobileProvision"
  echo "Mobile Provision válido hasta: $expirationMobileProvision"

  echo "Environment for $bundle_identifier at version $short_version_string"
  echo "App URL: $app_url"
  echo "Git Revision: $git_revision"
  echo
  echo "OTA Title: $app_name"
  echo "OTA URL: $artifacts_url"

  rm -rf Payload
  rm info-app.ipa
}

function build_ota_plist()
{
  echo "Generating app.plist"
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
  echo "Generating index.html"
  cat << EOF > $ci_dir/index.html
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
          background: #fff url($artifacts_url/icon-1.png) no-repeat 50% 50%;
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
            background-image: url($artifacts_url/icon-2.png);
            background-size: 57px 57px;
          }
        }
    </style>
  </head>
  <body>
    <div id="wrapper">
      <span class="icon"></span>
      <h1>$app_name <span>Versión $short_version_string - $git_revision</span></h1>
      <a href="itms-services://?action=download-manifest&url=$artifacts_url/app.plist">Instalar aplicaci&oacute;n</a>
    <ul style="font-size: 11px;color: gray;">
      <li>Aplicación compilada el: `date +%d/%m/%Y`</li>
      <li>Firmado por: $certificateSubject</li>
      <li>Certificado de distribución válido hasta: $expirationDate</li>
      <li>Mobile Provision válido hasta: $expirationMobileProvision</li>
      <li>Mobile Provision UUID: $uuidMobileProvision</li>
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
    mkdir -p $out/$app_url/ios/$short_version_string/$environment/
    cp -f $ipa $out/$app_url/ios/$short_version_string/$environment/app.ipa
    cp -f $ci_dir/app.plist  $out/$app_url/ios/$short_version_string/$environment/app.plist
    cp -f $ci_dir/index.html $out/$app_url/ios/$short_version_string/$environment/index.html
    cp -f $ci_dir/icon-1.png $out/$app_url/ios/$short_version_string/$environment/icon-1.png
    cp -f $ci_dir/icon-2.png $out/$app_url/ios/$short_version_string/$environment/icon-2.png
    rm $ci_dir/app.plist
    rm $ci_dir/index.html
    echo "Create OTA URL: $artifacts_url"
}

if [ "$#" -ne 5 ]; then
    show_usage
else
  echo
  echo "Get ipa info"
  ipa_info $ipa
  build_ota_plist
  build_ota_page
  distribute_app
fi
