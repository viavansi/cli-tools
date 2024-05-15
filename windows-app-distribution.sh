#!/bin/bash

# Configuration
program_name=$0
exe=$1          # ej: /releases/app.exe
app_name=$2     # ej: viafirmadocuments
version=$3      # ej: 3.7.20
environment=$4  # ej: pre
url=$5          # ej: https://descargas.viafirma.com/mobileapps/ci
out=$6          # ej: mobileapps/ci
app_icon=$7     # ej: windows/resources/ico.png
current_dir=`pwd`
app_url=`echo $app_name | tr "[:upper:]" "[:lower:]" | tr -d ' '`

function show_usage() {
    echo "usage: $program_name param1 param2 param3"
    echo "param1: .exe path"
    echo "param2: app_name"
    echo "param3: version"
    echo "param4: environment"
    echo "param5: base url"
    echo "param6: output directory"
    echo "use \" \" in params with white spaces"
    exit 1
}

function failed()
{
    local error=${1:-Undefined error}
    echo "Failed: $error" >&2
    exit 1
}

function build_ota_page()
{
  #echo "Generating index.html"
  cat << EOF > $current_dir/index.html
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="initial-scale=1, maximum-scale=1, user-scalable=no">
    <title>$app_name - $version</title>
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
  margin-top: 0px;
  margin-bottom: -5px;
  max-width: 600px;
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
  min-height: 650px;
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
  width: 100%;
  margin-bottom: 25px;
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
      </div>
    </header>
    <main>
      <section class="full download">
        <div class="container">
          <div class="half center handImage">
            <p class="left introText">
            <!-- Bienvenidos a la página de descargas de Viafirma. -->
            </p>
            <img src="https://descargas.viafirma.com/afuentes/img/descargas/splash-windows.png"/>
          </div>
          <div class="half center appInfo">
            <p class="info threeQuarters">Vas a instalar una aplicación externa a la Microsoft Store.</p>
            <div class="threeQuarters infoContainer">
              <div class="appName">
                <span class="icon"></span>
                <h2>$app_name</h2>
                <small>Versión $version</small>
              </div>
              <a class="button"  href="$url/$app_url/windows/$version/$environment/$app_url.exe">Instalar aplicación</a>
              <ul>
                <li>Aplicación compilada el: `date +%d/%m/%Y`</li>
              </ul>
            </div>
          </div>
        </div>
      </section>
    </main>
    <footer class="full">
      <div class="container center">
        <p>&copy; Viafirma - `date +%Y`</p>
      </div>
    </footer>
  </body>
  </html>
EOF
}

function distribute_app()
{
    echo "Distribute app:  $out/$app_url/ios/$version/$environment/"
    export
    firstChar=${out::1}
    if [[ $firstChar != "/" ]] ;
    then
      echo "ftp transfer to :$out"
      sshpass -p $PUBLISH_PASSWORD ssh -t $PUBLISH_USER@$PUBLISH_SERVER mkdir -p $out/$app_url/windows/$version/$environment/
      sshpass -p $PUBLISH_PASSWORD scp $exe $PUBLISH_USER@$PUBLISH_SERVER:$out/$app_url/windows/$version/$environment/$app_url.exe
      sshpass -p $PUBLISH_PASSWORD scp $current_dir/index.html $PUBLISH_USER@$PUBLISH_SERVER:$out/$app_url/windows/$version/$environment/index.html
      sshpass -p $PUBLISH_PASSWORD scp $app_icon $PUBLISH_USER@$PUBLISH_SERVER:$out/$app_url/windows/$version/$environment/icon-1.png
    else
      echo "copy transfer to :$out"
      mkdir -p $out/$app_url/windows/$version/$environment/
      cp -f $exe $out/$app_url/windows/$version/$environment/$app_url.exe
      cp -f $current_dir/index.html $out/$app_url/windows/$version/$environment/index.html
      cp -f $app_icon $out/$app_url/windows/$version/$environment/icon-1.png
    fi

    rm -f $current_dir/index.html
        
    echo "Create URL: $url/$app_url/windows/$version/$environment/"

}



if [ "$#" -ne 7 ]; then
    show_usage
else
  echo
  echo "....... Distribution Info ......."
  echo
  build_ota_page
  distribute_app
  echo
  echo "................................."
fi
