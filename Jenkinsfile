pipeline {
    agent any
    stages {
      stage('Build Artifact') {
        steps {
          sh "mvn clean package -DskipTests=true"
          archive 'target/*.jar'
        }
      }

      stage('Unit Tests - JUnit and Jacoco') {
        steps {
          sh "mvn test"
        }
        post {
            always {
              junit 'target/surefire-reports/*.xml'
              jacoco execPattern: 'target/jacoco.exec'
            }
        }
      }

      stage('Docker Build and Push') {
        steps {
          withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
            sh 'printenv' // Jenkins ENV Variables available
            sh 'docker build -t dockerdemo786/numeric-app:""$GIT_COMMIT"" .' // Using GIT_COMMIT as version number for Docker image
            sh 'docker push dockerdemo786/numeric-app:""$GIT_COMMIT""'
          }

        }
      }
    }
}