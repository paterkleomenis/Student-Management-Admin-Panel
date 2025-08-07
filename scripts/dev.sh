#!/bin/bash

# Development Script for Admin Panel
# This script sets up and runs the Flutter web app in development mode

set -e  # Exit on any error

echo "🛠️ Starting development environment..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from template..."
    if [ -f ".env.template" ]; then
        cp .env.template .env
        print_info "Please edit .env file with your configuration before running the app"
        exit 1
    else
        print_error "Neither .env nor .env.template found. Please create .env file."
        exit 1
    fi
fi

# Verify Flutter version
print_status "Checking Flutter version..."
flutter --version

# Enable web if not already enabled
print_status "Ensuring web support is enabled..."
flutter config --enable-web

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Check for any immediate issues
print_status "Running quick analysis..."
if flutter analyze --no-fatal-infos; then
    print_status "Code analysis passed"
else
    print_warning "Found some analysis issues, but starting development server anyway"
fi

print_status "Development environment ready!"
echo ""
print_info "Starting development server..."
print_info "The app will be available at: http://localhost:3000"
print_info "Press Ctrl+C to stop the development server"
echo ""

# Run the development server
flutter run -d web-server --web-port=3000 \
    --dart-define=APP_ENV=development \
    --dart-define=DEBUG_MODE=true \
    --dart-define=ENABLE_LOGGING=true
