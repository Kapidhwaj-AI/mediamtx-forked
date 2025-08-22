# syntax=docker/dockerfile:1.7

############################
# 1) Build mediamtx (Go)
############################
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS build
ARG TARGETOS TARGETARCH
WORKDIR /src
RUN apk add --no-cache git ca-certificates

# Cache go mod first
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .
ENV CGO_ENABLED=0
RUN --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/mediamtx ./...

############################
# 2) (Optional) Fetch rclone
############################
# Set RCLONE_VERSION="" to skip bundling rclone.
FROM --platform=$BUILDPLATFORM alpine:3.20 AS rclone
ARG TARGETOS TARGETARCH
ARG RCLONE_VERSION="v1.67.0"

# Map docker arch -> rclone arch labels
# amd64 -> amd64, arm64 -> arm64
RUN case "$TARGETARCH" in \
      amd64)  ARCH=amd64 ;; \
      arm64)  ARCH=arm64 ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac && \
    apk add --no-cache curl unzip ca-certificates && \
    if [ -n "$RCLONE_VERSION" ]; then \
      URL="https://downloads.rclone.org/${RCLONE_VERSION}/rclone-${RCLONE_VERSION}-${TARGETOS}-${ARCH}.zip"; \
      echo "Downloading $URL"; \
      curl -fsSL "$URL" -o /tmp/rclone.zip && \
      unzip -q /tmp/rclone.zip -d /tmp && \
      mv /tmp/rclone-${RCLONE_VERSION}-${TARGETOS}-${ARCH}/rclone /rclone && \
      chmod +x /rclone; \
    else \
      echo "Skipping rclone download"; \
    fi

############################
# 3) Runtime image
############################
FROM alpine:3.20 AS run
WORKDIR /app

# Minimal deps
RUN apk add --no-cache ca-certificates tzdata && \
    addgroup -S app && adduser -S app -G app

ENV TZ=Asia/Kolkata \
    # Default DB envs (overridden by Compose)
    MYSQL_HOST=db \
    MYSQL_PORT=3306 \
    MYSQL_USER=vicharak \
    MYSQL_PASSWORD=vicharak2207 \
    MYSQL_DATABASE=kapidhwaj_local \
    # rclone default config path (if you mount/ copy one)
    RCLONE_CONFIG=/config/rclone/rclone.conf

# Copy binary
COPY --from=build /out/mediamtx /app/mediamtx

# Copy rclone binary if built
COPY --from=rclone /rclone /usr/local/bin/rclone
# Place your rclone.conf either by COPY at build time or volume mount at runtime:
# COPY rclone.conf /config/rclone/rclone.conf

# (Optional) ship a default mediamtx.yml:
# COPY mediamtx.yml /app/mediamtx.yml

# Make sure runtime dirs exist (your Compose mounts recordings there)
RUN mkdir -p /var/lib/nvr/recordings /config/rclone && \
    chown -R app:app /app /var/lib/nvr /config

USER app

EXPOSE 8554 8889 9997
# If you ship a config file in the image, add: ["-config","/app/mediamtx.yml"]
ENTRYPOINT ["/app/mediamtx"]
