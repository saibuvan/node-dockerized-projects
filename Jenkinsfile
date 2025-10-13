pipeline {
    agent any

    tools {
        git 'Default'
    }

    parameters {
        choice(
            name: 'TARGET_BRANCH',
            choices: ['develop', 'main', 'release/1.0.0'],
            description: 'Select the Git branch to build and deploy'
        )
        string(
            name: 'NEW_TAG',
            defaultValue: '',
            description: 'Optional Docker tag (leave blank to auto-generate)'
        )
    }

    environment {
        APP_NAME = 'my-node-app'
        DOCKERHUB_REPO = 'buvan654321/my-node-app'
        CONTAINER_NAME = 'my-node-app-container'
        GIT_REPO_URL = 'https://github.com/saibuvan/node-dockerized-projects.git'
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "📥 Checking out branch: ${params.TARGET_BRANCH}"
                    git url: "${env.GIT_REPO_URL}", branch: "${params.TARGET_BRANCH}"

                    // Auto-generate Docker tag if not provided
                    if (!params.NEW_TAG?.trim()) {
                        if (params.TARGET_BRANCH.startsWith('release/')) {
                            env.NEW_TAG = params.TARGET_BRANCH.replace('release/', '')
                        } else if (params.TARGET_BRANCH == 'main') {
                            env.NEW_TAG = "prod-${env.BUILD_NUMBER}"
                        } else {
                            env.NEW_TAG = "${params.TARGET_BRANCH}-${env.BUILD_NUMBER}"
                        }
                    } else {
                        env.NEW_TAG = params.NEW_TAG
                    }

                    echo "🏷️ Using Docker tag: ${env.NEW_TAG}"
                }
            }
        }

        stage('Test') {
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
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building image ${APP_NAME}:${env.NEW_TAG}"
                sh "docker build -t ${APP_NAME}:${env.NEW_TAG} ."
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
                        docker tag ${APP_NAME}:${env.NEW_TAG} ${DOCKERHUB_REPO}:${env.NEW_TAG}
                        docker push ${DOCKERHUB_REPO}:${env.NEW_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Deploy to Staging') {
            when {
                expression { return params.TARGET_BRANCH.startsWith('release/') }
            }
            steps {
                echo "🚀 Deploying release branch to Staging..."
                sh """
                    docker stop ${CONTAINER_NAME}-staging || true
                    docker rm ${CONTAINER_NAME}-staging || true
                    docker pull ${DOCKERHUB_REPO}:${env.NEW_TAG}
                    docker run -d --name ${CONTAINER_NAME}-staging -p 8080:3001 ${DOCKERHUB_REPO}:${env.NEW_TAG}
                """
            }
        }

        stage('Deploy to Production') {
            when {
                expression { return params.TARGET_BRANCH == 'main' }
            }
            steps {
                echo "🚀 Deploying to Production..."
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                    docker pull ${DOCKERHUB_REPO}:${env.NEW_TAG}
                    docker run -d --name ${CONTAINER_NAME} -p 80:3001 ${DOCKERHUB_REPO}:${env.NEW_TAG}
                """
            }
        }
    }

    post {
        success {
            emailext(
                subject: "✅ SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>Branch: <b>${params.TARGET_BRANCH}</b></p>
                         <p>Tag: ${env.NEW_TAG}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "❌ FAILURE: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>Branch: <b>${params.TARGET_BRANCH}</b> failed to build</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
