pipeline {
    agent any
    stages {
      stage('Build Artifact') {
        steps {
          sh "mvn clean package -DskipTests=true"
          archive 'target/*.jar'
          sh "echo 'Build completed on: ' $(date)"
        }
      }
    }
}