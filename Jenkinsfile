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
                    chown -R jenkins:jenkins ${TF_DIR}
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
                            # 🔍 Handle stale lock
                            if [ -f "$LOCK_FILE" ]; then
                                FILE_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE") ))
                                if [ "$FILE_AGE" -gt 600 ]; then
                                    echo "🧹 Removing stale lock file..."
                                    rm -f "$LOCK_FILE"
                                else
                                    echo "🚫 Lock exists. Another deployment may be running."
                                    exit 1
                                fi
                            fi
                            echo "LOCKED by Jenkins build #${BUILD_NUMBER}" > "$LOCK_FILE"

                            # 🪣 Write backend.tf with updated parameter
                            cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket                      = "${MINIO_BUCKET}"
    key                         = "state/${JOB_NAME}.tfstate"
    region                      = "${MINIO_REGION}"
    endpoints = {
      s3 = "${MINIO_ENDPOINT}"
    }
    access_key                  = "${MINIO_ACCESS_KEY}"
    secret_key                  = "${MINIO_SECRET_KEY}"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }
}
EOF

                            echo "🧩 Initializing Terraform..."
                            terraform init -reconfigure

                            echo "🚀 Applying Terraform (Node.js + PostgreSQL)..."
                            terraform apply -auto-approve \
                              -var="docker_image=${DOCKER_REPO}:${IMAGE_TAG}" \
                              -var="container_name=my-node-app-container" \
                              -var="host_port=${APP_PORT}" \
                              -var="postgres_user=${POSTGRES_USER}" \
                              -var="postgres_password=${POSTGRES_PASSWORD}" \
                              -var="postgres_db=${POSTGRES_DB}" \
                              -var="postgres_port=${POSTGRES_PORT}"

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
                        docker exec postgres_container pg_isready -U ${POSTGRES_USER} || echo "⚠️ Postgres not ready yet."

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
            echo "🚨 Deployment failed! Rolling back to version ${OLD_IMAGE_TAG}..."
            dir("${TF_DIR}") {
                sh '''
                    terraform init
                    terraform apply -auto-approve \
                      -var="docker_image=${DOCKER_REPO}:${OLD_IMAGE_TAG}" \
                      -var="container_name=my-node-app-container" \
                      -var="host_port=${APP_PORT}"
                    echo "✅ Rollback completed to version ${OLD_IMAGE_TAG}."
                '''
            }

            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER} (Rolled back to ${OLD_IMAGE_TAG})",
                 body: """Build failed and rolled back to version ${OLD_IMAGE_TAG}.
Please verify the environment.
Build URL: ${env.BUILD_URL}"""
        }

        always {
            echo "🧹 Cleaning up Terraform lock..."
            sh 'rm -f /tmp/terraform.lock || true'
        }
    }
}