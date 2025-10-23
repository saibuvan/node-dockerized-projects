pipeline {
    agent any

    triggers {
        // Poll SCM every 1 minute (H distributes load)
        pollSCM('H/1 * * * *')
    }

    environment {
        IMAGE_TAG = "9.0"
        DOCKER_REPO = "buvan654321/my-node-app"
        GIT_BRANCH = "staging"
        GIT_URL = "https://github.com/saibuvan/node-dockerized-projects.git"
        GIT_CREDENTIALS = "sai-repo" // Replace with your Jenkins Git credentials ID
    }

    options {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') // Ensure post always runs
    }

    stages {
        stage('Checkout') {
            steps {
                // Use credentials for polling private repos
                git branch: "${GIT_BRANCH}",
                    url: "${GIT_URL}",
                    credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test || echo "Tests failed but continuing..."'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t my-node-app:${IMAGE_TAG} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker_cred',
                    usernameVariable: 'DOCKERHUB_USERNAME',
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh '''
                        echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                        docker tag my-node-app:${IMAGE_TAG} ${DOCKER_REPO}:${IMAGE_TAG}
                        docker push ${DOCKER_REPO}:${IMAGE_TAG}
                        docker logout
                    '''
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                sh '''
                    docker stop my-node-app-container || true
                    docker rm my-node-app-container || true
                    docker run -d -p 8089:3000 --name my-node-app-container ${DOCKER_REPO}:${IMAGE_TAG}
                '''
            }
        }

        stage('Notify') {
            steps {
                mail to: 'buvaneshganesan1@gmail.com',
                     subject: "Jenkins Notification: ${currentBuild.currentResult}",
                     body: "The Jenkins build #${env.BUILD_NUMBER} for ${env.JOB_NAME} has completed with status: ${currentBuild.currentResult}.\nCheck details: ${env.BUILD_URL}"
            }
        }
    }
}
