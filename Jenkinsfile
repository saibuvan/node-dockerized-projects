pipeline {
    agent any

    tools {
        git 'Default'
    }

    environment {
        APP_NAME = 'my-node-app'
        NEW_TAG = '2.0'
        OLD_TAG = '1.0'
        DOCKERHUB_REPO = 'buvan654321/my-node-app'
        CONTAINER_NAME = 'my-node-app-container'
    }

    stages {
        stage("Checkout SCM") {
            steps {
                git url: 'https://github.com/your-org/your-repo.git', branch: 'main'
            }
        }

        stage("Test") {
            steps {
                sh 'npm install'
                sh 'npm test'
                sh '''
                    npm start &
                    APP_PID=$!
                    sleep 5
                    echo "Checking if app started on port 3000..."
                    curl -s http://localhost:3000 || echo "App failed to start or no response"
                    kill $APP_PID || echo "Failed to stop app"
                '''
            }
        }

        stage("Build") {
            steps {
                sh 'npm run build'
            }
        }

        stage("Build Docker Image") {
            steps {
                sh "docker build -t ${APP_NAME}:${NEW_TAG} ."
            }
        }

        stage("Push Docker Image") {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker_cred', 
                    usernameVariable: 'DOCKERHUB_USERNAME', 
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh '''
                        docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD
                        docker tag ${APP_NAME}:${NEW_TAG} ${DOCKERHUB_REPO}:${NEW_TAG}
                        docker push ${DOCKERHUB_REPO}:${NEW_TAG}
                        docker logout
                    '''
                }
            }
        }

        stage("Deploy & Rollback") {
            steps {
                script {
                    try {
                        echo "Deploying ${DOCKERHUB_REPO}:${NEW_TAG}..."

                        sh """
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            docker pull ${DOCKERHUB_REPO}:${NEW_TAG}
                            docker run -d --name ${CONTAINER_NAME} -p 80:3000 ${DOCKERHUB_REPO}:${NEW_TAG}
                            sleep 10
                        """

                        // Verify container is running
                        def running = sh(script: "docker ps | grep ${CONTAINER_NAME}", returnStatus: true)
                        if (running != 0) {
                            error "New image failed to start!"
                        }

                        echo "New image deployed successfully."

                    } catch (Exception e) {
                        echo "Deployment failed. Rolling back to ${OLD_TAG}..."

                        sh """
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            docker pull ${DOCKERHUB_REPO}:${OLD_TAG}
                            docker run -d --name ${CONTAINER_NAME} -p 80:3000 ${DOCKERHUB_REPO}:${OLD_TAG}
                        """

                        echo "Rolled back to previous version: ${OLD_TAG}"
                    }
                }
            }
        }
    }

    post {
        success {
            emailext(
                subject: "✅ SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>✅ Build was successful!!!</p>
                         <p>Job: ${env.JOB_NAME}</p>
                         <p>Build Number: ${env.BUILD_NUMBER}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "❌ FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>❗ Build failed or rollback was triggered..</p>
                         <p>Job: ${env.JOB_NAME}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
