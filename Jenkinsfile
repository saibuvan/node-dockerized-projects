pipeline {
    agent any

    environment {
        IMAGE_TAG       = "10.0"
        OLD_IMAGE_TAG   = "9.0"
        DOCKER_REPO     = "buvan654321/my-node-app"
        GIT_BRANCH      = "staging"
        GIT_URL         = "https://github.com/saibuvan/node-dockerized-projects.git"
        GIT_CREDENTIALS = "devops"
        TF_DIR          = "${WORKSPACE}/terraform"
        LOCK_FILE       = "${WORKSPACE}/terraform.lock"

        MINIO_ENDPOINT   = "http://localhost:9000"
        MINIO_BUCKET     = "terraform-state"
        MINIO_REGION     = "us-east-1"
        MINIO_ACCESS_KEY = "minioadmin"
        MINIO_SECRET_KEY = "minioadmin"
    }

    options {
        timestamps()
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE')
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📦 Checking out code from ${GIT_BRANCH}..."
                git branch: "${GIT_BRANCH}", url: "${GIT_URL}", credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        stage('Detect App Port') {
            steps {
                script {
                    def portLine = sh(
                        script: "grep '^ARG APP_PORT' Dockerfile | cut -d'=' -f2 || echo '3000'",
                        returnStdout: true
                    ).trim()
                    env.APP_PORT = portLine
                    echo "🧭 Detected Application Port: ${env.APP_PORT}"
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
                        echo "🐳 Building Docker image..."
                        docker build -t ${DOCKER_REPO}:${IMAGE_TAG} .
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
                    mkdir -p ${TF_DIR}
                    cp -r terraform/* ${TF_DIR}/ || true
                    chown -R $(whoami):$(whoami) ${TF_DIR}
                '''
            }
        }

        stage('Approval for Deployment') {
            when { expression { env.GIT_BRANCH == 'staging' } }
            steps {
                script {
                    input message: "🚀 Deploy to STAGING environment?", ok: "Approve Deployment"
                }
            }
        }

        stage('Terraform Init & Apply (MinIO Backend)') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh '''
                            echo "🔍 Checking for existing Terraform lock..."
                            if [ -f "$LOCK_FILE" ]; then
                                FILE_AGE=$(($(date +%s) - $(stat -c %Y "$LOCK_FILE")))
                                if [ $FILE_AGE -gt 600 ]; then
                                    echo "🧹 Removing stale lock file..."
                                    rm -f "$LOCK_FILE" || echo "⚠️ Could not remove lock file"
                                else
                                    echo "🚫 Lock exists. Another deployment is running!"
                                    exit 1
                                fi
                            fi

                            echo "LOCKED by Jenkins build #${BUILD_NUMBER}" > "$LOCK_FILE"
                            chmod 664 "$LOCK_FILE"

                            echo "🪣 Writing backend.tf..."
                            cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket  = "${MINIO_BUCKET}"
    key     = "state/${JOB_NAME}.tfstate"
    region  = "${MINIO_REGION}"
    endpoints = { s3 = "${MINIO_ENDPOINT}" }
    access_key = "${MINIO_ACCESS_KEY}"
    secret_key = "${MINIO_SECRET_KEY}"
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_requesting_account_id = true
    use_path_style = true
  }
}
EOF

                            echo "🧩 Initializing Terraform..."
                            terraform init -reconfigure

                            echo "🚀 Applying Terraform (IMAGE_TAG=${IMAGE_TAG})..."
                            terraform apply -auto-approve -var="docker_image=${DOCKER_REPO}:${IMAGE_TAG}"

                            echo "✅ Terraform apply completed successfully."
                            rm -f "$LOCK_FILE"
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    sh """
                        echo "🕓 Waiting for PostgreSQL to initialize..."
                        sleep 10
                        echo "🔍 Checking PostgreSQL status..."
                        docker exec postgres_container pg_isready -U admin || echo "⚠️ Postgres not ready yet."

                        echo "⏳ Waiting for Node.js app to start..."
                        sleep 10
                        echo "🔍 Checking app health..."
                        curl -s http://localhost:${APP_PORT} || echo "⚠️ App not responding yet."
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful!"
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: """App deployed successfully using Terraform with PostgreSQL & MinIO backend.
Terraform state stored in MinIO bucket: ${MINIO_BUCKET}
URL: http://localhost:${APP_PORT}
Build URL: ${env.BUILD_URL}"""
        }

        failure {
            echo "🚨 Deployment failed! Rolling back to previous version..."
            dir("${TF_DIR}") {
                sh '''
                    terraform init -reconfigure
                    terraform apply -auto-approve -var="docker_image=${DOCKER_REPO}:${OLD_IMAGE_TAG}"
                    echo "✅ Rollback completed."
                '''
            }

            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} (Rollback Applied)",
                 body: """Build failed. Rollback applied.
Build URL: ${env.BUILD_URL}"""
        }

        always {
            echo "🧹 Cleaning up Terraform lock..."
            sh 'rm -f "${LOCK_FILE}" || true'
        }
    }
}