#!/usr/bin/env bash
# Build and push the Wanda HA add-on multi-arch image to Google Artifact Registry.
#
# Usage (from anywhere):
#   build-image.sh <version> <wanda-repo-root>
#
# Example:
#   build-image.sh 1.0.0 /home/davide/Documenti/repositories/wanda
#
# Prerequisites:
#   gcloud auth configure-docker europe-west3-docker.pkg.dev
#   docker buildx with multi-arch support
set -euo pipefail

VERSION="${1:?usage: build-image.sh <version> <wanda-repo-root>}"
WANDA_DIR="${2:?usage: build-image.sh <version> <wanda-repo-root>}"
ADDON_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE="europe-west3-docker.pkg.dev/adm-wanda/wanda-public/wanda-agent-ha"

echo "Building wandad binaries from ${WANDA_DIR}/apps/ztna ..."
docker run --rm \
  -v "${WANDA_DIR}/apps/ztna":/src -w /src \
  -e CGO_ENABLED=0 -e GOOS=linux -e GOARCH=arm64 \
  golang:1.26-alpine \
  go build -ldflags="-s -w" -o /src/packaging/homeassistant/wanda-agent/wandad-arm64 ./cmd/agent

docker run --rm \
  -v "${WANDA_DIR}/apps/ztna":/src -w /src \
  -e CGO_ENABLED=0 -e GOOS=linux -e GOARCH=amd64 \
  golang:1.26-alpine \
  go build -ldflags="-s -w" -o /src/packaging/homeassistant/wanda-agent/wandad-amd64 ./cmd/agent

# Copy binaries into this repo for the Docker build context
cp "${WANDA_DIR}/apps/ztna/packaging/homeassistant/wanda-agent/wandad-arm64" "${ADDON_DIR}/wandad-arm64"
cp "${WANDA_DIR}/apps/ztna/packaging/homeassistant/wanda-agent/wandad-amd64" "${ADDON_DIR}/wandad-amd64"

echo "Building and pushing multi-arch image ${IMAGE}:${VERSION} ..."
# TARGETARCH is injected automatically by buildx per platform (arm64 / amd64).
docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag "${IMAGE}:${VERSION}" \
  --tag "${IMAGE}:latest" \
  --push \
  "${ADDON_DIR}"

echo "Done. Image: ${IMAGE}:${VERSION}"