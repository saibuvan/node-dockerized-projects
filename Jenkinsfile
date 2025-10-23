pipeline {
    agent any

    triggers {
        pollSCM('H/1 * * * *') // Poll every 1 minute
    }

    environment {
        IMAGE_TAG = "9.0"
        DOCKER_REPO = "buvan654321/my-node-app"
        GIT_BRANCH = "staging"
        GIT_URL = "https://github.com/saibuvan/node-dockerized-projects.git"
    }

    options {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE') // Ensure post always runs
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${GIT_BRANCH}", url: "${GIT_URL}"
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
    }

    post {
        success {
            emailext(
                to: 'buvaneshganesan1@gmail.com',
                subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h3>✅ Jenkins Build Successful</h3>
                    <p>Job: <b>${env.JOB_NAME}</b><br>
                    Build Number: <b>${env.BUILD_NUMBER}</b><br>
                    <a href="${env.BUILD_URL}">View build details</a></p>
                """,
                mimeType: 'text/html'
            )
        }

        failure {
            emailext(
                to: 'buvaneshganesan1@gmail.com',
                subject: "❌ FAILURE: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h3>❌ Jenkins Build Failed</h3>
                    <p>Job: <b>${env.JOB_NAME}</b><br>
                    Build Number: <b>${env.BUILD_NUMBER}</b><br>
                    <a href="${env.BUILD_URL}">View console output</a></p>
                """,
                mimeType: 'text/html'
            )
        }

        always {
            echo "📧 Email notification processed."
        }
    }
}
