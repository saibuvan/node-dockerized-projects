pipeline {
    agent any

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['staging', 'production'],
            description: 'Select the environment to deploy'
        )
        choice(
            name: 'TARGET_BRANCH',
            choices: ['dev', 'release/1.0.0', 'main'],
            description: 'Select the branch to build and deploy'
        )
        string(
            name: 'NEW_TAG',
            defaultValue: '1.0.0',
            description: 'Docker image tag (e.g. 1.0.0)'
        )
    }

    environment {
        APP_NAME        = 'my-node-app'
        OLD_TAG         = '0.9.0'
        DOCKERHUB_REPO  = 'buvan654321/my-node-app'
        CONTAINER_NAME  = 'my-node-app-container'
        GIT_REPO_URL    = 'https://github.com/saibuvan/node-dockerized-projects.git'
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📥 Checking out branch: ${params.TARGET_BRANCH}"
                deleteDir()  // 🔥 Clean workspace
                git branch: "${params.TARGET_BRANCH}",
                    url: "${env.GIT_REPO_URL}"
            }
        }

        stage('Install & Test') {
            steps {
                sh '''
                echo "📦 Installing dependencies..."
                npm install

                echo "🧪 Running tests..."
                if npm run | grep -q test; then
                    npm test
                else
                    echo "No tests found, skipping."
                fi

                echo "🏗️ Building if build script exists..."
                if npm run | grep -q build; then
                    npm run build
                else
                    echo "No build script found."
                fi
                '''
            }
        }

        // 👇 Docker Build / Push / Deploy stages remain same as your version
    }

    post {
        success {
            emailext(
                subject: "✅ SUCCESS: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>✅ Successfully deployed branch <b>${params.TARGET_BRANCH}</b></p>
                         <p>Tag: <b>${params.NEW_TAG}</b></p>
                         <p>Environment: <b>${params.DEPLOY_ENV}</b></p>
                         <p><a href="${env.BUILD_URL}">View Build</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                subject: "❌ FAILURE: ${env.JOB_NAME} [${env.BUILD_NUMBER}]",
                body: """<p>❌ Deployment failed for branch <b>${params.TARGET_BRANCH}</b></p>
                         <p>Tag: <b>${params.NEW_TAG}</b></p>
                         <p>Environment: <b>${params.DEPLOY_ENV}</b></p>
                         <p><a href="${env.BUILD_URL}">View Build</a></p>""",
                to: 'buvaneshganesan1@gmail.com',
                mimeType: 'text/html'
            )
        }
    }
}
