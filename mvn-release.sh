#!/bin/bash
FILE="History.md"

function increment_version ()
{
  current_version=$1
  n=${current_version##*[!0-9]}; p=${current_version%%$n}
  next_version=$p$((n+1))
  echo $next_version
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
