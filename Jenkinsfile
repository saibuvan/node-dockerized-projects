pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out branch: main"
                git branch: 'staging', url: 'https://github.com/saibuvan/node-dockerized-projects.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing npm dependencies...'
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running tests...'
                sh 'npm test'
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh 'docker build -t my-node-app:9.0 .'
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'docker_cred', 
                    usernameVariable: 'DOCKERHUB_USERNAME', 
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh '''
                        echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                        docker tag my-node-app:9.0 buvan654321/my-node-app:9.0
                        docker push buvan654321/my-node-app:9.0
                        docker logout
                    '''
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                echo 'Running Docker container...'
                sh '''
                    # Stop and remove old container if it exists
                    docker stop my-node-app-container || true
                    docker rm my-node-app-container || true

                    # Run the new container
                    docker run -d -p 8089:3000 --name my-node-app-container buvan654321/my-node-app:9.0

                    echo "✅ Container started successfully!"
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Build completed successfully and Docker image pushed!'
        }
        failure {
            echo '❌ Build failed!'
        }
    }
}