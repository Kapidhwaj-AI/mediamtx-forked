# syntax=docker/dockerfile:1.7

# -----------------------------
# Stage 1: Build MediaMTX Go binary
# -----------------------------
FROM golang:1.24 AS builder

WORKDIR /app
COPY . .

# deps + build
RUN go mod tidy && go get github.com/go-sql-driver/mysql
RUN go generate ./... && \
    CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o mediamtx .

# -----------------------------
# Stage 2: Build RKMPP stack (MPP + FFmpeg)
# -----------------------------
FROM ubuntu:22.04 AS ffmpeg_builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git ca-certificates build-essential pkg-config \
    yasm nasm cmake \
    libdrm-dev libgbm-dev libudev-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# --- Build Rockchip MPP userspace ---
RUN git clone --depth=1 https://github.com/rockchip-linux/mpp.git /src/mpp
RUN cmake -S /src/mpp -B /src/mpp/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
 && cmake --build /src/mpp/build -j"$(nproc)" \
 && cmake --install /src/mpp/build

# --- Build FFmpeg with RKMPP enabled ---
RUN git clone --depth=1 https://github.com/FFmpeg/FFmpeg.git /src/ffmpeg
RUN cd /src/ffmpeg && \
    ./configure \
      --prefix=/usr/local \
      --enable-gpl \
      --enable-version3 \
      --enable-nonfree \
      --enable-libdrm \
      --enable-rkmpp \
      --enable-openssl \
      --disable-debug \
      --disable-doc \
      --enable-shared && \
    make -j"$(nproc)" && make install

# -----------------------------
# Stage 3: Runtime (glibc) with working ffmpeg+rkmpp
# -----------------------------
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates libdrm2 libgbm1 libssl3 \
    && rm -rf /var/lib/apt/lists/*

# bring in MPP + FFmpeg
COPY --from=ffmpeg_builder /usr/local /usr/local
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
RUN ldconfig || true

WORKDIR /app

# Copy MediaMTX binary
COPY --from=builder /app/mediamtx /app/mediamtx

# Copy config
COPY mediamtx.yml /app/mediamtx.yml

# Ports
EXPOSE 8554/tcp 1935/tcp 8888/tcp 8889/tcp
EXPOSE 8000-8100/udp

CMD ["/app/mediamtx", "/app/mediamtx.yml"]
