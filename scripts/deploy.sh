#!/bin/bash

set -Eeuo pipefail

# ==========================================================
# Production Linux Server Automation
# Script: deploy.sh
#
# Purpose:
# Deploy Spring Boot JAR and React frontend to EC2.
# ==========================================================

trap 'echo "ERROR: Deployment failed at line $LINENO."' ERR

# ----------------------------------------------------------
# Configuration
# ----------------------------------------------------------

REMOTE_USER="ubuntu"
REMOTE_APP_DIR="/opt/news-app"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

KEY_FILE="$PROJECT_ROOT/production-server-key.pem"

# Change this if your JAR name changes
JAR_FILE="$PROJECT_ROOT/project_builds/News-App2-0.0.1-SNAPSHOT.jar"

DIST_DIR="$PROJECT_ROOT/project_builds/dist"

# ----------------------------------------------------------
# Usage
# ----------------------------------------------------------

if [[ $# -ne 1 ]]; then
    echo "Usage:"
    echo "./scripts/deploy.sh <public-ip>"
    echo ""
    echo "Example:"
    echo "./scripts/deploy.sh 3.110.152.38"
    exit 1
fi

PUBLIC_IP="$1"

# ----------------------------------------------------------
# Validate SSH key
# ----------------------------------------------------------

if [[ ! -f "$KEY_FILE" ]]; then
    echo "ERROR: SSH key not found:"
    echo "$KEY_FILE"
    exit 1
fi

chmod 400 "$KEY_FILE"

# ----------------------------------------------------------
# Validate application files
# ----------------------------------------------------------

if [[ ! -f "$JAR_FILE" ]]; then
    echo "ERROR: Spring Boot JAR not found:"
    echo "$JAR_FILE"
    exit 1
fi

if [[ ! -d "$DIST_DIR" ]]; then
    echo "ERROR: React dist directory not found:"
    echo "$DIST_DIR"
    exit 1
fi

# ----------------------------------------------------------
# SSH options
# ----------------------------------------------------------

SSH_OPTS=(
    -i "$KEY_FILE"
    -o StrictHostKeyChecking=accept-new
    -o ConnectTimeout=10
)

echo "=========================================="
echo "NEWS APP DEPLOYMENT"
echo "=========================================="
echo "Server: $PUBLIC_IP"
echo "JAR:    $JAR_FILE"
echo "React:  $DIST_DIR"
echo "=========================================="

# ----------------------------------------------------------
# Test SSH
# ----------------------------------------------------------

echo ""
echo "Testing SSH connection..."

ssh "${SSH_OPTS[@]}" \
    "$REMOTE_USER@$PUBLIC_IP" \
    "echo 'SSH connection successful.'"

# ----------------------------------------------------------
# Create application directories
# ----------------------------------------------------------

echo ""
echo "Preparing server directories..."

ssh "${SSH_OPTS[@]}" \
    "$REMOTE_USER@$PUBLIC_IP" \
    "sudo mkdir -p $REMOTE_APP_DIR/backend $REMOTE_APP_DIR/frontend && \
     sudo chown -R $REMOTE_USER:$REMOTE_USER $REMOTE_APP_DIR"

# ----------------------------------------------------------
# Upload Spring Boot JAR
# ----------------------------------------------------------

echo ""
echo "Uploading Spring Boot JAR..."

scp "${SSH_OPTS[@]}" \
    "$JAR_FILE" \
    "$REMOTE_USER@$PUBLIC_IP:$REMOTE_APP_DIR/backend/app.jar"

echo "Backend uploaded."

# ----------------------------------------------------------
# Upload React frontend
# ----------------------------------------------------------

echo ""
echo "Uploading React frontend..."

ssh "${SSH_OPTS[@]}" \
    "$REMOTE_USER@$PUBLIC_IP" \
    "rm -rf $REMOTE_APP_DIR/frontend/*"

scp "${SSH_OPTS[@]}" \
    -r "$DIST_DIR/." \
    "$REMOTE_USER@$PUBLIC_IP:$REMOTE_APP_DIR/frontend/"

echo "Frontend uploaded."

# ----------------------------------------------------------
# Verify deployment
# ----------------------------------------------------------

echo ""
echo "Verifying deployment..."

ssh "${SSH_OPTS[@]}" \
    "$REMOTE_USER@$PUBLIC_IP" \
    "ls -lh $REMOTE_APP_DIR/backend/app.jar && \
     echo 'Frontend files:' && \
     find $REMOTE_APP_DIR/frontend -maxdepth 2 -type f | head -20"

# ----------------------------------------------------------
# Complete
# ----------------------------------------------------------

echo ""
echo "=========================================="
echo "DEPLOYMENT COMPLETED"
echo "=========================================="
echo ""
echo "Backend:"
echo "$REMOTE_APP_DIR/backend/app.jar"
echo ""
echo "Frontend:"
echo "$REMOTE_APP_DIR/frontend/"
echo ""
echo "Next:"
echo "1. Configure systemd for Spring Boot"
echo "2. Configure Nginx for React"
echo "=========================================="