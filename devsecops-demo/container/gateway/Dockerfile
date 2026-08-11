ARG JAVA_RUNTIME_IMAGE=eclipse-temurin:8-jre
FROM ${JAVA_RUNTIME_IMAGE}

COPY app.jar /opt/app/app.jar
WORKDIR /opt/app
EXPOSE 6880
ENTRYPOINT ["java", "-Dfile.encoding=UTF-8", "-jar", "/opt/app/app.jar"]
