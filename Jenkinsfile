pipeline {
    agent any

    tools {
        git 'Default'
    }

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['staging', 'productiom'],
            description: 'Select the environment to deploy'
        )
        choice(
            name: 'TARGET_BRANCH',
            choices: ['develop', 'release/1.0.0', 'main'],
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
        OLD_TAG         = '0.9.0'                        
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

        stage('Install & Test') {
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

                echo "🏗️ Building if build script exists..."
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
                    def port = (params.DEPLOY_ENV == 'staging') ? 3002 : 80

                    try {
                        echo "🚀 Pulling Docker image for deployment..."
                        sh "docker pull ${DOCKERHUB_REPO}:${params.NEW_TAG}"

                        echo "🏃 Running new container temporarily..."
                        sh """
                            docker run -d --name ${tempContainer} -p ${port}:80830d94684923d6 ${DOCKERHUB_REPO}:${params.NEW_TAG}
                        """

                        def status = sh(script: "docker ps | grep ${tempContainer}", returnStatus: true)
                        if (status != 0) {
                            error "❌ New container failed to start"
                        }

                        echo "✅ New container started successfully!"

                        echo "📦 Stopping old container if exists..."
                        sh """
                            if [ \$(docker ps -q -f name=${containerName}) ]; then
                                docker stop ${containerName}
                                docker rm ${containerName}
                            fi
                        """

                        echo "🔄 Renaming new container to main name..."
                        sh "docker rename ${tempContainer} ${containerName}"

                        echo "✅ Deployment to ${params.DEPLOY_ENV} successful!"

                    } catch (err) {
                        echo "❌ Deployment failed. Rolling back..."

                        sh "docker rm -f ${tempContainer} || true"

                        sh """
                            docker pull ${DOCKERHUB_REPO}:${OLD_TAG}
                            docker run -d --name ${containerName} -p ${port}:3002 ${DOCKERHUB_REPO}:${OLD_TAG}
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
