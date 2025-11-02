# --- Final Production Image ---
# We start from a lightweight Java 17 image
FROM eclipse-temurin:17-jre-jammy

# Set the working directory inside the container
WORKDIR /app

# Copy the JAR file that Jenkins (Stage 2) ALREADY BUILT.
# This JAR is in the 'target' folder of our workspace.
COPY target/demo-0.0.1-SNAPSHOT.jar app.jar

# Expose port 8080 (the default port for Spring Boot)
EXPOSE 8080

# The command to run when the container starts
ENTRYPOINT ["java", "-jar", "app.jar"]