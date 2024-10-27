#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)."
    exit 1
fi

echo "Updating package lists..."
apt-get update

echo "Installing dependencies..."
apt-get install -y zip unzip tar p7zip-full dos2unix

echo "Copying 'arc' script to /usr/local/bin..."
cp arc /usr/local/bin/

echo "Setting permissions..."
chmod +x /usr/local/bin/arc

echo "Converting 'arc' script to Unix format..."
dos2unix /usr/local/bin/arc

echo "Installation complete! You can now use 'arc' command."
