#!/bin/bash
FILE="History.md"

function increment_version ()
{
  declare -a part=( ${1//\./ } )
  declare    new
  declare -i carry=1

  for (( CNTR=${#part[@]}-1; CNTR>=0; CNTR-=1 )); do
    len=${#part[CNTR]}
    new=$((part[CNTR]+carry))
    [ ${#new} -gt $len ] && carry=1 || carry=0
    [ $CNTR -gt 0 ] && part[CNTR]=${new: -len} || part[CNTR]=${new}
  done
  new="${part[*]}"
  echo -e "${new// /.}"
}


VERSION=$(mvn -q \
  -Dexec.executable="echo" \
  -Dexec.args='${project.version}' \
  --non-recursive \
  org.codehaus.mojo:exec-maven-plugin:1.3.1:exec)

NEXT_VERSION=`increment_version $VERSION`
DATE=`date +%Y-%m-%d`
echo "release version: $VERSION at $DATE next version $NEXT_VERSION"
LAST_TAG=`git describe --abbrev=0 --tags`
echo "last release version: $LAST_TAG"
CURRENT_BRANCH=`git rev-parse --abbrev-ref HEAD`

COUNT=`git rev-list $LAST_TAG...HEAD --count`
if [[ $COUNT > 0 ]]; then

  echo "" |cat - $FILE > /tmp/out && mv /tmp/out $FILE
  git log --no-merges --date=format:'%d/%m/%Y (%H:%M)' --pretty=format:"  * %h - %ad - (%aN) %s" $LAST_TAG...HEAD | cat - $FILE > /tmp/out &&
  mv /tmp/out $FILE
  echo "===================" | cat - $FILE > /tmp/out && mv /tmp/out $FILE
  echo "$VERSION / $DATE" | cat - $FILE > /tmp/out && mv /tmp/out $FILE
  echo "" | cat - $FILE > /tmp/out && mv /tmp/out $FILE

  git add $FILE
  git commit -m "release $VERSION"
  git push origin $CURRENT_BRANCH
  git tag $VERSION
  git push origin $VERSION

  mvn versions:set -DgenerateBackupPoms=false -DnewVersion="$NEXT_VERSION"

  git add pom.xml
  git add **/pom.xml
  git commit -m "upgrade version to $NEXT_VERSION"
  git push origin $CURRENT_BRANCH

fi
