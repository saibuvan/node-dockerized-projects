pipeline {
    agent any

    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'staging', 'uat', 'preprod', 'prod'], description: 'Select the environment to deploy')
    }

    environment {
        DOCKER_REPO     = "buvan654321/my-node-app"
        GIT_URL         = "https://github.com/saibuvan/node-dockerized-projects.git"
        GIT_CREDENTIALS = "devops"
        TF_DIR          = "${WORKSPACE}/terraform"
        LOCK_FILE       = "/tmp/terraform.lock"

        MINIO_ENDPOINT   = "http://localhost:9000"
        MINIO_BUCKET     = "terraform-state"
        MINIO_REGION     = "us-east-1"
        MINIO_ACCESS_KEY = "minioadmin"
        MINIO_SECRET_KEY = "minioadmin"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout Branch') {
            steps {
                script {
                    def branchMap = [
                        'dev'     : 'dev',
                        'staging' : 'release/release_1',
                        'uat'     : 'release/release_1',
                        'preprod' : 'release/release_1',
                        'prod'    : 'main'
                    ]
                    env.GIT_BRANCH = branchMap[params.DEPLOY_ENV]
                    echo "📦 Checking out branch: ${env.GIT_BRANCH}"

                    checkout([$class: 'GitSCM',
                        branches: [[name: "${env.GIT_BRANCH}"]],
                        userRemoteConfigs: [[
                            url: "${GIT_URL}",
                            credentialsId: "${GIT_CREDENTIALS}"
                        ]]
                    ])
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${params.DEPLOY_ENV}-${env.BUILD_NUMBER}"
                    sh """
                        echo "🐳 Building Docker image..."
                        docker build -t ${DOCKER_REPO}:${IMAGE_TAG} .
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker_cred', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_PASSWORD')]) {
                    sh """
                        echo "\$DOCKERHUB_PASSWORD" | docker login -u "\$DOCKERHUB_USERNAME" --password-stdin
                        docker push ${DOCKER_REPO}:${IMAGE_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Terraform Deploys') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh """
                            echo "🔍 Checking for existing Terraform lock..."
                            if [ -f "$LOCK_FILE" ]; then
                                FILE_AGE=\$(( \$(date +%s) - \$(stat -c %Y "$LOCK_FILE") ))
                                if [ \$FILE_AGE -gt 600 ]; then
                                    echo "🧹 Removing stale lock file..."
                                    rm -f "$LOCK_FILE"
                                else
                                    echo "🚫 Another deployment is running!"
                                    exit 1
                                fi
                            fi

                            echo "LOCKED by Jenkins build #${BUILD_NUMBER}" > "$LOCK_FILE"

                            echo "🔍 Ensuring MinIO alias & bucket..."
                            mc alias set myminio ${MINIO_ENDPOINT} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} --api S3v4 || true
                            mc ls myminio/${MINIO_BUCKET} >/dev/null 2>&1 || mc mb myminio/${MINIO_BUCKET}

                            echo "🧹 Cleaning previous Terraform cache..."
                            rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup || true

                            echo "🪣 Writing backend.tf..."
                            cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket  = "${MINIO_BUCKET}"
    key     = "state/${params.DEPLOY_ENV}/${JOB_NAME}.tfstate"
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

                            echo "📝 Ensuring variables.tf exists..."
                            cat > variables.tf <<EOF
variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "container_name" {
  description = "Docker container name"
  type        = string
  default     = "node_app_container"
}

variable "host_port" {
  description = "Host port to expose"
  type        = number
  default     = 3000
}
EOF

                            echo "🧩 Initializing Terraform..."
                            terraform init -input=false -reconfigure

                            echo "🚀 Applying Terraform changes for ${params.DEPLOY_ENV}..."
                            terraform apply -auto-approve \
                                -var="docker_image=${DOCKER_REPO}:${IMAGE_TAG}" \
                                -var="environment=${params.DEPLOY_ENV}" \
                                -var="container_name=node_app_container" \
                                -var="host_port=3000"

                            echo "✅ Terraform deployment successful."
                            echo "🧾 Verifying tfstate upload to MinIO..."
                            mc ls myminio/${MINIO_BUCKET}/state/${params.DEPLOY_ENV}/${JOB_NAME}.tfstate || echo "⚠️ tfstate file not found in MinIO!"

                            rm -f "$LOCK_FILE"
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    echo "🔍 Verifying app status..."
                    sleep 10
                    curl -f http://localhost:3000 || echo "⚠️ App might not be reachable yet."
                """
            }
        }

        stage('Promotion Confirmation') {
            when { expression { params.DEPLOY_ENV in ['staging', 'uat', 'preprod'] } }
            steps {
                input message: "Promote ${params.DEPLOY_ENV} build to next environment?", ok: "Promote"
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful for ${params.DEPLOY_ENV}"
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER} (${params.DEPLOY_ENV})",
                 body: """Deployment successful in ${params.DEPLOY_ENV} environment.
Docker Image: ${DOCKER_REPO}:${IMAGE_TAG}
Build URL: ${env.BUILD_URL}"""
        }

        failure {
            echo "🚨 Deployment failed for ${params.DEPLOY_ENV}. Rolling back..."
            dir("${TF_DIR}") {
                sh """
                    terraform init -input=false -reconfigure
                    terraform apply -auto-approve -var="docker_image=${DOCKER_REPO}:previous" \
                                              -var="container_name=node_app_container" \
                                              -var="host_port=3000"
                    echo "✅ Rollback completed."
                """
            }
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} (${params.DEPLOY_ENV})",
                 body: """Deployment failed for ${params.DEPLOY_ENV}.
Rollback executed successfully.
Build URL: ${env.BUILD_URL}"""
        }

        always {
            echo "🧹 Cleaning up lock..."
            sh 'rm -f "$LOCK_FILE" || true'
        }
    }
}