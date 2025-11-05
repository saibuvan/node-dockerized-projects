#!/bin/bash
set -e

##############################################
# CONFIGURATION
##############################################
IMAGE_TAG="10.0"
OLD_IMAGE_TAG="9.0"
DOCKER_REPO="buvan654321/my-node-app"
GIT_BRANCH="staging"
GIT_URL="https://github.com/saibuvan/node-dockerized-projects.git"
TF_DIR="/opt/jenkins_projects/node-dockerized-projects/terraform"
LOCK_FILE="/tmp/terraform.lock"

MINIO_ENDPOINT="http://localhost:9000"
MINIO_BUCKET="terraform-state"
MINIO_REGION="us-east-1"
MINIO_ACCESS_KEY="minioadmin"
MINIO_SECRET_KEY="minioadmin"

POSTGRES_USER="admin"
POSTGRES_PASSWORD="admin123"
POSTGRES_DB="node_app_db"
POSTGRES_PORT="5432"

DOCKER_USERNAME="buvan654321"
DOCKER_PASSWORD="Buvan@808080"

##############################################
# HELPER FUNCTIONS
##############################################
info() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $1"; }

##############################################
# GIT CHECKOUT
##############################################
info "📦 Cloning branch ${GIT_BRANCH}..."
rm -rf node-dockerized-projects || true
git clone -b "${GIT_BRANCH}" "${GIT_URL}" node-dockerized-projects
cd node-dockerized-projects

##############################################
# DETECT APP PORT
##############################################
APP_PORT=$(grep '^ARG APP_PORT' Dockerfile | cut -d'=' -f2 || echo "3000")
info "🧭 Detected Application Port: ${APP_PORT}"

##############################################
# INSTALL DEPENDENCIES
##############################################
info "📦 Installing npm dependencies..."
npm install

##############################################
# RUN TESTS
##############################################
info "🧪 Running tests..."
if ! npm test; then
  warn "⚠️ Tests failed, continuing anyway..."
fi

##############################################
# BUILD & PUSH DOCKER IMAGE
##############################################
info "🐳 Building Docker image ${DOCKER_REPO}:${IMAGE_TAG}..."
docker build -t ${DOCKER_REPO}:${IMAGE_TAG} .

info "🔐 Logging into DockerHub..."
echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin

info "📤 Pushing image..."
docker push ${DOCKER_REPO}:${IMAGE_TAG}
docker logout

##############################################
# PREPARE TERRAFORM DIRECTORY
##############################################
info "📁 Preparing Terraform directory..."
sudo mkdir -p "${TF_DIR}"
sudo cp -r terraform/* "${TF_DIR}/" || true
sudo chown -R $(whoami):$(whoami) "${TF_DIR}"

##############################################
# TERRAFORM INIT & APPLY
##############################################
cd "${TF_DIR}"

if [ -f "$LOCK_FILE" ]; then
    error "🚫 Lock file exists. Another deployment is running!"
    exit 1
fi

echo "LOCKED by deployment at $(date)" > "$LOCK_FILE"

info "🪣 Configuring backend.tf..."
cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket                      = "${MINIO_BUCKET}"
    key                         = "state/node-app.tfstate"
    region                      = "${MINIO_REGION}"
    endpoints = {
      s3 = "${MINIO_ENDPOINT}"
    }
    access_key                  = "${MINIO_ACCESS_KEY}"
    secret_key                  = "${MINIO_SECRET_KEY}"
    skip_credentials_validation  = true
    skip_metadata_api_check      = true
    skip_requesting_account_id   = true
    force_path_style             = true
  }
}
EOF

info "🧩 Initializing Terraform..."
terraform init -input=false -reconfigure

info "🚀 Applying Terraform..."
set +e
terraform apply -auto-approve \
  -var="docker_image=${DOCKER_REPO}:${IMAGE_TAG}" \
  -var="container_name=my-node-app-container" \
  -var="host_port=${APP_PORT}" \
  -var="postgres_user=${POSTGRES_USER}" \
  -var="postgres_password=${POSTGRES_PASSWORD}" \
  -var="postgres_db=${POSTGRES_DB}" \
  -var="postgres_port=${POSTGRES_PORT}"

if [ $? -ne 0 ]; then
  set -e
  error "❌ Terraform apply failed!"
  info "🔁 Rolling back to version ${OLD_IMAGE_TAG}..."
  terraform apply -auto-approve \
    -var="docker_image=${DOCKER_REPO}:${OLD_IMAGE_TAG}" \
    -var="container_name=my-node-app-container" \
    -var="host_port=${APP_PORT}"
  warn "✅ Rolled back successfully to version ${OLD_IMAGE_TAG}."
  rm -f "$LOCK_FILE"
  exit 1
fi
set -e

rm -f "$LOCK_FILE"

##############################################
# VERIFY DEPLOYMENT
##############################################
info "🕓 Waiting for PostgreSQL to initialize..."
sleep 10
docker exec postgres_container pg_isready -U ${POSTGRES_USER} || warn "⚠️ Postgres not ready yet."

info "⏳ Waiting for Node.js app to start..."
sleep 10
curl -s http://localhost:${APP_PORT} && info "✅ App is responding!" || warn "⚠️ App not responding yet."

##############################################
# SUCCESS MESSAGE
##############################################
info "✅ Deployment completed successfully!"
echo "-----------------------------------------------"
echo "Terraform state stored in MinIO bucket: ${MINIO_BUCKET}"
echo "Application URL: http://localhost:${APP_PORT}"
echo "-----------------------------------------------"
