#!/bin/bash

# Variables
DOCKER_IMAGE="your-dockerhub-username/your-app-image"
NGINX_CONF="/home/ubuntu/Blue-Green/nginx.conf"  # Update this path to your nginx.conf location

# Step 1: Build and deploy the new version (green)
echo "Building and deploying the new version (green)..."
docker build -t $DOCKER_IMAGE:green ./Green
docker-compose up -d app-green

# Step 2: Wait for the green container to be healthy
echo "Waiting for the green container to be healthy..."
sleep 10  # Adjust the sleep time as needed

# Step 3: Test the green container
echo "Testing the green container..."
GREEN_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" http://localhost:8002)

if [ "$GREEN_STATUS" != "200" ]; then
  echo "Error: Green container is not healthy. Deployment aborted."
  exit 1
fi

# Step 4: Update Nginx to route traffic to green
echo "Switching traffic to the new version (green)..."
sed -i 's/server app-blue:8000;/server app-green:8000;/g' $NGINX_CONF
docker exec nginx nginx -s reload

# Step 5: Scale down the old version (blue)
echo "Scaling down the old version (blue)..."
docker-compose stop app-blue
docker-compose rm -f app-blue

echo "Blue-green deployment completed successfully!"