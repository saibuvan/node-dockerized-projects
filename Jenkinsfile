pipeline {
    agent any

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['dev', 'staging', 'uat', 'preprod', 'prod'],
            description: 'Select the environment to deploy'
        )
    }

    environment {
        DOCKER_REPO     = "buvan654321/my-node-app"
        GIT_URL         = "https://github.com/saibuvan/node-dockerized-projects.git"
        GIT_CREDENTIALS = "devops"
        TF_DIR          = "${WORKSPACE}/terraform"
        LOCK_FILE       = "/tmp/terraform-${params.DEPLOY_ENV}.lock"

        MINIO_ENDPOINT   = "http://localhost:9000"
        MINIO_BUCKET     = "terraform-state"
        MINIO_REGION     = "us-east-1"
        MINIO_ACCESS_KEY = "minioadmin"
        MINIO_SECRET_KEY = "minioadmin"

        IMAGE_TAG_FILE   = "${WORKSPACE}/last_successful_image_tag.txt"
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

                    checkout([
                        $class: 'GitSCM',
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
            when { expression { params.DEPLOY_ENV == 'dev' } }
            steps {
                script {
                    env.IMAGE_TAG = "${params.DEPLOY_ENV}-${env.BUILD_NUMBER}"
                    sh """
                        echo "🐳 Building Docker image..."
                        docker build -t ${DOCKER_REPO}:${IMAGE_TAG} .
                        echo "${IMAGE_TAG}" > ${IMAGE_TAG_FILE}
                    """
                }
            }
        }

        stage('Use Existing Docker Image for Promotion') {
            when { expression { params.DEPLOY_ENV in ['uat', 'preprod', 'prod'] } }
            steps {
                script {
                    if (fileExists(IMAGE_TAG_FILE)) {
                        env.IMAGE_TAG = readFile(IMAGE_TAG_FILE).trim()
                        echo "📌 Re-using Docker image tag: ${env.IMAGE_TAG} for ${params.DEPLOY_ENV}"
                    } else {
                        error "❌ No previous dev image found. Run dev deployment first."
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker_cred', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_TOKEN')]) {
                    sh """
                        echo "\$DOCKERHUB_TOKEN" | docker login -u "\$DOCKERHUB_USERNAME" --password-stdin
                        docker push ${DOCKER_REPO}:${IMAGE_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Prepare Container & Port') {
            steps {
                script {
                    def CONTAINER_NAME = "node_app_container_${params.DEPLOY_ENV}_${BUILD_NUMBER}"
                    def HOST_PORT
                    switch(params.DEPLOY_ENV) {
                        case 'dev': HOST_PORT = 3100; break
                        case 'staging': HOST_PORT = 3200; break
                        case 'uat': HOST_PORT = 3300; break
                        case 'preprod': HOST_PORT = 3400; break
                        case 'prod': HOST_PORT = 3500; break
                        default: HOST_PORT = 3000
                    }
                    env.CONTAINER_NAME = CONTAINER_NAME
                    env.HOST_PORT = HOST_PORT.toString()

                    // Stop and remove any existing container
                    sh """
                        EXISTING_CONTAINER=\$(docker ps -aq -f "name=node_app_container_${params.DEPLOY_ENV}_")
                        if [ ! -z "\$EXISTING_CONTAINER" ]; then
                            echo "⚠️ Stopping existing container(s)..."
                            docker stop \$EXISTING_CONTAINER || true
                            docker rm \$EXISTING_CONTAINER || true
                        fi

                        # Wait until port is free
                        COUNT=0
                        while lsof -i :${HOST_PORT} > /dev/null; do
                            echo "⚠️ Waiting for port ${HOST_PORT} to be released..."
                            sleep 3
                            COUNT=\$((COUNT + 1))
                            if [ \$COUNT -gt 10 ]; then
                                echo "❌ Port ${HOST_PORT} still in use after 30s. Aborting."
                                exit 1
                            fi
                        done
                        echo "✅ Port ${HOST_PORT} is free."
                    """
                }
            }
        }

        stage('Terraform Deploy') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh """
                            echo "🔍 Checking Terraform lock..."
                            if [ -f "$LOCK_FILE" ]; then
                                FILE_AGE=\$(( \$(date +%s) - \$(stat -c %Y "$LOCK_FILE") ))
                                if [ \$FILE_AGE -gt 600 ]; then
                                    echo "🧹 Removing stale lock..."
                                    rm -f "$LOCK_FILE"
                                else
                                    echo "🚫 Another deployment is running for ${params.DEPLOY_ENV}!"
                                    exit 1
                                fi
                            fi

                            echo "LOCKED by Jenkins build #${BUILD_NUMBER}" > "$LOCK_FILE"

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

                            echo "🧩 Initializing Terraform..."
                            terraform init -input=false -reconfigure

                            echo "🚀 Applying Terraform for ${params.DEPLOY_ENV}..."
                            terraform apply -auto-approve \
                                -var="docker_image=${DOCKER_REPO}:${IMAGE_TAG}" \
                                -var="environment=${params.DEPLOY_ENV}" \
                                -var="container_name=${CONTAINER_NAME}" \
                                -var="host_port=${HOST_PORT}"

                            echo "✅ Deployment successful for ${params.DEPLOY_ENV}"
                            rm -f "$LOCK_FILE"
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                script {
                    def portMap = [
                        dev: 3100,
                        staging: 3200,
                        uat: 3300,
                        preprod: 3400,
                        prod: 3500
                    ]
                    def PORT = portMap[params.DEPLOY_ENV] ?: 3000

                    sh """
                        echo "🔍 Verifying app in container ${params.DEPLOY_ENV}..."
                        sleep 10
                        curl -f http://localhost:${PORT} || echo "⚠️ App might not be reachable yet."
                    """
                }
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
            echo "🚨 Deployment failed for ${params.DEPLOY_ENV}. Please check the logs."
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} (${params.DEPLOY_ENV})",
                 body: """Deployment failed for ${params.DEPLOY_ENV}.
Please review the Jenkins console for details.
Build URL: ${env.BUILD_URL}"""
        }

        always {
            echo "🧹 Cleaning up lock..."
            sh 'rm -f "$LOCK_FILE" || true'
        }
    }
}