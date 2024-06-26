# How to use the image
NOTE: Compilation doesn't work for some reason; fails while building. However, the steps followed to compile (written below; take a look!) I believe are not wrong. Needs further investigation.
## Build your project

First, you'll need to build the docker image. For that, cd to the directory containing the dockerfile and use the following command (you should give a `<name>` to your image):  
```bash
docker build -t <name> .
```

Now you can use the image you built to compile your flutter project. Make sure you change `path/to/project` so that it points to your project (use absolute paths). Tell docker the `<name>`of the image you intend to use (the one we built in the previous step).
```bash
docker run --rm -it -v path/to/project:/build --workdir /build <name> flutter build linux
```
NOTE: You should have added linux support to your flutter project prior to this step. If you haven't done it already do:
```bash
docker run --rm -it -v path/to/project:/build --workdir /build <name> flutter create --platforms=linux .
```

## Publish your .desktop to an html
TODO (I have to compile the project first to see what files are created in order to create script that generates html)

## Files created and dependencies required for your linux machine
The executable binary can be found in your project under `build/linux/<build mode>/bundle/`. Alongside your executable binary in the bundle directory there are two directories:
* `lib` contains the required .so library files
* `data` contains the application’s data assets, such as fonts or images

In addition to these files, your application also relies on various operating system libraries that it’s been compiled against.

Make sure the Linux system you are installing your application upon has all of the system libraries required. This may be as simple as:
```bash
sudo apt-get install libgtk-3-0 libblkid1 liblzma5
```
For more information about linux desktop compilation of your flutter project see the flutter docs (https://docs.flutter.dev/desktop).
