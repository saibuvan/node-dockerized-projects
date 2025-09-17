pipeline {
    agent any 
     tools {
        git 'Default'
    }
    stages{
        stage("checkout scm"){
            steps{
                checkout scm
            }
        }
        stage("test"){
            steps{
                sh 'sudo npm install'
                sh 'npm test'
            }
        }
        stage("build"){
            steps{
                sh 'npm run build'
            }
        }
    }
}
