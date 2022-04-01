#!/bin/bash

touch index.html

cat > index.html << EOF
<!DOCTYPE html>
<html>
  <head>
    <title>App files</title>
    <meta charset=”utf-8”/>
  </head>
  <body>
    <h1>App files</h1>
EOF

for file in ./builds/*
do
    echo "      <ul>" >> index.html
    echo "        <li><a href="$file">$(basename "$file")</a></li>" >> index.html
done

cat >> index.html << EOF
      </ul>
  </body>
</html>
EOF
