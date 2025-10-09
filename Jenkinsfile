pipeline {
    agent any

    tools {
        git 'Default'
    }

    parameters {
        string(name: 'RELEASE_BRANCH', defaultValue: 'release/1.0.0', description: 'Specify the release branch to deploy')
        string(name: 'NEW_TAG', defaultValue: '1.0.0', description: 'Docker image tag for the release')
    }

    environment {
        APP_NAME = 'my-node-app'
        OLD_TAG = '1.0.0'
        DOCKERHUB_REPO = 'buvan654321/my-node-app'
        CONTAINER_NAME = 'my-node-app-container'
    }

    stages {
        stage("Checkout Release Branch") {
            steps {
                echo "📥 Checking out branch: ${params.RELEASE_BRANCH}"
                git url: 'https://github.com/saibuvan/node-dockerized-projects.git', branch: "${params.RELEASE_BRANCH}"
            }
        }

        stage("Install & Test") {
            steps {
                sh 'npm install'
                sh 'npm test'
                sh 'npm run serve'
            }
        }

        stage("Build Docker Image") {
            steps {
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
                        echo "🚀 Deploying ${DOCKERHUB_REPO}:${params.NEW_TAG} from branch ${params.RELEASE_BRANCH}..."

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

                        echo "✅ Rolled back to 1.0.0 version: ${OLD_TAG}"
                    }
                }
            }
        }
    }

    post {
        success {
            emailext(
                subject: "✅ SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>✅ Successfully deployed branch <b>${params.RELEASE_BRANCH}</b></p>
                         <p>Tag: ${params.NEW_TAG}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "❌ FAILURE: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>❌ Deployment failed for branch <b>${params.RELEASE_BRANCH}</b></p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
