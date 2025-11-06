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
        timeout(time: 60, unit: 'MINUTES')
    }

    stages {

        stage('Determine Branch') {
            steps {
                script {
                    env.GIT_BRANCH = switch(params.DEPLOY_ENV) {
                        case 'dev' -> 'develop'
                        case 'staging', 'uat', 'preprod' -> 'release/release_1'
                        default -> 'main'
                    }
                    echo "📦 Will checkout branch: ${env.GIT_BRANCH}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                checkout([$class: 'GitSCM',
                    branches: [[name: "*/${env.GIT_BRANCH}"]],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'CleanBeforeCheckout']],
                    userRemoteConfigs: [[
                        url: "${GIT_URL}",
                        credentialsId: "${GIT_CREDENTIALS}"
                    ]]
                ])
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
                        echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                        docker push ${DOCKER_REPO}:${IMAGE_TAG}
                        docker logout
                    """
                }
            }
        }

        stage('Terraform Deploy') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh """
                            echo "🔍 Checking for existing Terraform lock..."
                            if [ -f "$LOCK_FILE" ]; then
                                FILE_AGE=\$(($(date +%s) - \$(stat -c %Y "$LOCK_FILE")))
                                if [ \$FILE_AGE -gt 600 ]; then
                                    echo "🧹 Removing stale lock file..."
                                    rm -f "$LOCK_FILE"
                                else
                                    echo "🚫 Another deployment is running!"
                                    exit 1
                                fi
                            fi
                            echo "LOCKED by Jenkins build #${BUILD_NUMBER}" > "$LOCK_FILE"

                            echo "🔍 Ensuring MinIO backend bucket exists..."
                            mc alias set myminio ${MINIO_ENDPOINT} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY} --api S3v4
                            mc ls myminio/${MINIO_BUCKET} || mc mb myminio/${MINIO_BUCKET}

                            echo "🧹 Cleaning old Terraform cache..."
                            rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup || true

                            echo "🔧 Writing backend.tf..."
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

                            echo "🧩 Initializing Terraform..."
                            terraform init -input=false -reconfigure

                            echo "🚀 Applying Terraform for ${params.DEPLOY_ENV}..."
                            terraform apply -auto-approve -var="docker_image=${DOCKER_REPO}:${IMAGE_TAG}" -var="environment=${params.DEPLOY_ENV}"

                            echo "✅ Terraform deployment successful."
                            rm -f "$LOCK_FILE"

                            echo "🧾 Verifying tfstate file in MinIO..."
                            mc ls myminio/${MINIO_BUCKET}/state/${params.DEPLOY_ENV}/ || echo "⚠️ tfstate file not found!"
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    echo "🔍 Waiting for app to be ready..."
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
Terraform state bucket: ${MINIO_BUCKET}
Build URL: ${env.BUILD_URL}"""
        }

        failure {
            echo "🚨 Deployment failed for ${params.DEPLOY_ENV}. Rolling back..."
            dir("${TF_DIR}") {
                sh """
                    terraform init -input=false -reconfigure
                    terraform apply -auto-approve -var="docker_image=${DOCKER_REPO}:previous"
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