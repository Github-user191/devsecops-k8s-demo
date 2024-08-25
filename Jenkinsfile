pipeline {
    agent any

    // We can reference these variables in our pipeline and also in scripts used in the pipeline
    environment {
      deploymentName = "devsecops"
      containerName = "devsecops-container"
      serviceName = "devsecops-svc"
      imageName = "dockerdemo786/numeric-app:${GIT_COMMIT}"
      applicationURL = "http://devsecopsdemo786.eastus.cloudapp.azure.com/"
      applicationURI = "/increment/99"
    }

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
      }

      stage('Mutation Tests - PIT') {
        when {
            expression { return false } // This will prevent the stage from running
        }

        steps {
            sh "mvn org.pitest:pitest-maven:mutationCoverage"
        }
      }

      stage('SonarQube - SAST') {
          when {
            expression { return false } // This will prevent the stage from running
          }

          steps {
            sh "mvn clean verify sonar:sonar \
                  -Dsonar.projectKey=numeric-application \
                  -Dsonar.projectName='numeric application' \
                  -Dsonar.host.url=http://devsecopsdemo786.eastus.cloudapp.azure.com:9000 \
                  -Dsonar.token=sqp_05d48c71c3494c547d974545dd5f5f4e905a66ee"
          }
      }

      // Run multiple steps in Parallel
      stage('Vulnerability Scan - Docker') {
       steps {
         parallel(
           'Dependency Scan': {
             sh "mvn dependency-check:check"
           },
           'Trivy Scan': { // Returns an exit code (0/1) and either passes or fails the pipeline
             sh "bash trivy-docker-image-scan.sh"
           },
           'OPA Conftest': {
             // --policy is the name of the Config file you want to test
             sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
           })
       }
     }

      stage('Docker Build and Push') {
        steps {
          withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
            sh 'printenv' // Jenkins ENV Variables available
            // Run as root so the Jenkins user can access the necessary files/folders
            sh 'sudo docker build -t dockerdemo786/numeric-app:""$GIT_COMMIT"" .' // Using GIT_COMMIT as version number for Docker image
            sh 'docker push dockerdemo786/numeric-app:""$GIT_COMMIT""'
          }
        }
      }

      stage('Vulnerability Scan - Kubernetes') {
        steps {
          parallel(
             "OPA Scan": {
               sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
             },
             "Kubesec Scan": {
               sh "bash kubesec-scan.sh"
             }
        }
      }


      stage('Kubernetes Deployment - DEV') {
        steps {
         parallel(
           "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
             sh "bash k8s-deployment.sh"
            }
           },
           "Rollout Status": {
             withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
               sh "bash k8s-deployment-rollout-status.sh"
             }
           }
         )
        }
      }
    }

    post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'


          // Publishes reports of Mutation tests in this directory
          script {
              pitmutation mutationStatsFile '**/target/pit-reports/**/mutation.xml'
          }
        }

        //success {}
        //failure{}
    }
}