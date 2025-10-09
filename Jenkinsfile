pipeline {
    agent any

    tools {
        git 'Default'
    }

    environment {
        APP_NAME = 'my-node-app'
        NEW_TAG = '3.0'
        OLD_TAG = '2.0'
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
                sh 'npm run serve'
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
                            docker run -d --name ${CONTAINER_NAME} -p 87:3001 ${DOCKERHUB_REPO}:${NEW_TAG}
                            sleep 10
                        """

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
                            docker run -d --name ${CONTAINER_NAME} -p 80:3001 ${DOCKERHUB_REPO}:${OLD_TAG}
                        """

                        echo "Rolled back to previous version: ${OLD_TAG}"
                    }
                }
            }
        }

        stage("Remove Old Docker Image") {
            when {
                expression {
                    return currentBuild.result == null || currentBuild.result == 'SUCCESS'
                }
            }
            steps {
                script {
                    echo "Removing old Docker image: ${APP_NAME}:${OLD_TAG}"
                    sh "docker rmi ${APP_NAME}:${OLD_TAG} || true"
                    sh "docker rmi ${DOCKERHUB_REPO}:${OLD_TAG} || true"
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
                body: """<p>❗ Build failed or rollback was triggered.</p>
                         <p>Job: ${env.JOB_NAME}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}

