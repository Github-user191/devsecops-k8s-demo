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
        stage('Testing Slack') {
            steps {
                sh 'exit 0'
            }
        }

    }

    post {
        always {

          // Use sendNotification.groovy from Shared Library and provide current build result as parameter
          sendNotifications currentBuild.result


          // Publishes reports of Mutation tests in this directory
          //script {
           //   pitmutation mutationStatsFile '**/target/pit-reports/**/mutation.xml'
          //}
        }

        //success {}
        //failure{}
    }
}