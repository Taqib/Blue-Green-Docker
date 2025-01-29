#!/bin/bash

# Variables
DOCKER_IMAGE="taqib4802/blue-green"
COMPOSE_FILE="/home/ubuntu/Blue-Green/blue-green-compose.yml"
NGINX_CONF="/home/ubuntu/Blue-Green/nginx.conf"

# Step 1.5: Stop and remove the existing green container
echo "Stopping and removing the existing green container..."
docker-compose -f $COMPOSE_FILE stop app-green
docker-compose -f $COMPOSE_FILE rm -f app-green

# Step 2: Deploy the new version (green)
echo "Deploying the new version (green)..."
if ! docker-compose -f $COMPOSE_FILE up -d app-green; then
  echo "Error: Failed to deploy the green container. Aborting deployment."
  exit 1
fi

# Step 3: Wait for the green container to be healthy
echo "Waiting for the green container to be healthy..."
sleep 10  # Adjust the sleep time as needed

# Step 4: Test the green container
echo "Testing the green container..."
GREEN_STATUS=$(curl -o /dev/null -s -w "%{http_code}\n" http://localhost:8002)

if [ "$GREEN_STATUS" != "200" ]; then
  echo "Error: Green container is not healthy. Deployment aborted."
  docker-compose -f $COMPOSE_FILE stop app-green
  docker-compose -f $COMPOSE_FILE rm -f app-green
  exit 1
fi

# Step 5: Update Nginx to route traffic to green
echo "Switching traffic to the new version (green)..."
docker exec nginx nginx -s reload

# Step 6: Scale down the old version (blue)
echo "Scaling down the old version (blue)..."
docker-compose -f $COMPOSE_FILE stop app-blue
docker-compose -f $COMPOSE_FILE rm -f app-blue

echo "Blue-green deployment completed successfully!"
