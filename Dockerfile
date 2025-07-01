FROM ubuntu:latest
WORKDIR /app
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
 && rm -rf /var/lib/apt/lists/*

RUN curl https://rclone.org/install.sh | bash

COPY rclone.conf /root/.config/rclone/rclone.conf



COPY . ./

CMD ["./mediamtx"]
