# -------------------------------------------
# STAGE 1 — Build Java App (Maven)
# -------------------------------------------
FROM maven:3.9.6-eclipse-temurin-17 AS builder

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone your repository
RUN git clone https://github.com/KishanGollamudi/onlinebookstore.git .

# Build WAR
RUN mvn clean package -DskipTests


# -------------------------------------------
# STAGE 2 — Tomcat Runtime
# -------------------------------------------
FROM tomcat:10.1-jdk17

# Remove default ROOT app
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy your WAR as ROOT.war
COPY --from=builder /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
