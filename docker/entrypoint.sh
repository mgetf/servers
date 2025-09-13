#!/bin/bash
# Pterodactyl Entrypoint Script for TF2 MGE Server

cd /home/container || exit 1

# Replace startup variables
MODIFIED_STARTUP=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo "Starting server with: ${MODIFIED_STARTUP}"

# Fix permissions if needed
if [ -f "./srcds_run" ]; then
    chmod +x ./srcds_run
fi

# Source any custom environment
if [ -f ".env" ]; then
    source .env
fi

# Execute the server
eval "${MODIFIED_STARTUP}"