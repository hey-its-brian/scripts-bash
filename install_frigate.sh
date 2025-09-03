#!/bin/bash
```
set -e

echo "📦 Updating system..."
sudo apt update && sudo apt upgrade -y

echo "🐳 Installing Docker..."
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-compose-plugin

echo "✅ Docker installed."

echo "📂 Creating Frigate directories..."
sudo mkdir -p /appdata/frigate/media
sudo mkdir -p /appdata/frigate/config
sudo chown -R $USER:$USER /appdata/frigate

echo "🧠 Writing default Frigate config..."
cat <<EOF > /appdata/frigate/config/config.yml
mqtt:
  enabled: false

˙detectors:
  coral:
    type: edgetpu
    device: pci

cameras:
  example_cam:
    ffmpeg:
      inputs:
        - path: rtsp://USERNAME:PASSWORD@CAMERA_IP:554/stream
          roles:
            - detect
    detect:
      width: 1280
      height: 720
      fps: 5
EOF

echo "🧾 Creating docker-compose.yml..."
cat <<EOF > /appdata/frigate/docker-compose.yml
version: '3.9'
services:
  frigate:
    container_name: frigate
    privileged: true
    restart: unless-stopped
    image: ghcr.io/blakeblackshear/frigate:stable
    shm_size: "64mb"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /appdata/frigate/config:/config:ro
      - /appdata/frigate/media:/media/frigate
    ports:
      - "5000:5000"
      - "8554:8554"
      - "8555:8555/tcp"
      - "8555:8555/udp"
    devices:
      - /dev/apex_0:/dev/apex_0
    environment:
      - FRIGATE_RTSP_PASSWORD=changeme
EOF

echo "🚀 Starting Frigate container..."
cd /appdata/frigate
docker compose up -d

echo "🎉 Frigate is now running at: http://$(hostname -I | awk '{print $1}'):5000"`