#!/bin/bash

set -Eeuo pipefail

# ==========================================================
# Production Linux Server Automation
# Script: setup-server.sh
#
# Purpose:
# Install all dependencies required to build and run
# the News Application on Ubuntu 24.04
#
# Backend:
#   Java 17
#   Maven
#
# Frontend:
#   Node.js 22
#   npm
#
# Web Server:
#   Nginx
# ==========================================================

trap 'echo "ERROR: Script failed at line $LINENO."' ERR

echo "=========================================="
echo "SERVER SETUP STARTED"
echo "=========================================="

# ----------------------------------------------------------
# Root check
# ----------------------------------------------------------

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: This script must be run as root."
    echo "Run:"
    echo "sudo ./scripts/setup-server.sh"
    exit 1
fi

# ----------------------------------------------------------
# Validate Ubuntu
# ----------------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    echo "ERROR: Cannot determine operating system."
    exit 1
fi

source /etc/os-release

if [[ "$ID" != "ubuntu" ]]; then
    echo "ERROR: This script is designed for Ubuntu."
    echo "Detected: $ID"
    exit 1
fi

echo "Operating System: $PRETTY_NAME"

# ----------------------------------------------------------
# Update package repository
# ----------------------------------------------------------

echo ""
echo "Updating package repository..."

apt-get update

# ----------------------------------------------------------
# Install basic dependencies
# ----------------------------------------------------------

echo ""
echo "Installing basic dependencies..."

apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    zip \
    rsync \
    jq \
    build-essential \
    ca-certificates \
    gnupg \
    software-properties-common

# ----------------------------------------------------------
# Install Java 17
# ----------------------------------------------------------

echo ""
echo "Installing Java 17..."

apt-get install -y openjdk-17-jdk

JAVA_VERSION=$(java -version 2>&1 | head -n 1)

echo "Java installed:"
echo "$JAVA_VERSION"

# ----------------------------------------------------------
# Install Maven
# ----------------------------------------------------------

echo ""
echo "Installing Maven..."

apt-get install -y maven

echo "Maven version:"
mvn -version

# ----------------------------------------------------------
# Install Node.js 22 + npm
# ----------------------------------------------------------

echo ""
echo "Installing Node.js 22..."

curl -fsSL https://deb.nodesource.com/setup_22.x | bash -

apt-get install -y nodejs

echo ""
echo "Node.js version:"
node --version

echo "npm version:"
npm --version

# ----------------------------------------------------------
# Install Nginx
# ----------------------------------------------------------

echo ""
echo "Installing Nginx..."

apt-get install -y nginx

# ----------------------------------------------------------
# Enable services
# ----------------------------------------------------------

echo ""
echo "Enabling Nginx..."

systemctl enable nginx
systemctl start nginx

# ----------------------------------------------------------
# Verify Nginx
# ----------------------------------------------------------

if systemctl is-active --quiet nginx; then
    echo "Nginx is running."
else
    echo "ERROR: Nginx failed to start."
    exit 1
fi

# ----------------------------------------------------------
# Display installed versions
# ----------------------------------------------------------

echo ""
echo "=========================================="
echo "INSTALLED DEPENDENCIES"
echo "=========================================="

echo ""
echo "Java:"
java -version

echo ""
echo "Maven:"
mvn -version

echo ""
echo "Node:"
node --version

echo ""
echo "npm:"
npm --version

echo ""
echo "Nginx:"
nginx -v

echo ""
echo "Git:"
git --version

# ----------------------------------------------------------
# Server setup complete
# ----------------------------------------------------------

echo ""
echo "=========================================="
echo "SERVER SETUP COMPLETED SUCCESSFULLY"
echo "=========================================="

echo ""
echo "Installed:"
echo "✓ Java 17"
echo "✓ Maven"
echo "✓ Node.js 22"
echo "✓ npm"
echo "✓ Nginx"
echo "✓ Git"
echo "✓ Build utilities"

echo ""
echo "The server is ready for application deployment."