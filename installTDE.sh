#!/bin/sh

# Trinity Desktop Installation Script for FreeBSD with SLiM
# Purpose: Installs Trinity Desktop Environment (TDE) and SLiM, configuring TDE as a session option
# Based on: https://wiki.trinitydesktop.org/FreeBSD_Trinity_Installation_Instructions

# Check if the script is running with root privileges
if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root" 1>&2
    exit 1
fi

# Step 1: Update package repository to 'latest'
echo "Switching package repository to 'latest'..."
mkdir -p /usr/local/etc/pkg/repos
echo 'FreeBSD: { url: "pkg+http://pkg.FreeBSD.org/${ABI}/latest" }' > /usr/local/etc/pkg/repos/FreeBSD.conf
pkg update

# Step 2: Install core dependencies via pkg to avoid building them
echo "Installing core dependencies..."
pkg install -y git libtool gettext findutils gsed gtar bash automake cmake gmake ninja rsync xorg

# Step 3: Install SLiM (Simple Login Manager)
echo "Installing SLiM display manager..."
pkg install -y slim

# Step 4: Clone the TDE packaging repository
echo "Cloning TDE packaging repository..."
cd /usr/local
git clone --single-branch --branch r14.1.x https://mirror.git.trinitydesktop.org/gitea/TDE/tde-packaging.git
cd tde-packaging/freebsd

# Step 5: Synchronize TDE ports to /usr/ports
echo "Synchronizing TDE ports to /usr/ports..."
sh ./tde-ports-map sync /usr/ports

# Step 6: Build and install TDE using the tde-meta port
echo "Building and installing Trinity Desktop Environment (this may take a while)..."
cd /usr/ports/x11/tde-meta
make install clean

# Step 7: Create Trinity session file for Xsessions
echo "Configuring Trinity as a session option..."
mkdir -p /usr/local/share/xsessions
cat << EOF > /usr/local/share/xsessions/trinity.desktop
[Desktop Entry]
Name=Trinity
Comment=Trinity Desktop Environment
Exec=/usr/local/bin/starttde
TryExec=/usr/local/bin/starttde
Type=Application
DesktopNames=TDE
EOF
chmod 644 /usr/local/share/xsessions/trinity.desktop

# Step 8: Configure SLiM to include Trinity
echo "Updating SLiM configuration..."
# Backup original slim.conf
cp /usr/local/etc/slim.conf /usr/local/etc/slim.conf.bak
# Add Trinity to the sessions list if not already present
if ! grep -q "trinity" /usr/local/etc/slim.conf; then
    sed -i '' 's/sessions.*/sessions            trinity,openbox/' /usr/local/etc/slim.conf
else
    echo "Trinity already in SLiM sessions list."
fi

# Step 9: Enable SLiM service
echo "Enabling SLiM service..."
sysrc slim_enable="YES"

# Final message to the user
echo "Installation complete."
echo "Trinity Desktop Environment and SLiM have been installed."
echo "Reboot your system with 'sudo reboot'."
echo "At the SLiM login screen, use F1 to cycle sessions and select 'Trinity'."
echo "Log in to start the Trinity Desktop Environment."
echo "Note: If you encounter build issues, ensure your ports tree is up-to-date and review the wiki for troubleshooting."
