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
                sh 'docker build -t my-node-app:2.0 .'
            }
        }
        stage("Build push") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker_cred', passwordVariable: 'DOCKERHUB_PASSWORD', usernameVariable: 'DOCKERHUB_USERNAME')]) {
                    sh 'docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD'
                    sh 'docker tag my-node-app:2.0 buvan654321/my-node-app:2.0'
                    sh 'docker push buvan654321/my-node-app:2.0'
                    sh 'docker logout'
                }
             }
           }

         }
      }
