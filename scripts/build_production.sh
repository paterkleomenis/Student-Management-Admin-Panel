#!/bin/bash

# Production Build Script for Admin Panel
# This script builds the Flutter web app for production deployment

set -e  # Exit on any error

echo "🚀 Starting production build process..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
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
    print_error ".env file not found. Please copy .env.template to .env and configure it."
    exit 1
fi

# Verify Flutter version
print_status "Checking Flutter version..."
flutter --version

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

# Run code analysis
print_status "Running code analysis..."
if flutter analyze; then
    print_status "Code analysis passed"
else
    print_warning "Code analysis found issues, but continuing with build"
fi

# Format code
print_status "Formatting code..."
dart format lib/ --line-length=80

# Build for production
print_status "Building for production..."
flutter build web \
    --release \
    --dart-define=APP_ENV=production \
    --dart-define=DEBUG_MODE=false \
    --source-maps \
    --web-renderer html

# Check if build was successful
if [ -d "build/web" ]; then
    print_status "Production build completed successfully!"
    echo ""
    echo "📁 Build output is in: build/web/"
    echo "📊 Build size:"
    du -sh build/web/
    echo ""
    echo "🎯 Ready for deployment!"
    echo ""
    echo "Next steps:"
    echo "1. Test the build locally by serving the build/web/ directory"
    echo "2. Deploy to your hosting service (Firebase, Netlify, Vercel, etc.)"
    echo "3. Configure your domain and SSL certificate"
    echo "4. Set up monitoring and analytics"
else
    print_error "Build failed! Please check the error messages above."
    exit 1
fi

# Optional: Create deployment archive
read -p "📦 Create deployment archive? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    ARCHIVE_NAME="admin_panel_production_${TIMESTAMP}.tar.gz"

    print_status "Creating deployment archive: ${ARCHIVE_NAME}"
    tar -czf "${ARCHIVE_NAME}" -C build web/

    print_status "Archive created: ${ARCHIVE_NAME}"
    echo "📤 You can now upload this archive to your server"
fi

echo ""
print_status "Production build process completed! 🎉"
