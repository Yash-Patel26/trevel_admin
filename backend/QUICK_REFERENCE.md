# Quick Reference: Zero-Downtime Deployment

## 🚀 Daily Workflow

```bash
# Make your changes
git add .
git commit -m "Your change description"
git push origin main

# That's it! GitHub Actions deploys automatically
```

## 📋 Setup Checklist

- [ ] Create GitHub repository
- [ ] Push code to GitHub
- [ ] Add GitHub Secrets (EC2_HOST, EC2_USER, EC2_SSH_KEY)
- [ ] SSH to EC2 and create `~/backend` directory
- [ ] Upload code to EC2 once manually
- [ ] Create `.env` file on EC2
- [ ] Make scripts executable: `chmod +x scripts/*.sh`
- [ ] Run initial deployment: `./scripts/deploy.sh`
- [ ] Test automated deployment with a push

## 🔧 Useful Commands

### On EC2

```bash
# Check health
./scripts/health-check.sh

# View logs
docker logs trevel_admin_backend -f

# Manual deployment
./scripts/quick-deploy.sh

# Restart container
docker restart trevel_admin_backend

# Check container status
docker ps -f name=trevel_admin_backend
```

### On Local Machine

```bash
# Check GitHub Actions status
# Go to: https://github.com/YOUR_USERNAME/trevel-admin/actions

# Deploy manually (if needed)
git push origin main
```

## 🏥 Health Check Endpoint

Your backend needs this endpoint:

```typescript
app.get('/healthz', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
```

## 📚 Documentation

- **[CICD_SETUP.md](./CICD_SETUP.md)** - Complete setup guide
- **[README.md](./README.md)** - Project overview
- **[EC2_DEPLOY_GUIDE.md](./EC2_DEPLOY_GUIDE.md)** - Initial EC2 setup

## 🆘 Troubleshooting

### Deployment Failed

1. Check GitHub Actions logs
2. SSH to EC2: `ssh -i trevel-key.pem ubuntu@YOUR_EC2_IP`
3. Check logs: `docker logs trevel_admin_backend --tail 100`
4. Run health check: `./scripts/health-check.sh`

### Rollback

```bash
# SSH to EC2
cd ~
rm -rf backend
mv backend_old backend
cd backend
./scripts/deploy.sh
```

## ✅ What Changed

| Before | After |
|--------|-------|
| Stop EC2 for changes | No stops needed |
| Manual SCP uploads | Automatic via GitHub |
| 30-60s downtime | 0s downtime |
| Manual rollback | Automatic rollback |
| No version tracking | Git SHA versioning |

## 🎯 Key Files

- `.github/workflows/deploy.yml` - CI/CD workflow
- `scripts/deploy.sh` - Zero-downtime deployment
- `scripts/health-check.sh` - Health validation
- `scripts/quick-deploy.sh` - Manual deployment
- `.env.example` - Environment template
- `docker-compose.yml` - Container config
