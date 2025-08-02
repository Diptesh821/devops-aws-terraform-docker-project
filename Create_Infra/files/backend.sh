#!/bin/bash
set -e
port_no=$1
echo "Installing Docker"
sudo rm -rf /var/lib/apt/lists/*
sudo apt-get clean
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt install -y git

sudo docker network create myapp-network || true
sudo docker pull dipteshsingh/feedback-db
sudo docker pull dipteshsingh/backend
sudo docker images
sudo docker volume create pgdata
sudo docker run -d -p 5432:5432 -v pgdata:/var/lib/postgresql/data --name db  --network myapp-network dipteshsingh/feedback-db 
sudo docker run -d -p ${port_no}:5000 -e PGHOST=db --name backend  --network myapp-network dipteshsingh/backend 

echo "Waiting for backend service to start..."
for i in {1..24}; do
  # Use curl to check if the service is responding successfully
  if curl -s --head --fail http://localhost:${port_no} > /dev/null; then
    echo " Backend service is up and running!"
    exit 0
  fi
  printf "."
  sleep 10
done

echo " Backend service failed to start within the timeout period."
exit 1
