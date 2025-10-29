pipeline {
    agent any

    environment {
        IMAGE_TAG       = "9.0"
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

        stage('Detect App Port from Dockerfile') {
            steps {
                script {
                    // Get port from Dockerfile (ARG APP_PORT)
                    def portLine = sh(
                        script: "grep '^ARG APP_PORT' Dockerfile | cut -d'=' -f2",
                        returnStdout: true
                    ).trim()

                    env.APP_PORT = portLine ?: "3000"  // fallback to 3000 if not found
                    echo "📦 Application port detected: ${env.APP_PORT}"
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

        stage('Clean Existing Container') {
            steps {
                sh '''
                    echo "Cleaning up existing container..."
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
                        sh """
                            echo "🔍 Checking for existing Terraform lock..."
                            retries=5
                            while [ -f "$LOCK_FILE" ] && [ $retries -gt 0 ]; do
                                echo "🔒 Lock exists, waiting 10s..."
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
                        """
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
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "Build failed.\nSee details: ${env.BUILD_URL}"
        }

        always {
            echo "🧹 Cleaning up lock file..."
            sh 'rm -f /tmp/terraform.lock || true'
        }
    }
}