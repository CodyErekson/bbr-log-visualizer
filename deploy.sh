#!/usr/bin/env bash

# BBR Log Visualizer Deployment Script
# This script automates the deployment of the BBR Log Visualizer on the local server

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command_exists docker; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command_exists nginx; then
    print_error "Nginx is not installed. Please install Nginx first."
    exit 1
fi

print_success "All prerequisites are available."

# Get deployment configuration
echo
print_status "BBR Log Visualizer Deployment Configuration"
echo "=========================================="

# Prompt for domain name
while true; do
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
    if [[ -n "$DOMAIN_NAME" && "$DOMAIN_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$ ]]; then
        break
    else
        print_error "Please enter a valid domain name (e.g., example.com)"
    fi
done

# Prompt for Node.js port
read -p "Enter Node.js server port (default: 2069): " NODEJS_PORT
NODEJS_PORT=${NODEJS_PORT:-2069}

# Prompt for deployment path
read -p "Enter deployment path (default: /var/www/$DOMAIN_NAME): " DEPLOY_PATH
DEPLOY_PATH=${DEPLOY_PATH:-/var/www/$DOMAIN_NAME}

# Confirm configuration
echo
print_status "Deployment Configuration:"
echo "Domain: $DOMAIN_NAME"
echo "Port: $NODEJS_PORT"
echo "Path: $DEPLOY_PATH"
echo

read -p "Continue with deployment? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled."
    exit 0
fi

# Create nginx configuration from template
print_status "Creating nginx configuration..."
NGINX_CONF="${DOMAIN_NAME}.conf"

if [[ ! -f "nginx.conf.template" ]]; then
    print_error "nginx.conf.template not found. Please ensure you're running this script from the project root."
    exit 1
fi

cp nginx.conf.template "$NGINX_CONF"
sed -i "s/YOUR_DOMAIN_HERE/$DOMAIN_NAME/g" "$NGINX_CONF"
sed -i "s/YOUR_NODEJS_PORT/$NODEJS_PORT/g" "$NGINX_CONF"

print_success "Created $NGINX_CONF"

# Build Docker image
print_status "Building Docker image..."
docker build -t bbr-log-server .
print_success "Docker image built successfully"

# Create deployment directory
print_status "Creating deployment directory..."
mkdir -p "$DEPLOY_PATH/public_html"

# Copy application files
print_status "Copying application files..."
cp -r public_html/* "$DEPLOY_PATH/public_html/"

# Stop existing container if running
print_status "Stopping existing container..."
docker stop bbr-log-server 2>/dev/null || true
docker rm bbr-log-server 2>/dev/null || true

# Start new container
print_status "Starting new container..."
docker run -d --name bbr-log-server -p "$NODEJS_PORT:$NODEJS_PORT" bbr-log-server

# Update nginx configuration
print_status "Updating nginx configuration..."
cp "$NGINX_CONF" /etc/nginx/sites-available/
ln -sf "/etc/nginx/sites-available/$NGINX_CONF" /etc/nginx/sites-enabled/

# Test nginx configuration
print_status "Testing nginx configuration..."
nginx -t

# Reload nginx
print_status "Reloading nginx..."
systemctl reload nginx

# Set proper permissions
print_status "Setting file permissions..."
chown -R www-data:www-data "$DEPLOY_PATH/public_html"

# Clean up
print_status "Cleaning up temporary files..."
rm "$NGINX_CONF"

print_success "Application deployed successfully!"

# Final status check
print_status "Checking deployment status..."
sleep 5

if docker ps | grep bbr-log-server >/dev/null; then
    print_success "Container is running successfully"
else
    print_error "Container may not be running properly"
fi

# Display final information
echo
print_success "🎉 Deployment Complete!"
echo "=========================================="
echo "Your BBR Log Visualizer is now deployed at:"
echo "  🌐 https://$DOMAIN_NAME"
echo
echo "To view logs:"
echo "  📋 ssh $SERVER_USER@$SERVER_HOST 'docker logs -f bbr-log-server'"
echo
echo "To send test logs:"
echo "  🧪 curl -X POST https://$DOMAIN_NAME/logs \\"
echo "      -H 'Content-Type: application/json' \\"
echo "      -d '{\"message\": \"Test log from deployment\", \"level\": \"info\"}'"
echo
echo "To manage the container:"
echo "  🔄 Restart: ssh $SERVER_USER@$SERVER_HOST 'docker restart bbr-log-server'"
echo "  🛑 Stop: ssh $SERVER_USER@$SERVER_HOST 'docker stop bbr-log-server'"
echo "  📊 Status: ssh $SERVER_USER@$SERVER_HOST 'docker ps'"
echo

if [[ "$DOMAIN_NAME" != *"."* ]]; then
    print_warning "Don't forget to set up SSL certificates with Let's Encrypt:"
    echo "  🔒 ssh $SERVER_USER@$SERVER_HOST 'certbot --nginx -d $DOMAIN_NAME'"
fi
