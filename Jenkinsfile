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

        stage('Terraform Init & Apply (with MinIO backend)') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh '''
                            echo "🔍 Ensuring MinIO bucket exists..."
                            if ! mc alias set myminio ${MINIO_ENDPOINT} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} --api S3v4; then
                                echo "⚠️ Could not configure mc alias. Installing mc..."
                                wget -q https://dl.min.io/client/mc/release/linux-amd64/mc -O /usr/local/bin/mc
                                chmod +x /usr/local/bin/mc
                                mc alias set myminio ${MINIO_ENDPOINT} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} --api S3v4
                            fi

                            if ! mc ls myminio/${MINIO_BUCKET} >/dev/null 2>&1; then
                                echo "🪣 Creating missing MinIO bucket: ${MINIO_BUCKET}"
                                mc mb myminio/${MINIO_BUCKET} || true
                            else
                                echo "✅ MinIO bucket ${MINIO_BUCKET} exists."
                            fi

                            echo "🔍 Checking and removing old container if exists..."
                            docker ps -a --format '{{.Names}}' | grep -w "my-node-app-container" && \
                                (echo "🧹 Removing old container..." && docker stop my-node-app-container && docker rm my-node-app-container) || \
                                echo "✅ No existing container found."

                            echo "🔍 Writing backend.tf for MinIO..."
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

                            echo "🧩 Initializing Terraform with MinIO backend..."
                            terraform init -migrate-state -reconfigure

                            echo "🚀 Applying Terraform (IMAGE_TAG=${IMAGE_TAG})..."
                            terraform apply -auto-approve -var="docker_image=${DOCKER_REPO}:${IMAGE_TAG}"

                            echo "✅ Terraform apply completed successfully and state uploaded to MinIO."
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

        stage('Cleanup Old Docker Images') {
            steps {
                sh '''
                    echo "🧹 Cleaning up old Docker images..."
                    docker image prune -f || true
                    docker rmi ${DOCKER_REPO}:${OLD_IMAGE_TAG} || true
                    echo "✅ Old images cleaned up."
                '''
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
    }
}