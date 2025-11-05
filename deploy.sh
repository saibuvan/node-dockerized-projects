#!/bin/bash
set -e

# ===================================================
# 🌍 Environment Variables
# ===================================================
IMAGE_BASE="buvan654321/my-node-app"
GIT_URL="https://github.com/saibuvan/node-dockerized-projects.git"
GIT_BRANCH="staging"
TF_DIR="/opt/jenkins_projects/node-dockerized-projects/terraform"
LOCK_FILE="/tmp/terraform.lock"

# ---- MinIO ----
MINIO_ENDPOINT="http://localhost:9000"
MINIO_BUCKET="terraform-state"
MINIO_REGION="us-east-1"
MINIO_ACCESS_KEY="minioadmin"
MINIO_SECRET_KEY="minioadmin"

# ---- PostgreSQL ----
POSTGRES_USER="admin"
POSTGRES_PASSWORD="admin123"
POSTGRES_DB="node_app_db"
POSTGRES_PORT="5432"

# ===================================================
# 🕒 Generate Tag & Detect Port
# ===================================================
IMAGE_TAG="build-$(date +%Y%m%d%H%M%S)"
APP_PORT=$(grep '^ARG APP_PORT' Dockerfile 2>/dev/null | cut -d'=' -f2 || echo "3000")

echo "🚀 Starting deployment with image ${IMAGE_BASE}:${IMAGE_TAG}"
echo "🧭 Detected App Port: ${APP_PORT}"

# ===================================================
# 📦 Clone or Update Repo
# ===================================================
if [ ! -d "node-dockerized-projects" ]; then
  git clone -b "${GIT_BRANCH}" "${GIT_URL}" node-dockerized-projects
fi

cd node-dockerized-projects
git fetch origin "${GIT_BRANCH}"
git checkout "${GIT_BRANCH}"
git pull origin "${GIT_BRANCH}"

# ===================================================
# 🐳 Optimized Docker Build (Layer Cache + Mount)
# ===================================================
echo "🐳 Building Docker image with cache mount for node_modules..."

cat > Dockerfile <<'EOF'
FROM node:18

WORKDIR /usr/src/app

# Copy dependency files first
COPY package*.json ./

# Use Docker buildkit mount cache to speed up npm install
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

# Copy rest of the source code
COPY . .

# Expose app port
ARG APP_PORT=3000
EXPOSE ${APP_PORT}

CMD ["node", "app.js"]
EOF

# Enable BuildKit for fast caching
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Build using cache mount
docker build --progress=plain -t ${IMAGE_BASE}:${IMAGE_TAG} .

# ===================================================
# 📤 Push Docker Image
# ===================================================
echo "📤 Pushing image to Docker Hub..."
echo "${DOCKERHUB_PASSWORD}" | docker login -u "${DOCKERHUB_USERNAME}" --password-stdin
docker push ${IMAGE_BASE}:${IMAGE_TAG}
docker logout

# ===================================================
# ⚙️ Terraform Setup
# ===================================================
mkdir -p ${TF_DIR}
cp -r terraform/* ${TF_DIR}/ || true
cd ${TF_DIR}

if [ -f "$LOCK_FILE" ]; then
  echo "🚫 Terraform already running. Exiting..."
  exit 1
fi
echo "LOCKED" > "$LOCK_FILE"

echo "🪣 Writing backend.tf..."
cat > backend.tf <<EOF
terraform {
  backend "s3" {
    bucket                      = "${MINIO_BUCKET}"
    key                         = "state/deploy.tfstate"
    region                      = "${MINIO_REGION}"
    endpoints = { s3 = "${MINIO_ENDPOINT}" }
    access_key                  = "${MINIO_ACCESS_KEY}"
    secret_key                  = "${MINIO_SECRET_KEY}"
    skip_credentials_validation  = true
    skip_metadata_api_check      = true
    skip_requesting_account_id   = true
    use_path_style               = true
  }
}
EOF

# ===================================================
# 🚀 Terraform Apply
# ===================================================
echo "🧩 Initializing Terraform..."
terraform init -input=true -reconfigure

echo "🚀 Applying Terraform..."
terraform apply -auto-approve \
  -var="docker_image=${IMAGE_BASE}:${IMAGE_TAG}" \
  -var="container_name=my-node-app-container" \
  -var="host_port=${APP_PORT}" \
  -var="postgres_user=${POSTGRES_USER}" \
  -var="postgres_password=${POSTGRES_PASSWORD}" \
  -var="postgres_db=${POSTGRES_DB}" \
  -var="postgres_port=${POSTGRES_PORT}"

echo "✅ Terraform Apply Done!"

# ===================================================
# 🔍 Verify Deployment
# ===================================================
echo "⏳ Checking containers..."
sleep 5
docker ps | grep my-node-app-container || echo "⚠️ App container not running."

APP_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-node-app-container)
echo "🌐 App running at: http://${APP_IP}:${APP_PORT}"

# ===================================================
# 🧹 Cleanup
# ===================================================
rm -f "$LOCK_FILE"
echo "✅ Deployment completed successfully!"
