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

      stage('Mutation Tests - PIT') {
        when {
              expression { return false } // This will prevent the stage from running
        }

        steps {
            sh "mvn org.pitest:pitest-maven:mutationCoverage"
        }
        post {
            always {
                // Publishes reports of Mutation tests in this directory
                script {
                    pitmutation mutationStatsFile '**/target/pit-reports/**/mutation.xml'
                }
            }
        }
      }

      stage('SonarQube - SAST') {
          steps {
            sh "mvn clean verify sonar:sonar -Dsonar.projectKey=numeric-application \
                  -Dsonar.projectName='numeric application' \
                  -Dsonar.host.url=http://devsecopsdemo786.eastus.cloudapp.azure.com:9000 \
                  -Dsonar.token=sqp_d109ed902eba19447de2b1a57374b89ed36f371e"
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

      stage('Kubernetes Deployment - DEV') {
        steps {
          withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
            // Replace every occurrence of 'replace' with the string dockerdemo786/numeric-app:${GIT_COMMIT} inside the manifest file
            sh "sed -i 's#replace#dockerdemo786/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
            sh "kubectl apply -f k8s_deployment_service.yaml"
          }
        }
      }
    }
}