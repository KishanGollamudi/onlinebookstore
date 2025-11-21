# -------------------------------------------
# STAGE 1 — Build Java App
# -------------------------------------------
FROM maven:3.9.6-eclipse-temurin-17 AS builder

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone your repository
RUN git clone https://github.com/KishanGollamudi/onlinebookstore.git .

# Build the project
RUN mvn clean package -DskipTests


# -------------------------------------------
# STAGE 2 — Lightweight Runtime
# -------------------------------------------
FROM eclipse-temurin:17-jre

WORKDIR /app

# Copy built JAR
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
