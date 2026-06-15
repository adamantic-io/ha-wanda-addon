#!/usr/bin/env bash
# Build and push the Wanda HA add-on multi-arch image to GHCR.
# Run from the wanda repo root:
#   apps/ztna/packaging/homeassistant/wanda-agent/build-image.sh [version]
#
# Prerequisites: docker login ghcr.io, docker buildx with multi-arch support.
set -euo pipefail

IMAGE="ghcr.io/adamantic/wanda-agent-ha"
VERSION="${1:-latest}"
ADDON_DIR="apps/ztna/packaging/homeassistant/wanda-agent"
ZTNA_DIR="apps/ztna"

echo "Building wandad binaries..."
docker run --rm \
  -v "$(pwd)/${ZTNA_DIR}":/src -w /src \
  -e CGO_ENABLED=0 -e GOOS=linux -e GOARCH=arm64 \
  golang:1.26-alpine \
  go build -ldflags="-s -w" -o "/src/packaging/homeassistant/wanda-agent/wandad-arm64" ./cmd/agent

docker run --rm \
  -v "$(pwd)/${ZTNA_DIR}":/src -w /src \
  -e CGO_ENABLED=0 -e GOOS=linux -e GOARCH=amd64 \
  golang:1.26-alpine \
  go build -ldflags="-s -w" -o "/src/packaging/homeassistant/wanda-agent/wandad-amd64" ./cmd/agent

echo "Building and pushing multi-arch image ${IMAGE}:${VERSION}..."
# TARGETARCH is injected automatically by buildx per platform (arm64 / amd64).
docker buildx build \
  --platform linux/arm64,linux/amd64 \
  --tag "${IMAGE}:${VERSION}" \
  --tag "${IMAGE}:latest" \
  --push \
  "${ADDON_DIR}"

echo "Done. Image: ${IMAGE}:${VERSION}"
