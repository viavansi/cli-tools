#!/bin/bash

FILE="History.md"
CURRENT_DIR=`pwd`
PREVIOUS_TAG=`git rev-list --max-parents=0 HEAD`

echo "Creating changelog for project in $CURRENT_DIR"
git pull --tags

rm $FILE
echo "" >> $FILE

for TAG in `git tag --sort=v:refname|sed 's/\*//g'`;
do 
  echo "" | cat - $FILE > /tmp/out && mv /tmp/out $FILE

  git log --no-merges --date=format:'%d/%m/%Y (%H:%M)' --pretty=format:"  * %h - %ad - (%aN) %s" $PREVIOUS_TAG...$TAG | cat - $FILE > /tmp/out &&
  mv /tmp/out $FILE

  DATE=`git log -1 --format=%ad --date=short $TAG`
  echo "===================" | cat - $FILE > /tmp/out && mv /tmp/out $FILE
  echo "$TAG / $DATE" | cat - $FILE > /tmp/out && mv /tmp/out $FILE
  echo "" | cat - $FILE > /tmp/out && mv /tmp/out $FILE
      
  PREVIOUS_TAG=$TAG
done



