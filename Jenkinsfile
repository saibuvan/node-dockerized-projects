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
    }
}
