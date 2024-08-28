// The library name we created in Jenkins that holds the file to send slack notifications
@Library('slack') _

pipeline {
    agent any

    // We can reference these variables in our pipeline and also in scripts used in the pipeline
    environment {
      deploymentName = "devsecops"
      containerName = "devsecops-container"
      serviceName = "devsecops-svc"
      imageName = "dockerdemo786/numeric-app:${GIT_COMMIT}"
      applicationURL = "http://devsecopsdemo786.eastus.cloudapp.azure.com"
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
            sh 'printenv' // Jenkins ENV Variables available.
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
               sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_DEV-deployment_service.yaml'
             },
             "Kubesec Scan": {
               sh "bash kubesec-scan.sh"
             },
             "Trivy Scan": { // Returns an exit code (0/1) and either passes or fails the pipeline
                sh "bash trivy-k8s-scan.sh"
             })
        }
      }

      // For DEV - 2 Replicas.
      stage('Kubernetes Deployment - DEV') {
        steps {
         parallel(
           "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
             sh "bash k8s-deployment.sh k8s_DEV-deployment_service.yaml default"
            }
           },
           "Rollout Status": {
             withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
               sh "bash k8s-deployment-rollout-status.sh default"
             }
           }
         )
        }
      }

      stage('Integration Tests - DEV') {
        steps {
          script {
            try {
              withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
                sh "bash integration-test.sh"
              }
            } catch(e) {

              // If the integration tests fail, rollback to the previous Deployment
              withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
                sh "kubectl -n default rollout undo deploy ${deploymentName}"
              }
              throw e
            }
          }
        }
      }

      stage('OWASP ZAP - DAST') {
        steps {
          withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
            sh 'bash zap.sh' // This script runs the ZAP Test once the application is running
          }
        }
      }

      stage('Promote to PROD?.') {
        steps {
          timeout(time: 2, unit: 'DAYS') {
            input 'Do you want to Approve the Deployment to Production Environment?'
          }
        }
      }

      // Run scans against Master Node, Etcd and Kubelet
      // for potential vulnerabilities in our Cluster configuration
      stage('Kubernetes CIS Benchmark') {
        steps {
          script {
            parallel(
              "Scan Master": {
                sh "bash cis-master.sh"
              },
              "Scan Etcd": {
                sh "bash cis-etcd.sh"
              },
              "Scan Kubelet": {
                sh "bash cis-kubelet.sh"
              }
            )
          }
        }
      }

      // For PROD - 3 Replicas
      // We also specify Pod resource limits for PROD
      /*
      resources:
       requests:
        memory: "256Mi"
        cpu: "200m"
       limits:
        memory: "512Mi"
        cpu: "500m"
      */
      // We are exposing a ClusterIP for this Deployment, to access it externally we will use an Istio Ingress Gateway
      stage('Kubernetes Deployment - PROD') {
        steps {
            parallel(
              "Deployment": {
                withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
                  sh "bash k8s-deployment.sh k8s_PROD-deployment_service.yaml prod"
                }
              },
              "Rollout Status": {
                withKubeConfig([credentialsId: 'kubeconfig']) { // To get access the Kubernetes API Server
                  sh "bash k8s-deployment-rollout-status.sh prod"
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
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report', useWrapperFileDirectly: true])

          // Use sendNotification.groovy from Shared Library and provide current build result as parameter
          sendNotification currentBuild.result


          // Publishes reports of Mutation tests in this directory
          //script {
           //   pitmutation mutationStatsFile '**/target/pit-reports/**/mutation.xml'
          //}
        }

        //success {}
        //failure{}
    }
}


