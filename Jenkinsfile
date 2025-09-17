pipeline {
    agent any 
    stages{
        stage {
            steps{
                checkout scm
            }
        }
        stage {
            steps{
                sh 'sudo npm install'
                sh 'npm test'
            }
        }
        stage {
            steps{
                sh 'npm run build'
            }
        }
    }
}
