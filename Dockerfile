# syntax=docker/dockerfile:1.7

############################
# 1) Build mediamtx (Go)
############################
FROM --platform=$BUILDPLATFORM golang:1.22-alpine AS build
ARG TARGETOS TARGETARCH
# 👇 main package is the repo root by default
ARG MAIN_PKG=./

WORKDIR /src
RUN apk add --no-cache git ca-certificates build-base

# Cache deps first
COPY go.mod go.sum ./
RUN go mod download

# Bring in the rest of the source
COPY . .

# --- Fix go:embed rpi camera issue (create placeholder if empty)
RUN if [ -d internal/staticsources/rpicamera ]; then \
      mkdir -p internal/staticsources/rpicamera/mtxrpicam_64 && \
      if ! find internal/staticsources/rpicamera/mtxrpicam_64 -mindepth 1 -print -quit | grep -q .; then \
        echo "placeholder" > internal/staticsources/rpicamera/mtxrpicam_64/.keep; \
      fi; \
    fi

# Build only the main package (root by default)
ENV CGO_ENABLED=0
RUN --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/mediamtx "$MAIN_PKG"

############################
# 2) Runtime image
############################
FROM alpine:3.20 AS run
WORKDIR /app

RUN apk add --no-cache ca-certificates tzdata && \
    addgroup -S app && adduser -S app -G app

ENV TZ=Asia/Kolkata \
    MYSQL_HOST=db \
    MYSQL_PORT=3306 \
    MYSQL_USER=vicharak \
    MYSQL_PASSWORD=vicharak2207 \
    MYSQL_DATABASE=kapidhwaj_local

COPY --from=build /out /app

# Optional: include a default config
# COPY ./mediamtx.yml /app/mediamtx.yml

RUN mkdir -p /var/lib/nvr/recordings && \
    chown -R app:app /app /var/lib/nvr
USER app

EXPOSE 8554 8889 9997
ENTRYPOINT ["/app/mediamtx"]
