pipeline {
    agent any

    tools {
        git 'Default'
    }

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['staging', 'production'],
            description: 'Select the environment to deploy'
        )
        choice(
            name: 'TARGET_BRANCH',
            choices: ['develop', 'main', 'release/1.0.0', 'release/2.0.0'],
            description: 'Select the branch to build and deploy (main or a release branch)'
        )
        string(
            name: 'NEW_TAG',
            defaultValue: '1.0.3',
            description: 'Docker image tag (e.g. 1.0.3)'
        )
    }

    environment {
        APP_NAME        = 'my-node-app'
        OLD_TAG         = '1.0.1'
        DOCKERHUB_REPO  = 'buvan654321/my-node-app'
        CONTAINER_NAME  = 'my-node-app-container'
        GIT_REPO_URL    = 'https://github.com/saibuvan/node-dockerized-projects.git'
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📥 Checking out branch: ${params.TARGET_BRANCH}"
                git branch: "${params.TARGET_BRANCH}", url: "${env.GIT_REPO_URL}"
            }
        }

        stage('Install & Serve') {
            steps {
                sh '''
                echo "📦 Installing dependencies..."
                npm install

                echo "🧪 Running tests..."
                if npm run | grep -q test; then
                    npm test
                else
                    echo "No tests found, skipping."
                fi

                echo "🧹 Killing any old npm serve processes..."
                pkill -f "npm run serve" || true

                echo "🌐 Starting npm serve if serve script exists..."
                if npm run | grep -q serve; then
                    nohup npm run serve > serve.log 2>&1 &
                    echo "✅ npm serve started in background (check serve.log for logs)"
                else
                    echo "❌ No serve script found in package.json"
                    exit 1
                fi
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image: ${APP_NAME}:${params.NEW_TAG}"
                sh "docker build --pull -t ${APP_NAME}:${params.NEW_TAG} ."
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
                        echo "🔐 Logging in to DockerHub..."
                        docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD

                        echo "🏷️ Tagging image..."
                        docker tag ${APP_NAME}:${params.NEW_TAG} ${DOCKERHUB_REPO}:${params.NEW_TAG}

                        echo "📤 Pushing image to DockerHub..."
                        docker push ${DOCKERHUB_REPO}:${params.NEW_TAG}

                        docker logout
                    """
                }
            }
        }

        stage('Deploy with Rollback') {
            steps {
                script {
                    def containerName = (params.DEPLOY_ENV == 'staging') ? "${CONTAINER_NAME}-staging" : "${CONTAINER_NAME}-prod"
                    def tempContainer = "${containerName}-new"
                    def hostPort = (params.DEPLOY_ENV == 'staging') ? 8085 : 8082
                    def containerPort = 3002

                    try {
                        echo "🧹 Removing any existing local image for this NEW_TAG..."
                        sh "docker rmi -f ${DOCKERHUB_REPO}:${params.NEW_TAG} || true"

                        echo "🚀 Pulling Docker image for deployment..."
                        sh "docker pull ${DOCKERHUB_REPO}:${params.NEW_TAG}"

                        echo "🧼 Stopping & removing old container if exists..."
                        sh """
                            if [ \$(docker ps -q -f name=${containerName}) ]; then
                                docker stop ${containerName} || true
                                docker rm -f ${containerName} || true
                            fi
                            if [ \$(docker ps -a -q -f name=${containerName}) ]; then
                                docker rm -f ${containerName} || true
                            fi
                        """

                        echo "🧼 Cleaning up temp container if exists..."
                        sh "docker rm -f ${tempContainer} || true"

                        echo "🏃 Starting new container..."
                        sh """
                            docker run -d \
                                --name ${tempContainer} \
                                -p ${hostPort}:${containerPort} \
                                -e PORT=${containerPort} \
                                ${DOCKERHUB_REPO}:${params.NEW_TAG}
                        """

                        def status = sh(script: "docker ps | grep ${tempContainer}", returnStatus: true)
                        if (status != 0) {
                            error "❌ New container failed to start"
                        }

                        echo "🔄 Renaming new container to ${containerName}..."
                        sh "docker rename ${tempContainer} ${containerName}"

                        echo "✅ Deployment to ${params.DEPLOY_ENV} successful!"

                    } catch (err) {
                        echo "❌ Deployment failed. Rolling back..."
                        sh "docker rm -f ${tempContainer} || true"

                        sh """
                            docker pull ${DOCKERHUB_REPO}:${OLD_TAG}
                            docker run -d \
                                --name ${containerName} \
                                -p ${hostPort}:${containerPort} \
                                -e PORT=${containerPort} \
                                ${DOCKERHUB_REPO}:${OLD_TAG}
                        """
                        echo "♻️ Rollback completed to ${OLD_TAG}."
                        error "Rollback executed!"
                    }
                }
            }
        }

        stage('Cleanup Old Docker Image') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo "🧹 Cleaning old Docker images..."
                sh """
                    docker rmi -f ${APP_NAME}:${OLD_TAG} || true
                    docker rmi -f ${DOCKERHUB_REPO}:${OLD_TAG} || true
                """
            }
        }
    }

    post {
        success {
            emailext(
                subject: "✅ SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>✅ Successfully deployed branch <b>${params.TARGET_BRANCH}</b></p>
                         <p>Tag: <b>${params.NEW_TAG}</b></p>
                         <p>Environment: <b>${params.DEPLOY_ENV}</b></p>
                         <p><a href="${env.BUILD_URL}">View Build</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "❌ FAILURE: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>❌ Deployment failed for branch <b>${params.TARGET_BRANCH}</b></p>
                         <p>Tag: <b>${params.NEW_TAG}</b></p>
                         <p>Environment: <b>${params.DEPLOY_ENV}</b></p>
                         <p><a href="${env.BUILD_URL}">View Build</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
