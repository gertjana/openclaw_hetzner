# Clawdbot on Hetzner VPS

Production-grade Terraform deployment for running OpenClaw (formerly Clawdbot) 24/7 on a Hetzner Cloud VPS with security hardening and Tailscale integration.

## 🚀 Quick Start

1. **Prerequisites:**
   - Hetzner Cloud account + API token
   - Terraform installed
   - SSH key pair generated
   - (Optional) Tailscale account

2. **Configure:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Install OpenClaw:**
   ```bash
   ssh openclaw@$(terraform output -raw server_ip)
   npm install -g openclaw@latest
   openclaw onboard --install-daemon
   # See DEPLOYMENT_GUIDE.md for complete instructions
   ```

## 📚 Documentation

See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for complete step-by-step instructions.

## 🔒 Security Features

- ✅ SSH key-only authentication (passwords disabled)
- ✅ Root login disabled
- ✅ fail2ban with 24h IP bans
- ✅ Dual firewall (Hetzner + UFW)
- ✅ Kernel hardening (IP spoofing, ICMP redirects)
- ✅ Automatic security updates
- ✅ Optional Tailscale for zero-trust access

## 💰 Cost

~$6.50/month for Hetzner CX22 (2 vCPU, 4GB RAM, 40GB SSD)

## 📖 Resources

- [OpenClaw Official Docs](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Blog Post (Original Clawdbot version)](https://moabukar.medium.com/running-clawdbot-24-7-on-a-hetzner-vps-terraform-security-hardening-and-the-bits-the-docs-miss-096d3bcf7a37)
- [Hetzner Cloud](https://www.hetzner.com/cloud)
- [Tailscale](https://tailscale.com)

## ⚠️ Important Notes

- Never commit `terraform.tfvars` (contains API keys)
- Don't use your personal WhatsApp number for the bot
- Wait for cloud-init to complete before installing Clawdbot
- Keep your API keys and tokens secure

## 📝 License

Based on the blog post by moabukar. Use at your own risk.
