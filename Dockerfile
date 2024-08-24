FROM adoptopenjdk/openjdk11
EXPOSE 8080
ARG JAR_FILE=target/*.jar

# Creates a Group "pipeline" and a User "k8s-pipeline" inside the Docker Container runtime
# It also adds this new user to the "pipeline" group
RUN addgroup pipeline && adduser k8s-pipeline -G pipeline

# COPY - Simply copies files from host system to the Docker image at the path
# ADD - Does everything COPY can do, but also includes features like copying from a URL or unpacking an archive file automatically etc.
# COPY is recommended for clarity and to avoid unintended side effects from ADDs additional features
# We copy the Jar file to the Users directory
COPY ${JAR_FILE} /home/k8s-pipeline/app.jar

# Using the user created to execute the Docker commands from here on as the "k8s-pipeline" User
USER k8s-pipeline

# We need to reference where the jar file to build the application
ENTRYPOINT ["java","-jar","/home/k8s-pipeline/app.jar"]