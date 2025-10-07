# syntax=docker/dockerfile:1.7

# -----------------------------
# Stage 1: Build Go binary
# -----------------------------
FROM golang:1.22.4-alpine AS builder

# Install required tools
RUN apk add --no-cache git bash zip curl

# Set working directory
WORKDIR /app

# Clone the repo
RUN git clone https://github.com/Kapidhwaj-AI/mediamtx-forked . \
    && git checkout production-edge

# Install Go MySQL driver
RUN go get github.com/go-sql-driver/mysql

# Replace config.go with your custom version
# (Assuming you'll COPY it from your local context

# Generate code and build the binary
RUN go generate ./... && \
    CGO_ENABLED=0 go build -o mediamtx .

# -----------------------------
# Stage 2: Runtime container
# -----------------------------
FROM alpine:latest

# Add minimal runtime dependencies
RUN apk add --no-cache libc6-compat

# Set working directory
WORKDIR /app

# Copy built binary from builder
COPY --from=builder /app/mediamtx .

# Expose necessary ports (customize as needed)
EXPOSE 8554 1935 8888 8889 8880

# Default command
CMD ["./mediamtx"]

