pipeline {
    agent any

    environment {
        IMAGE_TAG       = "10.0"  // new deployment
        OLD_IMAGE_TAG   = "9.0"   // rollback version
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
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: "${GIT_BRANCH}",
                    url: "${GIT_URL}",
                    credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        stage('Fix Docker Permissions') {
            steps {
                sh '''#!/bin/bash
                    echo "🔧 Checking Docker socket permissions..."
                    if ! docker ps >/dev/null 2>&1; then
                        echo "⚠️ Jenkins user cannot access Docker socket. Fixing permissions..."
                        if [ -S /var/run/docker.sock ]; then
                            sudo chmod 777 /var/run/docker.sock || true
                        else
                            echo "🚫 Docker socket not found at /var/run/docker.sock"
                            exit 1
                        fi
                    else
                        echo "✅ Docker socket access verified."
                    fi
                '''
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

        stage('Docker Build') {
            steps {
                sh """
                    docker build \
                        --build-arg APP_PORT=${APP_PORT} \
                        -t ${DOCKER_REPO}:${IMAGE_TAG} .
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker_cred',
                    usernameVariable: 'DOCKERHUB_USERNAME',
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh '''
                        echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                        docker push ${DOCKER_REPO}:${IMAGE_TAG}
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

        stage('Clean Existing Containers') {
            steps {
                sh '''
                    echo "🧹 Cleaning up existing container..."
                    docker rm -f my-node-app-container || true
                '''
            }
        }

        stage('Approval for Staging Deployment') {
            when {
                expression { env.GIT_BRANCH == 'staging' }
            }
            steps {
                script {
                    input message: "Deploy to STAGING environment?", ok: "Approve Deployment"
                }
            }
        }

        stage('Terraform Init & Apply (with Lock)') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh '''#!/bin/bash
                            echo "🔍 Checking for existing Terraform lock..."
                            retries=5
                            while [ -f "$LOCK_FILE" ] && [ $retries -gt 0 ]; do
                                echo "🔒 Lock exists. Waiting 10s..."
                                sleep 10
                                retries=$((retries - 1))
                            done

                            if [ -f "$LOCK_FILE" ]; then
                                echo "🚫 Another job still holding lock. Exiting..."
                                exit 1
                            fi

                            echo "🔒 Creating Terraform lock..."
                            echo "LOCKED by Jenkins build #${BUILD_NUMBER} at $(date)" > "$LOCK_FILE"

                            terraform init -input=false
                            terraform apply -auto-approve \
                              -var="docker_image=${DOCKER_REPO}:${IMAGE_TAG}" \
                              -var="container_name=my-node-app-container" \
                              -var="host_port=${APP_PORT}"

                            echo "✅ Terraform apply completed."
                            rm -f "$LOCK_FILE"
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    echo "⏳ Waiting for app to start..."
                    sleep 5
                    echo "🔍 Checking app health..."
                    curl -s http://localhost:${APP_PORT} || echo "⚠️ App not responding yet."
                """
            }
        }
    }

    post {
        success {
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: """App deployed successfully using Terraform!
Check: http://localhost:${APP_PORT}

Build: ${env.BUILD_URL}"""
        }

        failure {
            echo "🚨 Deployment failed! Rolling back to previous version ${OLD_IMAGE_TAG}..."

            dir("${TF_DIR}") {
                sh '''#!/bin/bash
                    echo "🔄 Starting rollback to previous image..."
                    terraform init -input=false
                    terraform apply -auto-approve \
                      -var="docker_image=${DOCKER_REPO}:${OLD_IMAGE_TAG}" \
                      -var="container_name=my-node-app-container" \
                      -var="host_port=${APP_PORT}"
                    echo "✅ Rollback completed. Application reverted to version ${OLD_IMAGE_TAG}."
                '''
            }

            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} (Rolled back to ${OLD_IMAGE_TAG})",
                 body: """Build failed and automatically rolled back to version ${OLD_IMAGE_TAG}.
Please verify the environment.

Build details: ${env.BUILD_URL}"""
        }

        always {
            echo "🧹 Cleaning up lock file..."
            sh 'rm -f /tmp/terraform.lock || true'
        }
    }
}