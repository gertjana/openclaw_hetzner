#!/bin/bash
set -euo pipefail

# Variables from Terraform
TAILSCALE_AUTH_KEY="${tailscale_auth_key}"
USERNAME="${username}"
SSH_PUBLIC_KEY="${ssh_public_key}"

# Logging
exec > >(tee /var/log/cloud-init-custom.log) 2>&1
echo "=== Cloud-init started at $(date) ==="

# System updates
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install essentials
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl \
  git \
  vim \
  htop \
  fail2ban \
  ufw \
  unattended-upgrades \
  apt-listchanges

# Create non-root user
if ! id "$USERNAME" &>/dev/null; then
  useradd -m -s /bin/bash -G sudo "$USERNAME"
  # Set a random password (optional, for sudo prompts)
  echo "$USERNAME:$(openssl rand -base64 32)" | chpasswd
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
  chmod 0440 /etc/sudoers.d/$USERNAME
fi

# SSH key for user
USER_HOME="/home/$USERNAME"
mkdir -p "$USER_HOME/.ssh"
echo "$SSH_PUBLIC_KEY" > "$USER_HOME/.ssh/authorized_keys"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.ssh"

# SSH hardening
cat > /etc/ssh/sshd_config.d/hardening.conf << 'EOF'
# Disable password authentication
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes

# Disable root login
PermitRootLogin no

# Key-based auth only
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# Timeouts and limits
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
MaxSessions 3
LoginGraceTime 30

# Disable unused auth methods
HostbasedAuthentication no
PermitEmptyPasswords no
KerberosAuthentication no
GSSAPIAuthentication no

# Logging
LogLevel VERBOSE
EOF

# Restart SSH
systemctl restart ssh

# fail2ban configuration
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
banaction = ufw

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 24h
EOF

systemctl enable fail2ban
systemctl restart fail2ban

# UFW firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# Unattended upgrades – security patches only
cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "$${distro_id}:$${distro_codename}-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

systemctl enable unattended-upgrades

# Kernel hardening via sysctl
cat > /etc/sysctl.d/99-security.conf << 'EOF'
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

# Ignore source routed packets
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Log Martian packets
net.ipv4.conf.all.log_martians = 1

# Ignore broadcast pings
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable IPv6 if not needed (optional)
# net.ipv6.conf.all.disable_ipv6 = 1
EOF

sysctl -p /etc/sysctl.d/99-security.conf

# Tailscale (optional)
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
  curl -fsSL https://tailscale.com/install.sh | sh
  tailscale up --authkey="$TAILSCALE_AUTH_KEY" --ssh
  echo "Tailscale installed and connected"
fi

echo "=== Cloud-init completed at $(date) ==="
