pipeline {
    agent any

    tools {
        git 'Default'
    }

    parameters {
        choice(
            name: 'TARGET_BRANCH',
            choices: ['main', 'release/1.0.0', 'release/2.0.0'],
            description: 'Select the branch to build and deploy (main or a release branch)'
        )
        string(
            name: 'NEW_TAG',
            defaultValue: '1.0.0',
            description: 'Docker image tag for the build (e.g., 1.0.0)'
        )
    }

    environment {
        APP_NAME = 'my-node-app'
        OLD_TAG = '1.0.0'  // fallback tag for rollback
        DOCKERHUB_REPO = 'buvan654321/my-node-app'
        CONTAINER_NAME = 'my-node-app-container'
        GIT_REPO_URL = 'https://github.com/saibuvan/node-dockerized-projects.git'
    }

    stages {
        stage("Checkout Target Branch") {
            steps {
                echo "📥 Checking out branch: ${params.TARGET_BRANCH}"
                git url: "${env.GIT_REPO_URL}", branch: "${params.TARGET_BRANCH}"
            }
        }

        stage("Install & Test") {
            steps {
                sh 'npm install'
                sh 'npm test'
                // 👇 Use build for main, serve for release (optional)
                script {
                    if (params.TARGET_BRANCH == 'main') {
                        sh 'npm run build'
                    } else {
                        sh 'npm run serve'
                    }
                }
            }
        }

        stage("Build Docker Image") {
            steps {
                echo "🐳 Building Docker image: ${APP_NAME}:${params.NEW_TAG}"
                sh "docker build -t ${APP_NAME}:${params.NEW_TAG} ."
            }
        }

        stage("Push Docker Image") {
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

        stage("Deploy & Rollback") {
            steps {
                script {
                    try {
                        echo "🚀 Deploying ${DOCKERHUB_REPO}:${params.NEW_TAG} from branch ${params.TARGET_BRANCH}..."

                        // Deploy new container
                        sh """
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            docker pull ${DOCKERHUB_REPO}:${params.NEW_TAG}
                            docker run -d --name ${CONTAINER_NAME} -p 87:3001 ${DOCKERHUB_REPO}:${params.NEW_TAG}
                            sleep 10
                        """

                        def running = sh(script: "docker ps | grep ${CONTAINER_NAME}", returnStatus: true)
                        if (running != 0) {
                            error "❌ New container failed to start!"
                        }

                        echo "✅ New image deployed successfully."

                    } catch (Exception e) {
                        echo "🔄 Deployment failed. Rolling back to ${OLD_TAG}..."

                        sh """
                            docker stop ${CONTAINER_NAME} || true
                            docker rm ${CONTAINER_NAME} || true

                            docker pull ${DOCKERHUB_REPO}:${OLD_TAG}
                            docker run -d --name ${CONTAINER_NAME} -p 80:3001 ${DOCKERHUB_REPO}:${OLD_TAG}
                        """

                        echo "✅ Rolled back to ${OLD_TAG} successfully."
                    }
                }
            }
        }
    }

    post {
        success {
            emailext(
                subject: "✅ SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>✅ Successfully deployed branch <b>${params.TARGET_BRANCH}</b></p>
                         <p>Tag: ${params.NEW_TAG}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "❌ FAILURE: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>❌ Deployment failed for branch <b>${params.TARGET_BRANCH}</b></p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
