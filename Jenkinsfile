pipeline {
    agent any

    tools {
        git 'Default'
    }

    stages {
        stage("Checkout SCM") {
            steps {
                git url: 'https://github.com/your-org/your-repo.git', branch: 'main'
            }
        }

        stage("Test") {
            steps {
                sh 'npm install'
                sh 'npm test'
            }
        }

        stage("Build") {
            steps {
                sh 'npm run build'
            }
        }

        stage("Build Docker Image") {
            steps {
                sh 'docker build -t my-node-app:1.0 .'
            }
        }

        stage("Push Docker Image") {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker_cred', 
                    usernameVariable: 'DOCKERHUB_USERNAME', 
                    passwordVariable: 'DOCKERHUB_PASSWORD'
                )]) {
                    sh 'docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD'
                    sh 'docker tag my-node-app:1.0 buvan654321/my-node-app:1.0'
                    sh 'docker push buvan654321/my-node-app:1.0'
                    sh 'docker logout'
                }
            }
        }
    }

    post {
        success {
            emailext(
                subject: "SUCCESS: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>✅ Build was successful!!!</p>
                         <p>Job: ${env.JOB_NAME}</p>
                         <p>Build Number: ${env.BUILD_NUMBER}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "❌ FAILURE: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'",
                body: """<p>❗ Build failed.</p>
                         <p>Job: ${env.JOB_NAME}</p>
                         <p>Build URL: <a href="${env.BUILD_URL}">${env.BUILD_URL}</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
