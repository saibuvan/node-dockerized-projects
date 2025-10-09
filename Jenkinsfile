pipeline {
    agent any

    tools {
        git 'Default'
    }

    parameters {
        string(name: 'BRANCH_NAME', defaultValue: 'main', description: 'Branch to deploy')
        string(name: 'NEW_TAG', defaultValue: '', description: 'Docker image tag (optional, defaults to branch name)')
    }

    environment {
        APP_NAME = 'my-node-app'
        OLD_TAG = 'previous'  // Can be overridden if needed
        DOCKERHUB_REPO = 'buvan654321/my-node-app'
        CONTAINER_NAME = 'my-node-app-container'
    }

    stages {
        stage("Checkout SCM") {
            steps {
                echo "Checking out branch: ${params.BRANCH_NAME}"
                git branch: "${params.BRANCH_NAME}",
                    url: 'https://github.com/saibuvan/node-dockerized-projects.git',
                    credentialsId: 'github-cred'  // optional if repo is private
            }
        }

        stage("Install & Test") {
            steps {
                sh '''
                echo "Installing dependencies..."
                npm install

                echo "Running tests..."
                if npm run | grep -q test; then
                    npm test
                else
                    echo "No test script found. Skipping tests."
                fi

                echo "Running build if available..."
                if npm run | grep -q build; then
                    npm run build
                else
                    echo "No build script found. Skipping build."
                fi

                echo "Running serve if available..."
                if npm run | grep -q serve; then
                    npm run serve
                else
                    echo "No serve script found. Skipping serve."
                fi
                '''
            }
        }

        stage("Build Docker Image") {
            steps {
                script {
                    // Use NEW_TAG param if provided; otherwise derive from branch name
                    env.IMAGE_TAG = params.NEW_TAG ?: params.BRANCH_NAME.replaceAll('/', '-')
                }
                sh "docker build -t ${APP_NAME}:${env.IMAGE_TAG} ."
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
                        docker tag ${APP_NAME}:${IMAGE_TAG} ${DOCKERHUB_REPO}:${IMAGE_TAG}
                        docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}
                        docker logout
                    '''
                }
            }
        }

        stage("Deploy & Rollback") {
            steps {
                script {
                    try {
                        echo "Deploying ${DOCKERHUB_REPO}:${IMAGE_TAG}..."

                        // Tag currently running image as 'previous' for rollback
                        sh """
                        if docker ps -a --format '{{.Names}}' | grep -q ${CONTAINER_NAME}; then
                            CURRENT_IMAGE_ID=\$(docker inspect --format='{{.Image}}' ${CONTAINER_NAME})
                            docker tag \$CURRENT_IMAGE_ID ${DOCKERHUB_REPO}:previous
                            docker push ${DOCKERHUB_REPO}:previous
                        fi
                        """

                        // Stop and remove existing container
                        sh """
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            docker pull ${DOCKERHUB_REPO}:${IMAGE_TAG}
                            docker run -d --name ${CONTAINER_NAME} -p 87:3001 ${DOCKERHUB_REPO}:${IMAGE_TAG}
                            sleep 10
                        """

                        def running = sh(script: "docker ps | grep ${CONTAINER_NAME}", returnStatus: true)
                        if (running != 0) {
                            error "New image failed to start!"
                        }

                        echo "New image deployed successfully."

                    } catch (Exception e) {
                        echo "Deployment failed. Rolling back to previous image..."

                        sh """
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            docker pull ${DOCKERHUB_REPO}:previous
                            docker run -d --name ${CONTAINER_NAME} -p 87:3001 ${DOCKERHUB_REPO}:previous
                        """

                        echo "Rolled back to previous image."
                    }
                }
            }
        }

        stage("Clean Up Old Docker Images") {
            steps {
                script {
                    echo "Removing old Docker images..."
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
                body: """<p>✅ Build and deployment successful!</p>
                         <p>Branch: ${params.BRANCH_NAME}</p>
                         <p>Docker Tag: ${env.IMAGE_TAG}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "❌ FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>❌ Deployment failed or rollback triggered.</p>
                         <p>Branch: ${params.BRANCH_NAME}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
