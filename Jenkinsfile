pipeline {
    agent any

    tools {
        nodejs 'Default'  // Ensure Node.js is configured in Jenkins under Global Tool Configuration
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing dependencies...'
                sh 'npm apt install npm'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running tests...'
                sh 'npm run build'
            }
        }

        stage('Build Project') {
            steps {
                echo 'Building project...'
                sh 'npm run build'
            }
        }
    }

    post {
        success {
            echo '✅ Build completed successfully!'
        }
        failure {
            echo '❌ Build failed!'
        }
    }
}

