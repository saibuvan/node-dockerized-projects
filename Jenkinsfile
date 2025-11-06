pipeline {
    agent any

    environment {
        DOCKER_REPO      = "buvan654321/my-node-app"
        GIT_URL          = "https://github.com/saibuvan/node-dockerized-projects.git"
        GIT_CREDENTIALS  = "devops"
        TF_DIR           = "terraform"
        LOCK_FILE        = "/tmp/terraform.lock"
        MINIO_ENDPOINT   = "http://localhost:9000"
        MINIO_BUCKET     = "tfstate-bucket"
        MINIO_ACCESS_KEY = "minioadmin"
        MINIO_SECRET_KEY = "minioadmin"
        MINIO_REGION     = "us-east-1"
    }

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'qa', 'uat', 'prod'],
            description: 'Select the environment to deploy'
        )
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "🔄 Checking out ${GIT_URL}..."
                git branch: 'staging',
                    credentialsId: "${GIT_CREDENTIALS}",
                    url: "${GIT_URL}"
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                script {
                    // Create unique Docker image tag
                    IMAGE_TAG = "${params.DEPLOY_ENV}-${BUILD_NUMBER}"
                    FULL_IMAGE_NAME = "${DOCKER_REPO}:${IMAGE_TAG}"

                    echo "🐳 Building Docker image: ${FULL_IMAGE_NAME}"

                    // Build Docker image
                    sh "docker build -t ${FULL_IMAGE_NAME} ."

                    // Login & push using Jenkins stored credentials
                    withCredentials([usernamePassword(credentialsId: 'docker-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        echo "🔑 Logging into Docker Hub..."
                        sh """
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                            echo "📤 Pushing Docker image: ${FULL_IMAGE_NAME}"
                            docker push ${FULL_IMAGE_NAME}
                            docker logout
                        """
                    }
                }
            }
        }

        stage('Terraform Deploy') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh """
                            echo "🔒 Checking for Terraform lock..."
                            if [ -f "$LOCK_FILE" ]; then
                                FILE_AGE=\$(( \$(date +%s) - \$(stat -c %Y "$LOCK_FILE") ))
                                if [ \$FILE_AGE -gt 600 ]; then
                                    echo "🧹 Removing stale lock..."
                                    rm -f "$LOCK_FILE"
                                else
                                    echo "🚫 Another deployment is in progress."
                                    exit 1
                                fi
                            fi
                            echo "LOCKED by Jenkins build #${BUILD_NUMBER}" > "$LOCK_FILE"

                            echo "🧹 Cleaning any Docker container using ports 3000–3004..."
                            for PORT in 3000 3001 3002 3003 3004; do
                                USED_CONTAINER=\$(docker ps --filter "publish=\${PORT}" --format "{{.ID}}")
                                if [ ! -z "\$USED_CONTAINER" ]; then
                                    echo "⚠️ Removing container using port \$PORT..."
                                    docker rm -f \$USED_CONTAINER || true
                                fi
                            done

                            echo "🧹 Cleaning Terraform cache..."
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

                            echo "📝 Writing variables.tf..."
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
}
variable "host_port" {
  description = "Host port to expose"
  type        = number
}
EOF

                            CONTAINER_NAME="node_app_container_${params.DEPLOY_ENV}_${BUILD_NUMBER}"

                            # Assign ports per environment
                            case "${params.DEPLOY_ENV}" in
                              dev) HOST_PORT=3001 ;;
                              qa)  HOST_PORT=3002 ;;
                              uat) HOST_PORT=3003 ;;
                              prod) HOST_PORT=3004 ;;
                              *) HOST_PORT=3000 ;;
                            esac

                            echo "🧩 Initializing Terraform..."
                            terraform init -input=false -reconfigure

                            echo "🚀 Applying Terraform for ${params.DEPLOY_ENV}..."
                            terraform apply -auto-approve \
                                -var="docker_image=${FULL_IMAGE_NAME}" \
                                -var="environment=${params.DEPLOY_ENV}" \
                                -var="container_name=\$CONTAINER_NAME" \
                                -var="host_port=\$HOST_PORT"

                            echo "✅ Deployment complete for ${params.DEPLOY_ENV}"
                            rm -f "$LOCK_FILE"
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up workspace..."
            sh "rm -f ${LOCK_FILE} || true"
        }
        failure {
            echo "❌ Build failed. Please check logs."
        }
        success {
            echo "✅ Build & Deployment succeeded!"
        }
    }
}