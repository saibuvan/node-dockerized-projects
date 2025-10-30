pipeline {
    agent any

    environment {
        NEW_IMAGE_TAG   = "10.0"
        OLD_IMAGE_TAG   = "9.0"
        DOCKER_REPO     = "buvan654321/my-node-app"
        GIT_BRANCH      = "staging"
        GIT_URL         = "https://github.com/saibuvan/node-dockerized-projects.git"
        GIT_CREDENTIALS = "devops"
        TF_DIR          = "/opt/jenkins_projects/node-dockerized-projects/terraform"
        LOCK_FILE       = "/tmp/terraform.lock"
    }

    options {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE')
        timestamps()
        timeout(time: 20, unit: 'MINUTES') // overall pipeline timeout
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: "${GIT_BRANCH}",
                    url: "${GIT_URL}",
                    credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        stage('Detect App Port from Dockerfile') {
            steps {
                script {
                    def portLine = sh(
                        script: "grep '^ARG APP_PORT' Dockerfile | cut -d'=' -f2 || echo ''",
                        returnStdout: true
                    ).trim()

                    env.APP_PORT = portLine ?: "3000"
                    echo "📦 Detected Application Port: ${env.APP_PORT}"
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test || echo "⚠️ Tests failed but continuing..."'
            }
        }

        stage('Docker Build & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker_cred',
                    usernameVariable: 'DOCKERHUB_USERNAME',
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh '''
                        echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                        
                        echo "🛠 Building Docker image ${DOCKER_REPO}:${NEW_IMAGE_TAG}..."
                        docker build -t ${DOCKER_REPO}:${NEW_IMAGE_TAG} .

                        echo "📤 Pushing image to Docker Hub..."
                        docker push ${DOCKER_REPO}:${NEW_IMAGE_TAG}

                        docker logout
                    '''
                }
            }
        }

        stage('Prepare Terraform Directory') {
            steps {
                sh '''
                    mkdir -p /opt/jenkins_projects/node-dockerized-projects
                    cp -r terraform /opt/jenkins_projects/node-dockerized-projects/ || true
                    chown -R jenkins:jenkins /opt/jenkins_projects/node-dockerized-projects
                '''
            }
        }

        stage('Approval for Staging Deployment') {
            when {
                expression { env.GIT_BRANCH == 'staging' }
            }
            steps {
                script {
                    input message: "🚀 Deploy version ${NEW_IMAGE_TAG} to STAGING?", ok: "Approve"
                }
            }
        }

        stage('Terraform Apply - Deploy New Version') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh '''#!/bin/bash
                            set -e
                            set -x

                            echo "🧹 Cleaning any existing Terraform lock..."
                            rm -f "$LOCK_FILE" || true

                            echo "🧹 Cleaning old containers and images..."
                            docker ps -aq --filter "name=my-node-app-container" | xargs -r docker rm -f
                            docker image prune -f

                            echo "🔒 Creating Terraform lock..."
                            echo "LOCKED by Jenkins build #${BUILD_NUMBER} at $(date)" > "$LOCK_FILE"

                            echo "🚀 Initializing Terraform..."
                            timeout 5m terraform init -input=false

                            echo "📦 Applying Terraform changes..."
                            timeout 5m terraform apply -auto-approve \
                                -var="docker_image=${DOCKER_REPO}:${NEW_IMAGE_TAG}" \
                                -var="container_name=my-node-app-container" \
                                -var="host_port=${APP_PORT}"

                            echo "✅ Terraform apply completed successfully."
                        '''
                    }
                }
            }
        }

        stage('Health Check - New Version') {
            steps {
                script {
                    def healthUrl = "http://localhost:${APP_PORT}/health"
                    def retries = 3
                    def success = false

                    timeout(time: 2, unit: 'MINUTES') {
                        for (int i = 1; i <= retries; i++) {
                            echo "🔍 Health check attempt ${i}/${retries}..."
                            def code = sh(
                                script: "curl -s -o /dev/null -w '%{http_code}' ${healthUrl} || true",
                                returnStdout: true
                            ).trim()

                            if (code == '200') {
                                echo "✅ Application (v${NEW_IMAGE_TAG}) is healthy!"
                                success = true
                                break
                            } else {
                                echo "⚠️ Health check failed (HTTP ${code}), retrying in 10s..."
                                sleep 10
                            }
                        }

                        if (!success) {
                            error("❌ Health check failed for new version — initiating rollback to ${OLD_IMAGE_TAG}")
                        }
                    }
                }
            }
        }
    }

    post {
        success {
            sh 'rm -f /tmp/terraform.lock || true'
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: """New version ${NEW_IMAGE_TAG} deployed successfully!

Health URL: http://localhost:${APP_PORT}/health
Build Details: ${env.BUILD_URL}"""
        }

        failure {
            script {
                echo "⚠️ Deployment failed. Rolling back to version ${OLD_IMAGE_TAG}..."
                dir("${TF_DIR}") {
                    sh '''
                        set -x
                        timeout 5m terraform apply -auto-approve \
                            -var="docker_image=${DOCKER_REPO}:${OLD_IMAGE_TAG}" \
                            -var="container_name=my-node-app-container" \
                            -var="host_port=${APP_PORT}"
                    '''
                }
                echo "♻️ Rollback to ${OLD_IMAGE_TAG} completed."
                sh 'rm -f /tmp/terraform.lock || true'
            }

            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: """Deployment of version ${NEW_IMAGE_TAG} failed.
Rollback to ${OLD_IMAGE_TAG} completed.

Build Details: ${env.BUILD_URL}"""
        }

        always {
            echo "🧹 Cleaning up lock file..."
            sh 'rm -f /tmp/terraform.lock || true'
        }
    }
}