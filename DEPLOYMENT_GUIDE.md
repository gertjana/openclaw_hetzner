# openclaw on Hetzner VPS - Complete Deployment Guide

Production-grade deployment using Terraform, security hardening, and Tailscale for 24/7 operation.

## Prerequisites

1. **Hetzner Cloud Account** - Sign up at [hetzner.com](https://www.hetzner.com/cloud)
2. **Hetzner API Token** - Generate from Hetzner Cloud Console → Security → API Tokens
3. **SSH Key Pair** - Generate with `ssh-keygen -t ed25519 -C "your@email.com"`
4. **Tailscale Account** (optional but recommended) - Sign up at [tailscale.com](https://tailscale.com)
5. **Terraform Installed** - Install from [terraform.io](https://www.terraform.io/downloads)
6. **Anthropic/OpenAI API Key** - For AI model access

## Step-by-Step Deployment

### Step 1: Get Tailscale Auth Key (Optional but Recommended)

1. Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Click "Generate auth key" with settings:
   - **Reusable**: No
   - **Ephemeral**: No
   - **Pre-approved**: Yes
   - **Expiry**: 1 hour
3. Copy the key (looks like `tskey-auth-kXYZ123CNTRL-abc123...`)

**Why Tailscale?**
- Private HTTPS access without exposing ports
- Zero-trust mesh network between your devices
- Access dashboard via `https://openclaw.tail1234.ts.net`

### Step 2: Create Terraform Configuration Files

Create each file with the content below.

### Step 3: Configure Your Variables

1. Copy the example file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values:
   ```hcl
   hcloud_token   = "your-hetzner-api-token"
   server_name    = "openclaw-vps"
   server_type    = "cx22"  # 2 vCPU, 4GB RAM
   image          = "ubuntu-24.04"
   location       = "nbg1"  # Nuremberg, Germany
   ssh_public_key = "ssh-ed25519 AAAA... you@machine"
   
   # Security: restrict SSH to your IP or VPN
   allowed_ssh_ips = ["YOUR_IP/32"]
   
   # Optional: Tailscale for zero-trust access
   tailscale_auth_key = "tskey-auth-xxxxx"
   ```

3. Get your public IP: `curl ifconfig.me`

### Step 4: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (takes ~2 minutes)
terraform apply

# Save the server IP
terraform output -raw server_ip
```

### Step 5: Wait for Cloud-Init to Complete

Cloud-init runs security hardening on first boot. Monitor progress:

```bash
# Watch the cloud-init log (takes ~3-5 minutes)
ssh openclaw@$(terraform output -raw server_ip) 'tail -f /var/log/cloud-init-custom.log'

# Look for this line at the end:
# === Cloud-init completed at [timestamp] ===
```

Press Ctrl+C when complete.

### Step 6: Install Node.js and Dependencies

SSH into the server:

```bash
ssh openclaw@$(terraform output -raw server_ip)
```

Install Node.js via nvm:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc
nvm install 24
node -v  # Should show v24.x
```

Install Homebrew (required for some skills):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
source ~/.bashrc
```

### Step 7: Install OpenClaw

**Note:** The project was renamed from openclaw to OpenClaw. Use the new package name:

```bash
npm install -g openclaw@latest
```

This takes 1-2 minutes. Once complete, proceed to onboarding.

### Step 8: Onboard OpenClaw

Run the interactive wizard:

```bash
openclaw onboard --install-daemon
```

**Configuration choices:**

| Prompt | Recommended Choice | Notes |
|--------|-------------------|-------|
| Continue? | Yes | Acknowledge risks |
| Onboarding mode | **Manual** | More control over configuration |
| What to set up? | **Local gateway** | Gateway runs on this VPS |
| Workspace directory | `/home/openclaw/clawd` | Default is fine |
| Model/auth provider | **Anthropic** or **OpenAI** | Your preference (need API key) |
| Gateway port | `18789` | Default |
| Gateway bind | **Loopback (127.0.0.1)** | Only accessible via Tailscale/SSH |
| Gateway auth | **Token** | Generates access token for dashboard |
| Tailscale exposure | **Serve** | Private HTTPS within your tailnet |
| Reset Tailscale on exit? | **No** | Keeps endpoint alive on restart |
| Configure chat channels? | **Yes** | Set up WhatsApp/Telegram/Discord |
| Configure skills? | **Yes** | Select skills you want (use Spacebar) |
| Node manager | **npm** | Default |
| Install Gateway service? | **Yes** | Auto-start via systemd |
| Gateway service runtime | **Node (recommended)** | Required for WhatsApp |
| How to hatch? | **Hatch in TUI** | Interactive terminal setup |

### Step 9: Verify Service Status

```bash
# Check service status
systemctl status openclaw-gateway

# View logs
journalctl -u openclaw-gateway -f

# Check status via CLI
openclaw status

# Access via Tailscale
# Your dashboard will be at: https://openclaw.your-tailnet.ts.net
```

### Step 10: WhatsApp Integration (Optional)

**Important:** Don't use your personal WhatsApp number!

1. **Get a temporary phone number:**
   - Giffgaff (UK): £10 prepaid SIM
   - Lycamobile: Budget MVNO
   - Any pay-as-you-go SIM for SMS verification

2. **Setup WhatsApp Business:**
   - Install WhatsApp Business on spare phone or Android emulator
   - Verify with temporary number
   - During OpenClaw onboarding, select WhatsApp as chat channel
   - Scan QR code shown by OpenClaw
   - Message your bot with `/start` to pair

3. **Use from your main phone:**
   - Add the business number as a contact
   - Message it like any WhatsApp contact
   - 24/7 AI assistant on your phone!

## Security Hardening Summary

The cloud-init script automatically configures:

✅ **SSH Hardening**
- Password authentication disabled
- Root login disabled
- Key-based auth only
- 3 max auth attempts
- Verbose logging

✅ **Firewall (Defense in Depth)**
- Hetzner firewall (hypervisor level)
- UFW (kernel level)
- fail2ban (24h IP bans after 3 failed SSH attempts)

✅ **Kernel Hardening**
- IP spoofing protection
- ICMP redirect blocking
- Source routing disabled
- Martian packet logging

✅ **Automatic Updates**
- Security patches only
- No surprise feature changes
- Daily update checks

## Accessing Your Openclaw

### Via Tailscale (Recommended)

```bash
# Dashboard
https://openclaw.your-tailnet.ts.net

# SSH
ssh openclaw@openclaw.your-tailnet.ts.net
```

### Via SSH Tunnel (If No Tailscale)

```bash
ssh -L 18789:localhost:18789 openclaw@<SERVER_IP>

# Then access dashboard at:
http://localhost:18789
```

## Maintenance Commands

```bash
# Check service status
systemctl status openclaw-gateway

# View logs
journalctl -u openclaw-gateway -f

# OpenClaw CLI commands
openclaw status        # Check gateway status
openclaw doctor        # Run diagnostics
openclaw dashboard     # Open web UI

# Restart service
sudo systemctl restart openclaw-gateway

# Check pending security updates
sudo unattended-upgrades --dry-run -v

# Monitor system resources
htop

# Check firewall status
sudo ufw status verbose

# View fail2ban bans
sudo fail2ban-client status sshd
```

## Troubleshooting

### NPM Global Install Errors (EACCES)

Don't use `sudo npm`. Fix permissions:

```bash
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Cloud-Init Not Finished

Terraform reports success before cloud-init completes:

```bash
ssh openclaw@<IP> 'tail -f /var/log/cloud-init-custom.log'
```

Wait for: `=== Cloud-init completed at [timestamp] ===`

### Tailscale SSH Issues

If you enabled `tailscale up --ssh`, Tailscale handles SSH auth separately. Your `~/.ssh/authorized_keys` still works, but Tailscale ACLs take precedence.

### Service Won't Start

Check logs for errors:

```bash
journalctl -u openclaw-gateway -n 100 --no-pager

# Or use the CLI
openclaw doctor
```

## Cost Estimate

**Hetzner CX22 Server:**
- 2 vCPU, 4GB RAM, 40GB SSD
- ~€5.83/month (~$6.50/month)
- 20TB monthly traffic

**Tailscale:**
- Free tier (up to 100 devices)

**Total:** ~$6.50/month for 24/7 AI assistant

## Additional Security Considerations

- **SSH on non-standard port** - Reduces log noise from bots
- **Monitoring/alerting** - Set up uptime-kuma or Prometheus
- **Backup strategy** - Backup `~/.openclaw` directory regularly
- **Rate limiting** - If exposing HTTP endpoints

## Next Steps

1. Configure your preferred chat channels (WhatsApp, Telegram, Discord, Slack)
2. Install and configure skills from the ecosystem
3. Set up hooks for automation (boot-md, session-memory, etc.)
4. Explore the dashboard for configuration and monitoring
5. Read the official docs for advanced features

## Resources

- [OpenClaw Official Docs](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw npm Package](https://www.npmjs.com/package/openclaw)
- [Hetzner Cloud](https://www.hetzner.com/cloud)
- [Tailscale](https://tailscale.com)
- [Terraform Hetzner Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)

---

**Security Note:** This is a production-grade setup, but always review and adjust security settings based on your threat model. Keep your API keys secure and never commit them to git.
