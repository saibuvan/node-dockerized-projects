pipeline {
    agent any 
     tools {
        git 'Git_2.43.0'
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
