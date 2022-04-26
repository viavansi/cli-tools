# Docker image description
The Dockerfile in this directory contains the recipe for creating a docker image that will be used to compile a flutter project. Right now, the image supports only compilation of android apps (apk files), but support for other platforms will be added in the future. 
After the compilation has completed, a new html file linking to the recently compiled app will be created. It will also contain information about the app such as name of the application, its build version, etc. The html file, along with the built app, will be taken to a nginx docker image in order to publish those files in a simple web server.

## Usage
1. Move your flutter project directory into a folder named `flutter_project` inside this directory.
2. If you are outside, move into the directory containing the dockerfile for the next step to work
3. The following command will create the final image. Give it a name to differentiate it from other images.
```bash
docker build -t <name> .
```
4. If all building was succesful, you'll now have your nginx image containing your html and app files ready for deployment. For that, use the next command, specifying the name you gave to your image in the previous step:
```bash
docker run -d -p 80:80 <name>
```
5. Open your browser and navigate to localhost to see the result.