pipeline {
    agent any 
     tools {
        git 'Default'
    }
    stages{
        stage("checkout scm"){
            steps{
                git url: 'https://github.com/your-org/your-repo.git', branch: 'main'
            }
        }
        stage("test"){
            steps{
                sh 'npm install'
                sh 'npm test'
            }
        }
        stage("build"){
            steps{
                sh 'npm run build'
            }
        }
        stage("Build Images"){
            steps{
                sh 'docker build -t my-node-app:1.0 .'
            }
        }
        stage("Build push") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker_cred', passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                    sh 'docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD'
                    sh 'docker tag my-node-app:1.0 buvan654321/my-node-app:1.0'
                    sh 'docker push buvan654321/my-node-app:1.0'
                    sh 'docker logout'
                }
             }
           }
        post {
           success {
             emailext(
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>Build was successful!</p>
                         <p>Job: ${env.JOB_NAME}</p>
                         <p>Build Number: ${env.BUILD_NUMBER}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }

         }
      }
