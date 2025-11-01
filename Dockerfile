# --- Stage 1: The Build Environment ---
# We use a full JDK (Java Development Kit) image to build the app
FROM eclipse-temurin:17-jdk-jammy as builder

# Set the working directory inside the container
WORKDIR /app

# Copy just the pom.xml and mvnw wrapper first.
# This is a Docker caching trick. If these files don't change,
# Docker re-uses the downloaded dependencies from a previous build.
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# Download all the dependencies
RUN ./mvnw dependency:resolve

# Copy the rest of the source code
COPY src ./src

# Build the application, skipping the tests (we already run them in Jenkins)
RUN ./mvnw package -DskipTests


# --- Stage 2: The Final Production Image ---
# We start from a fresh, lightweight JRE (Java Runtime Environment) image
FROM eclipse-temurin:17-jre-jammy

# Set the working directory
WORKDIR /app

# Copy ONLY the built .jar file from the 'builder' stage
COPY --from=builder /app/target/*.jar app.jar

# Expose port 8080 (the default port for Spring Boot)
EXPOSE 8080

# The command to run when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]