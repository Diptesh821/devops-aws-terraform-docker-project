#!/bin/bash
set -e
backend_private_ip=$1
port_no=$2
echo "Backend IP is: $backend_private_ip"
echo "Installing Docker"
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

sudo docker pull dipteshsingh/frontend
sudo docker images
sudo docker run -d -p ${port_no}:80 -e BACKEND_URL=${backend_private_ip}:5000 --name frontend dipteshsingh/frontend

echo "Waiting for frontend service to start..."
for i in {1..24}; do
  # Use curl to check if the service is responding successfully
  if curl -s --head --fail http://localhost:${port_no} > /dev/null; then
    echo " Frontend service is up and running!"
    exit 0
  fi
  printf "."
  sleep 5
done

echo "Frontend service failed to start within the timeout period."
exit 1
