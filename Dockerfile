# syntax=docker/dockerfile:1.7

# -----------------------------
# Stage 1: Build Go binary
# -----------------------------
FROM golang:1.24-alpine AS builder

# Install required tools
RUN apk add --no-cache git bash zip curl

# Set working directory
WORKDIR /app

# Clone the repo
RUN git clone https://github.com/Kapidhwaj-AI/mediamtx-forked . \
    && git checkout production-edge

# Install Go MySQL driver (use go workspaces mode)
RUN go mod tidy && go get github.com/go-sql-driver/mysql


# Generate code and build binary
RUN go generate ./... && \
    CGO_ENABLED=0 go build -o mediamtx .

# -----------------------------
# Stage 2: Runtime container
# -----------------------------
FROM alpine:latest

# Add minimal runtime dependencies
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/mediamtx .

# Expose typical media server ports (adjust as needed)
EXPOSE 8554 1935 8888

CMD ["./mediamtx"]
