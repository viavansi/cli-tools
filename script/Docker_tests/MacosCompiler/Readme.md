# Build and distribute a flutter app for mac os
This script is responsible of several things:
 1. It builds you mac app (.app) from your  flutter project
 2. Compresses the .app into a .dmg
 3. Creates a .html linking to the just created dmg file. It also contains info about the app.
## Requirements
 -A machine with mac os
 -Docker
 -Flutter
 -Xcode
NOTE: It may be possible to use docker, and if so, some of these dependencies would no longer be required. Research needed!

## Usage
Run the script with the path to your flutter project as a parameter:
````bash
main_scr.sh path/to/your/project/
```

If you want to publish your app to a local server, you can use a nginx docker image using the following instructions.

1. Create the image. Specify a name.
```bash
docker build -t <name> .
```
2.Run it
```bash
docker run -d -p 80:80 appserver
```
3.Go to localhost on your browser





