# Used by build-image.sh to produce the published multi-arch image.
# HA Supervisor uses the image: field in config.yaml and never runs this Dockerfile.
# TARGETARCH injected by docker buildx (amd64 | arm64).
FROM alpine:3.19
ARG TARGETARCH=arm64
RUN apk add --no-cache ca-certificates tzdata jq
COPY wandad-${TARGETARCH} /usr/bin/wandad
COPY run.sh /run.sh
RUN chmod +x /usr/bin/wandad /run.sh && mkdir -p /etc/wanda /run/wanda /var/lib/wanda
CMD ["/run.sh"]
