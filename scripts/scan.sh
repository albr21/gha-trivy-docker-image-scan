# === Default Variables ===
DOCKER_REGISTRY=""
IMAGE_NAME=""
IMAGE_TAG="latest"
OUTPUT_DIRECTORY="/tmp/trivy/"
OUTPUT_FILENAME="results.json"
TRIVY_DOCKER_IMAGE_NAME="aquasec/trivy"
TRIVY_DOCKER_IMAGE_TAG="0.67.2"
SCAN_SEVERITY="HIGH"
FAIL_ON_VULNERABILITY="false"
DOCKER_SOCK_PATH="/var/run/docker.sock"
SKIP_DB_UPDATE="false"

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# === Parse Arguments ===
set -e

while [ "$#" -gt 0 ]; do
  case "$1" in
    --docker-registry) DOCKER_REGISTRY="$2"; shift 2 ;;
    --image-name) IMAGE_NAME="$2"; shift 2 ;;
    --image-tag) IMAGE_TAG="${2:-$IMAGE_TAG}"; shift 2 ;;
    --scan-severity) SCAN_SEVERITY="${2:-$SCAN_SEVERITY}"; shift 2 ;;
    --fail-on-vulnerability) FAIL_ON_VULNERABILITY="${2:-$FAIL_ON_VULNERABILITY}"; shift 2 ;;
    --docker-sock) DOCKER_SOCK_PATH="$2"; shift 2 ;;
    --output-directory) OUTPUT_DIRECTORY="${2:-$OUTPUT_DIRECTORY}"; shift 2 ;;
    --output-filename) OUTPUT_FILENAME="${2:-$OUTPUT_FILENAME}"; shift 2 ;;
    --trivy-docker-image-name) TRIVY_DOCKER_IMAGE_NAME="${2:-$TRIVY_DOCKER_IMAGE_NAME}"; shift 2 ;;
    --trivy-docker-image-tag) TRIVY_DOCKER_IMAGE_TAG="${2:-$TRIVY_DOCKER_IMAGE_TAG}"; shift 2 ;;
    --skip-db-update) SKIP_DB_UPDATE="${2:-$SKIP_DB_UPDATE}"; shift 2 ;;
    *) echo "::error::Invalid option $1"; exit 1 ;;
  esac
done

# === Validate Arguments ===
if [ -z "$IMAGE_NAME" ] || [ -z "$DOCKER_REGISTRY" ]; then
  echo "::error::Usage: $0 --docker-registry <docker_registry> --image-name <image_name> [--image-tag <image_tag>] [--scan-severity <scan_severity>] [--fail-on-vulnerability <fail_on_vulnerability>] [--docker-sock <docker_sock_path>] [--output-directory <OUTPUT_DIRECTORY>] [--output-filename <output_filename>] [--trivy-docker-image-name <trivy_docker_image_name>] [--trivy-docker-image-tag <trivy_docker_image_tag>] [--skip-db-update <skip_db_update>]"
  exit 1
fi

# === Pull the Trivy Docker Image ===
TRIVY_IMAGE="$TRIVY_DOCKER_IMAGE_NAME:$TRIVY_DOCKER_IMAGE_TAG"
echo "🔧 Pulling Trivy image $TRIVY_IMAGE..."
docker pull "$TRIVY_IMAGE"
echo "✅ Trivy image $TRIVY_IMAGE pulled successfully!"

# === Pull the Docker Image to Scan ===
IMAGE="$DOCKER_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
echo "🔧 Pulling image $IMAGE..."
docker pull "$IMAGE"
echo "✅ Image $IMAGE pulled successfully!"

# === Determine the severity levels to scan ===
severities=("UNKNOWN" "LOW" "MEDIUM" "HIGH" "CRITICAL")
SECURITY_LEVELS=""
found=false
for level in "${severities[@]}"
do
  if [ "$found" = true ] || [ "$level" = "$SCAN_SEVERITY" ]; then
    SECURITY_LEVELS="$SECURITY_LEVELS$level,"
    found=true
  fi
done
SECURITY_LEVELS=${SECURITY_LEVELS%,}
echo "Severity levels: $SECURITY_LEVELS"

# Avoid exiting when there is an error while scanning the Docker Image
set +e

# === Scan the Docker Image ===
if [ -n "$SECURITY_LEVELS" ]; then
  echo "⚙️ Scanning image with Trivy..."
  docker run \
    -v "$DOCKER_SOCK_PATH":"/var/run/docker.sock" \
    -v "$OUTPUT_DIRECTORY":/results \
    "$TRIVY_IMAGE" \
    image --image-src docker "$IMAGE" \
    --format json \
    --output "/results/$OUTPUT_FILENAME.json" \
    --severity $SECURITY_LEVELS \
    $( [ "$SKIP_DB_UPDATE" = "true" ] && echo "--skip-db-update")
  SCAN_EXIT_CODE=$(echo $?)
else
  echo "::warning::No valid severity levels provided. Skipping scan."
fi

# Restore exit on error behavior
set -e

# === Cleanup ===
echo "🧹 Cleaning up..."
docker rmi -f "$IMAGE" >/dev/null 2>&1 || true
docker rmi -f "$TRIVY_IMAGE" >/dev/null 2>&1 || true
docker image prune -f >/dev/null 2>&1 || true
docker builder prune -f >/dev/null 2>&1 || true
echo "✅ Cleanup completed!"

# === Exit with error if vulnerabilities are found and fail-on-vulnerability is true ===
if [ $SCAN_EXIT_CODE -eq 1 ]; then
  echo "⚠️ Vulnerabilities found in the Docker image $IMAGE."
  if [ "$FAIL_ON_VULNERABILITY" = "true" ]; then
    echo "::error::Vulnerabilities found in the Docker image $IMAGE"
    exit 1
  else
    echo "::warning::Vulnerabilities found in the Docker image $IMAGE, but not failing the scan due to fail-on-vulnerability set to false."
  fi
else
  echo "✅ No vulnerabilities found in the Docker image $IMAGE."
fi
