pipeline {
    agent any

    tools {
        git 'Default'
    }

    parameters {
        choice(
            name: 'TARGET_BRANCH',
            choices: ['dev', 'release/1.0.0', 'main'],
            description: 'Select the branch to build and deploy'
        )
        string(
            name: 'NEW_TAG',
            defaultValue: '1.0.0',
            description: 'Docker image tag (e.g. 1.0.0)'
        )
    }

    environment {
        APP_NAME        = 'my-node-app'
        OLD_TAG         = '0.9.0'     // rollback tag
        DOCKERHUB_REPO  = 'buvan654321/my-node-app'
        CONTAINER_NAME  = 'my-node-app-container'
        GIT_REPO_URL    = 'https://github.com/saibuvan/node-dockerized-projects.git'
    }

    stages {
        stage('Checkout') {
            steps {
                echo "📥 Checking out ${params.TARGET_BRANCH}"
                git branch: "${params.TARGET_BRANCH}", url: "${env.GIT_REPO_URL}"
            }
        }

        stage('Install & Test') {
            steps {
                sh '''
                echo "Installing dependencies..."
                npm install

                echo "Running tests..."
                if npm run | grep -q test; then
                    npm test
                else
                    echo "No tests found, skipping."
                fi

                echo "Building if build script exists..."
                if npm run | grep -q build; then
                    npm run build
                else
                    echo "No build script found."
                fi
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image: ${APP_NAME}:${params.NEW_TAG}"
                sh "docker build -t ${APP_NAME}:${params.NEW_TAG} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker_cred',
                    usernameVariable: 'DOCKERHUB_USERNAME',
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh """
                        docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD
                        docker tag ${APP_NAME}:${params.NEW_TAG} ${DOCKERHUB_REPO}:${params.NEW_TAG}
                        docker push ${DOCKERHUB_REPO}:${params.NEW_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Deploy with Rollback') {
            steps {
                script {
                    try {
                        echo "🚀 Deploying ${DOCKERHUB_REPO}:${params.NEW_TAG}"
                        sh """
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true
                            docker pull ${DOCKERHUB_REPO}:${params.NEW_TAG}
                            docker run -d --name ${CONTAINER_NAME} -p 87:3001 ${DOCKERHUB_REPO}:${params.NEW_TAG}
                            sleep 10
                        """

                        def status = sh(script: "docker ps | grep ${CONTAINER_NAME}", returnStatus: true)
                        if (status != 0) {
                            error "Container failed to start"
                        }

                        echo "✅ Deployment successful."

                    } catch (err) {
                        echo "❌ Deployment failed. Rolling back to ${OLD_TAG}"
                        sh """
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true
                            docker pull ${DOCKERHUB_REPO}:${OLD_TAG}
                            docker run -d --name ${CONTAINER_NAME} -p 87:3001 ${DOCKERHUB_REPO}:${OLD_TAG}
                        """
                        error "Rollback completed."
                    }
                }
            }
        }

        stage('Cleanup Old Image') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo "🧹 Cleaning old images..."
                sh """
                    docker rmi ${APP_NAME}:${OLD_TAG} || true
                    docker rmi ${DOCKERHUB_REPO}:${OLD_TAG} || true
                """
            }
        }
    }

    post {
        success {
            emailext(
                subject: "✅ SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>✅ Successfully deployed <b>${params.TARGET_BRANCH}</b></p>
                         <p>Tag: ${params.NEW_TAG}</p>
                         <p><a href="${env.BUILD_URL}">View Build</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "❌ FAILURE: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>❌ Deployment failed for <b>${params.TARGET_BRANCH}</b></p>
                         <p><a href="${env.BUILD_URL}">View Build</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
