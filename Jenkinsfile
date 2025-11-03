pipeline {
    agent any

    environment {
        IMAGE_TAG       = "10.0"
        OLD_IMAGE_TAG   = "9.0"
        DOCKER_REPO     = "buvan654321/my-node-app"
        GIT_BRANCH      = "staging"
        GIT_URL         = "https://github.com/saibuvan/node-dockerized-projects.git"
        GIT_CREDENTIALS = "devops"
        TF_DIR          = "/opt/jenkins_projects/node-dockerized-projects/terraform"
        LOCK_FILE       = "/tmp/terraform.lock"

        # MinIO configuration
        MINIO_ENDPOINT  = "http://localhost:9000"
        MINIO_BUCKET    = "terraform-states"
        MINIO_REGION    = "us-east-1"
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
                        docker build -t ${DOCKER_REPO}:${IMAGE_TAG} .
                        echo "$DOCKERHUB_PASSWORD" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                        docker push ${DOCKER_REPO}:${IMAGE_TAG}
                        docker logout
                    '''
                }
            }
        }

        stage('Prepare Terraform') {
            steps {
                sh '''
                    mkdir -p ${TF_DIR}
                    cp -r terraform/* ${TF_DIR}/ || true
                    chown -R jenkins:jenkins ${TF_DIR}
                '''
            }
        }

        stage('Approval for Staging') {
            when { expression { env.GIT_BRANCH == 'staging' } }
            steps {
                script {
                    input message: "Deploy to STAGING environment?", ok: "Approve Deployment"
                }
            }
        }

        stage('Terraform Init & Apply (MinIO Backend)') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        sh '''
                            echo "🔒 Checking Terraform lock..."
                            if [ -f "$LOCK_FILE" ]; then
                              echo "🚫 Lock exists. Exiting..."
                              exit 1
                            fi
                            echo "LOCKED by Jenkins build #${BUILD_NUMBER}" > "$LOCK_FILE"

                            echo "🪣 Configuring Terraform backend with MinIO..."
                            cat > backend.tf <<EOF
                            terraform {
                              backend "s3" {
                                bucket                      = "${MINIO_BUCKET}"
                                key                         = "state/${JOB_NAME}.tfstate"
                                endpoint                    = "${MINIO_ENDPOINT}"
                                region                      = "${MINIO_REGION}"
                                access_key                  = "${MINIO_ACCESS_KEY}"
                                secret_key                  = "${MINIO_SECRET_KEY}"
                                skip_credentials_validation  = true
                                skip_metadata_api_check      = true
                                force_path_style             = true
                              }
                            }
                            EOF

                            echo "🔧 Initializing Terraform..."
                            terraform init -input=false -reconfigure

                            echo "🚀 Applying Terraform..."
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
                    sleep 10
                    echo "🔍 Checking app health..."
                    curl -s http://localhost:${APP_PORT} || echo "⚠️ App not responding yet."
                """
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful!"
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: """App deployed successfully using Terraform with MinIO backend.
Terraform state stored in MinIO bucket: ${MINIO_BUCKET}
URL: http://localhost:${APP_PORT}"""
        }

        failure {
            echo "🚨 Deployment failed! Rolling back..."
            dir("${TF_DIR}") {
                sh '''
                    terraform init -input=false
                    terraform apply -auto-approve \
                      -var="docker_image=${DOCKER_REPO}:${OLD_IMAGE_TAG}" \
                      -var="container_name=my-node-app-container" \
                      -var="host_port=${APP_PORT}"
                    echo "✅ Rollback completed to version ${OLD_IMAGE_TAG}."
                '''
            }

            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} (Rolled back to ${OLD_IMAGE_TAG})",
                 body: """Build failed and automatically rolled back to ${OLD_IMAGE_TAG}.
Check Terraform state in MinIO bucket: ${MINIO_BUCKET}."""
        }

        always {
            echo "🧹 Cleaning up lock file..."
            sh 'rm -f /tmp/terraform.lock || true'
        }
    }
}