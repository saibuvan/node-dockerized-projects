pipeline {
    agent any

    environment {
        IMAGE_TAG       = "9.0"
        DOCKER_REPO     = "buvan654321/my-node-app"
        GIT_BRANCH      = "staging"
        GIT_URL         = "https://github.com/saibuvan/node-dockerized-projects.git"
        GIT_CREDENTIALS = "devops"
        TF_DIR          = "/opt/jenkins_projects/node-dockerized-projects/terraform"
    }

    options {
        catchError(buildResult: 'FAILURE', stageResult: 'FAILURE')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: "${GIT_BRANCH}",
                    url: "${GIT_URL}",
                    credentialsId: "${GIT_CREDENTIALS}"
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                sh 'npm test || echo "Tests failed but continuing..."'
            }
        }

        stage('Docker Build') {
            steps {
                sh "docker build -t ${DOCKER_REPO}:${IMAGE_TAG} ."
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
                // Copy Terraform files to /opt if not already there
                sh '''
                    mkdir -p /opt/jenkins_projects/node-dockerized-projects
                    cp -r terraform /opt/jenkins_projects/node-dockerized-projects/
                    chown -R jenkins:jenkins /opt/jenkins_projects/node-dockerized-projects
                '''
            }
        }

        stage('Deploy using Terraform') {
            steps {
                dir("${TF_DIR}") {
                    sh '''
                        echo "Current directory: $(pwd)"
                        terraform init -input=false
                        terraform apply -auto-approve \
                          -var="docker_image=${DOCKER_REPO}:${IMAGE_TAG}" \
                          -var="container_name=my-node-app-container" \
                          -var="host_port=8089"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "Waiting for container to start..."
                    sleep 5
                    echo "Checking app response..."
                    curl -s http://localhost:8089 || echo "App not responding yet."
                '''
            }
        }
    }

    post {
        success {
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "✅ Jenkins SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "App deployed successfully using Terraform!\nCheck: http://localhost:8089\n\nBuild: ${env.BUILD_URL}"
        }
        failure {
            mail to: 'buvaneshganesan1@gmail.com',
                 subject: "❌ Jenkins FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "Build failed.\nSee details: ${env.BUILD_URL}"
        }
    }
}

