#Build environment
#FROM androidsdk/android-30 as build
FROM cirrusci/flutter:stable as build
WORKDIR /app
#Config Environment
ENV PATH="${ANDROID_SDK_ROOT}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:${PATH}"
COPY gen_apk_html.sh ./
COPY ${proj_path} ./flutter_project
#RUN /bin/bash -c 'flutter upgrade'
RUN /bin/bash -c '(cd flutter_project && \
flutter clean && \
if flutter build apk ; \
then cp build/app/outputs/apk/release/*.apk /app ; \
else echo "Build failed" ; fi )'
RUN ["/bin/bash", "-c", "./gen_apk_html.sh *.apk"]

#Production environment
FROM nginx:1.16.0-alpine
WORKDIR /usr/share/nginx/html/
COPY --from=build /app/*.apk /app/*.html .

#Config nginx
EXPOSE 80
