FROM eclipse-temurin:8-jdk
ENV LANG="C.UTF-8"
COPY app.jar /opt/app/app.jar
WORKDIR /opt/app
EXPOSE 6806
CMD ["java", "-Duser.timezone=GMT+08", "-Dsun.jnu.encoding=UTF-8", "-Dfile.encoding=UTF-8", "-jar", "/opt/app/app.jar"]
