# syntax=docker/dockerfile:1

# Build the WAR from the source in the Docker build context. This deliberately
# does not clone a repository so the image always contains the code being built.
FROM maven:3.9.9-eclipse-temurin-17 AS build

WORKDIR /workspace

# Keep dependency downloads cached when only application sources change.
COPY pom.xml ./
RUN mvn --batch-mode --no-transfer-progress dependency:go-offline

COPY src ./src
COPY WebContent ./WebContent
RUN mvn --batch-mode --no-transfer-progress clean package -DskipTests


# This application uses javax.servlet, which Tomcat 9 supports. Tomcat 10+
# requires the incompatible jakarta.servlet namespace.
FROM tomcat:9.0-jdk17-temurin

RUN rm -rf /usr/local/tomcat/webapps/* \
    && groupadd --system tomcat \
    && useradd --system --gid tomcat --home-dir /usr/local/tomcat --shell /usr/sbin/nologin tomcat \
    && chown -R tomcat:tomcat /usr/local/tomcat

COPY --from=build --chown=tomcat:tomcat /workspace/target/onlinebookstore.war /usr/local/tomcat/webapps/ROOT.war

USER tomcat

EXPOSE 8080

CMD ["catalina.sh", "run"]
