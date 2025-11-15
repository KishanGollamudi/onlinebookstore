FROM tomcat:9.0-jdk17-temurin

# Remove default ROOT app
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file built by Maven
COPY target/onlinebookstore.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
