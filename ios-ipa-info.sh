#!/bin/bash

# Configuration
program_name=$0
app=$1

show_usage() {
    echo "usage: $program_name param1"
    echo "param1:	.ipa file"
    exit 1
}

function ipa_info()
{
  cp -P $1 ./info-app.ipa
  unzip info-app.ipa > /dev/null

  expirationDate=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision) | openssl x509 -inform DER -noout -enddate | sed -e 's#notAfter=##'`

  certificateSubject=`/usr/libexec/PlistBuddy -c 'Print DeveloperCertificates:0' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision) | openssl x509 -inform DER -noout -subject`

  cert_uid=`echo $certificateSubject | cut -d \/ -f 2 | cut -d \= -f 2`
  cert_o=`echo $certificateSubject | cut -d \/ -f 3 | cut -d \= -f 2`  certificateSubject="$cert_o ($cert_uid)"

  expirationMobileProvision=`/usr/libexec/PlistBuddy -c 'Print ExpirationDate' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision)`

  uuidMobileProvision=`/usr/libexec/PlistBuddy -c 'Print UUID' /dev/stdin <<< $(security cms -D -i Payload/*.app/embedded.mobileprovision)`

  rm -rf Payload
  rm info-app.ipa
}

function jenkins_summary()
{
  #https://wiki.jenkins-ci.org/display/JENKINS/Summary+Display+Plugin
  echo "Write jenkins_summary.xml"
  cat << EOF > jenkins_summary.xml
<?xml version="1.0" encoding="UTF-8"?>
<section name="Jenkins Summary" fontcolor="#ffffff">
<field name="Firmado por:" value="$certificateSubject">
</field>
<field name="Certificado de distribución válido hasta:" value="$expirationDate">
</field>
<field name="Mobile Provision UUID:" value="$uuidMobileProvision">
</field>
<field name="Mobile Provision válido hasta:" value="$expirationMobileProvision">
</field>
</section>

EOF
}

if [ ${#@} != 1 ]; then
    show_usage
fi

echo
echo "App Info"
ipa_info $app
echo
echo "Firmado por: $certificateSubject"
echo "Certificado de distribución válido hasta: $expirationDate"
echo "Mobile Provision UUID: $uuidMobileProvision"
echo "Mobile Provision válido hasta: $expirationMobileProvision"

jenkins_summary
