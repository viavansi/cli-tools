#Build environment
#FROM androidsdk/android-30 as build
FROM cirrusci/flutter:stable as build
WORKDIR /app
#Config Environment
ENV PATH="${ANDROID_SDK_ROOT}/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:${PATH}"
COPY gen_apk_html.sh prueba.apk ./
COPY ./flutter_project ./flutter_project
#RUN /bin/bash -c 'flutter upgrade'
RUN /bin/bash -c '(cd flutter_project; \
flutter clean; \
flutter build apk; \
cp **/*.apk /app; )'
RUN ["/bin/bash", "-c", "./gen_apk_html.sh *.apk"]

#Production environment
FROM nginx:1.16.0-alpine
WORKDIR /usr/share/nginx/html/
COPY --from=build /app/prueba.apk /app/index.html .

#Config nginx
EXPOSE 80
