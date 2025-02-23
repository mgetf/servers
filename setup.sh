#!/bin/bash

# Set up logging
LOG_FILE="/var/log/tf2_setup.log"
exec 1> >(tee -a "${LOG_FILE}")
exec 2> >(tee -a "${LOG_FILE}" >&2)

# Logging functions
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
}

# Test the logging
log_info "Starting TF2 server setup"
log_info "Hello, World!"

# If something goes wrong
if false; then
    log_error "This is what an error looks like"
fi

log_info "Setup completed successfully" 