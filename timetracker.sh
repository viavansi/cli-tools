#!/bin/bash

output="/Users/jesus/Desarrollo"
output_file="$output/_timetracker.md"
months="6"

function add_commits()
{
  for f in *; do
      if [[ -d $f ]]; then
          # $f is a directory
          cd $f
          if [[ -d ".git" ]]; then
            count=`git rev-list --all --since=$months.months.ago --author=inyenia --count`
            if [[ $count > 0 && $f != 'mobile-services' ]]; then
              echo "$f: $count commits"
              git log --pretty=format:"%ad;$f-%h;%s" --date=iso --all --since=$months.months.ago --author=inyenia >> $output_file
              echo "" >> $output_file
            fi
          fi
          cd ..
      fi
  done
}

echo "" > $output_file
cd ~/Desarrollo/workspace/java
add_commits
cd ~/Desarrollo/workspace/android
add_commits
cd ~/Desarrollo/workspace/ios
add_commits
cd ~/Desarrollo/workspace/inyenia
add_commits

temporal="$output/timetracker.md"
sort -r $output_file > $temporal
rm $output_file
mv $temporal $output_file
sed -i -e 's/ +0100;/ (/g' $output_file
sed -i -e 's/ +0200;/ (/g' $output_file
sed -i -e 's/;/) /g' $output_file

old_date=""
echo "" > $temporal
while IFS='' read -r line || [[ -n "$line" ]]; do
    date=`echo ${line:0:10}`
    if [ "$date" == "$old_date" ]; then
      echo "${line//$date /}" >> $temporal
    else
      old_date=$date
      if [ "$line" != "" ]; then
        echo "" >> $temporal
        echo $date `date -j -f "%Y-%m-%d" "$date" +'%A'` >> $temporal
        echo "==========" >> $temporal
        echo "${line//$date /}" >> $temporal
      fi
    fi
done < "$output_file"
rm $output_file
mv $temporal $output_file
