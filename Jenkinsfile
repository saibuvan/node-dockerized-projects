pipeline {
    agent any 
     tools {
        git 'default'
    }
    stages{
        stage("checkout scm"){
            steps{
                git url: 'https://github.com/your-org/your-repo.git', branch: 'main'
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
