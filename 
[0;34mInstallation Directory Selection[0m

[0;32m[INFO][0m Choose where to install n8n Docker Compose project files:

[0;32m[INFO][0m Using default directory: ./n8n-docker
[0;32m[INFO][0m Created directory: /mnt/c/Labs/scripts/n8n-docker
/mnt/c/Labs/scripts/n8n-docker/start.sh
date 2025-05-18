#!/bin/bash
echo "Starting n8n with Docker Compose..."
docker-compose up -d
echo "n8n is starting up. Please wait a few moments..."
sleep 5
echo "n8n should be available at: http://localhost:5678"
