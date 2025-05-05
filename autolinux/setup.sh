#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== STARTING SETUP SCRIPT ==="
echo "Timestamp: $(date)"
echo "Hostname: $(hostname)"

# Function to handle errors
function error_exit {
    echo "Error: $1" >&2
    exit 1
}

# 1. System Updates & Basic Packages
echo "[1/8] Updating system and installing base packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y || error_exit "Failed to update packages"
apt-get upgrade -y || error_exit "Failed to upgrade packages"
apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    jq \
    htop \
    ncdu || error_exit "Failed to install base packages"

# 2. Create User & SSH Keys (commented out as we're using the admin user)
# echo "[2/8] Configuring SSH access..."
# USERNAME="devops"
# useradd -m -s /bin/bash "$USERNAME" || error_exit "Failed to create user"
# mkdir -p /home/"$USERNAME"/.ssh
# echo "ssh-rsa YOUR_PUBLIC_KEY_HERE" >> /home/"$USERNAME"/.ssh/authorized_keys
# chown -R "$USERNAME":"$USERNAME" /home/"$USERNAME"/.ssh
# chmod 700 /home/"$USERNAME"/.ssh
# chmod 600 /home/"$USERNAME"/.ssh/authorized_keys
# usermod -aG sudo "$USERNAME" || error_exit "Failed to add user to sudo group"

# 3. Security Hardening
echo "[3/8] Applying security settings..."
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config || echo "Warning: Failed to disable password auth"
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config || echo "Warning: Failed to disable root login"
systemctl restart sshd || echo "Warning: Failed to restart sshd"

# 4. Install Docker
echo "[4/8] Installing Docker..."
curl -fsSL https://get.docker.com | sh || error_exit "Failed to install Docker"
usermod -aG docker mohni || error_exit "Failed to add user to docker group"
systemctl enable docker || echo "Warning: Failed to enable Docker"
systemctl start docker || error_exit "Failed to start Docker"

# 5. Install Monitoring Agent (Azure example)
echo "[5/8] Skipping monitoring agent installation..."

# 6. Application Deployment (Example: Nginx)
echo "[6/8] Installing Nginx..."
apt-get install -y nginx || error_exit "Failed to install Nginx"
systemctl enable nginx || echo "Warning: Failed to enable Nginx"
systemctl start nginx || error_exit "Failed to start Nginx"

# Custom index.html
cat > /var/www/html/index.html <<EOF
<html>
  <body>
    <h1>Azure VM Setup Script Success!</h1>
    <p>Hostname: $(hostname)</p>
    <p>Timestamp: $(date)</p>
  </body>
</html>
EOF

# 7. Enable Automatic Updates
echo "[7/8] Configuring automatic security updates..."
apt-get install -y unattended-upgrades || echo "Warning: Failed to install unattended-upgrades"
dpkg-reconfigure -plow unattended-upgrades || echo "Warning: Failed to configure automatic updates"

# 8. Clean Up
echo "[8/8] Cleaning up..."
apt-get autoremove -y || echo "Warning: Failed to autoremove packages"
apt-get clean || echo "Warning: Failed to clean packages"

echo "=== SETUP SCRIPT COMPLETED SUCCESSFULLY ==="
exit 0
