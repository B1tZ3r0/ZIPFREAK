#!/bin/bash
echo "🔧 Installing ZIPFREAK Dependencies"
echo "----------------------------------"

# Check for root
if [ "$EUID" -ne 0 ]; then
  echo "⚠️  Please run as root (sudo $0)"
  exit 1
fi

# Install packages
echo "📦 Installing packages..."
apt update && apt install -y \
  zip \
  unzip \
  john \
  git \
  curl

# Verify installation
if ! command -v zip2john &> /dev/null; then
  echo "❌ John the Ripper installation failed!"
  exit 1
fi

echo "✅ Installation complete!"
echo "Run: ./ZIPFREAK.sh to start"
