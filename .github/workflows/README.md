# GitHub Actions Workflows

This directory contains CI/CD workflows for automated deployment using GitHub Container Registry (GHCR).

## Available Workflows

### Production Workflows (GHCR-based)

1. **[backend-ghcr-deploy.yml](./backend-ghcr-deploy.yml)** - Backend deployment with GHCR
   - Builds Django backend Docker image
   - Pushes to GitHub Container Registry
   - Deploys to production server
   - Includes: backend, celery, celery-beat services
   - Triggers on: changes to `backend/**`, `docker-compose.yml`

2. **[web-ghcr-deploy.yml](./web-ghcr-deploy.yml)** - Frontend deployment with GHCR
   - Builds React/Vite frontend Docker image
   - Pushes to GitHub Container Registry
   - Deploys to production server
   - Triggers on: changes to `web/**`

### Legacy Workflows (SSH-based)

3. **[backend-deploy.yml](./backend-deploy.yml)** - Original backend deployment
   - Uses SSH and git pull
   - Builds on server
   - Legacy approach - consider migrating to GHCR version

4. **[web-deploy.yml](./web-deploy.yml)** - Original frontend deployment
   - Uses SSH and direct file copy
   - Builds locally then uploads
   - Legacy approach - consider migrating to GHCR version

### Other Workflows

5. **[ios-build.yml](./ios-build.yml)** - iOS mobile app build
6. **[android-build.yml](./android-build.yml)** - Android mobile app build
7. **[pages-deploy.yml](./pages-deploy.yml)** - GitHub Pages deployment
8. **[full-deploy.yml](./full-deploy.yml)** - Full stack deployment

## Differences: GHCR vs SSH Deployment

### SSH-based Deployment (Legacy)
```
Developer → Push to GitHub → Workflow starts
   ↓
Server pulls code via SSH
   ↓
Server builds Docker image locally
   ↓
Server runs docker-compose up
```

**Pros:**
- Simpler setup
- No container registry needed
- Direct server control

**Cons:**
- Server needs git access
- Builds consume server resources
- No image versioning
- Slower deployments
- Hard to rollback

### GHCR-based Deployment (Recommended)
```
Developer → Push to GitHub → Workflow starts
   ↓
GitHub Actions builds Docker image
   ↓
Pushes image to GHCR
   ↓
Server pulls pre-built image
   ↓
Server runs docker-compose up
```

**Pros:**
- ✅ Faster deployments (pre-built images)
- ✅ Version control for images
- ✅ Easy rollback to previous versions
- ✅ Server doesn't need git or build tools
- ✅ Consistent builds (CI environment)
- ✅ Can deploy same image to multiple servers
- ✅ Better separation of concerns
- ✅ Free for public repositories

**Cons:**
- Slightly more complex setup
- Requires GHCR configuration
- Uses GitHub Actions minutes (free tier: 2000 min/month)

## Migration Guide

### From SSH to GHCR Deployment

1. **Disable old workflows** (optional)
   - Rename `backend-deploy.yml` to `backend-deploy.yml.disabled`
   - Rename `web-deploy.yml` to `web-deploy.yml.disabled`

2. **Configure new workflows**
   - Ensure GitHub Secrets are configured (see [CICD_SETUP.md](../../CICD_SETUP.md))
   - Enable package write permissions in repository settings

3. **Update docker-compose.yml**
   - Already updated to support GHCR images
   - Uses environment variables for image selection

4. **Test new workflows**
   - Push changes to `main` branch
   - Monitor workflow execution in Actions tab
   - Verify deployment on server

5. **Clean up** (after successful migration)
   - Remove old workflow files
   - Update documentation

## Workflow Configuration

### Environment Variables

Both GHCR workflows use these environment variables:

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: nfc-medical-app
```

### Triggers

**Backend GHCR:**
```yaml
on:
  push:
    branches: [ main ]
    paths:
      - 'backend/**'
      - 'docker-compose.yml'
      - '.github/workflows/backend-ghcr-deploy.yml'
```

**Web GHCR:**
```yaml
on:
  push:
    branches: [ main ]
    paths:
      - 'web/**'
      - '.github/workflows/web-ghcr-deploy.yml'
```

### Permissions

```yaml
permissions:
  contents: read      # Read repository contents
  packages: write     # Push to GHCR
```

### Concurrency

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

This ensures:
- Only one deployment runs at a time per workflow
- New deployments cancel in-progress ones
- Prevents deployment conflicts

## Image Tagging Strategy

Each image is tagged with:
- `latest` - Always points to the most recent build
- `sha-<commit>` - Specific commit hash (e.g., `sha-abc123`)
- `main` - Branch name

Example:
```
ghcr.io/username/nfc-medical-app-backend:latest
ghcr.io/username/nfc-medical-app-backend:sha-abc123
ghcr.io/username/nfc-medical-app-backend:main
```

### Rollback Strategy

To rollback to a previous version:

```bash
# On your server
cd /root/nfc-medical-app

# Edit .env to use specific SHA
IMAGE_TAG=sha-previous-commit-hash

# Pull and restart
docker compose pull backend
docker compose up -d backend --force-recreate
```

## Monitoring Workflows

### GitHub Actions UI

1. Go to repository → Actions tab
2. Select workflow from left sidebar
3. View runs and logs

### Email Notifications

GitHub sends emails on workflow failures by default.

### Slack/Discord Integration (Optional)

Add notification steps to workflows:

```yaml
- name: Notify Slack
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
```

## Debugging Workflows

### View detailed logs

1. Go to Actions tab
2. Click on failed workflow run
3. Click on failed job
4. Expand failed step

### SSH debugging

Add this step to workflow for SSH access:

```yaml
- name: Setup tmate session
  uses: mxschmitt/action-tmate@v3
  if: failure()
```

### Common Issues

**Build fails:**
- Check Dockerfile syntax
- Ensure all files are committed
- Check build logs in Actions tab

**Push to GHCR fails:**
- Verify packages: write permission is enabled
- Check if GITHUB_TOKEN is available
- Ensure repository allows package creation

**Deployment fails:**
- Verify SSH credentials
- Check server has Docker installed
- Ensure server has internet access to pull from GHCR
- Check disk space on server

**Health check fails:**
- Verify URL is correct in secrets
- Check if service is actually running
- Increase timeout in health check step

## Best Practices

1. **Use path filters** to trigger only relevant workflows
2. **Enable concurrency control** to prevent conflicts
3. **Add health checks** to verify successful deployment
4. **Use caching** to speed up builds
5. **Set retention policies** for old images
6. **Monitor workflow run times** and optimize as needed
7. **Keep secrets secure** - never commit them
8. **Test workflows** in a staging environment first
9. **Document any custom changes** to workflows
10. **Review workflow logs** regularly

## Security Considerations

1. **Secrets Management**
   - Never commit secrets to repository
   - Use GitHub Secrets for sensitive data
   - Rotate secrets regularly

2. **Image Security**
   - Scan images for vulnerabilities
   - Use minimal base images
   - Keep dependencies updated

3. **Access Control**
   - Limit who can modify workflows
   - Use branch protection rules
   - Require PR reviews for workflow changes

4. **GHCR Access**
   - Images are private by default for private repos
   - Configure package visibility in package settings
   - Use package access tokens for external access

## Performance Optimization

### Build Caching

Workflows use GitHub Actions cache:

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

This can reduce build times by 50-80%.

### Parallel Jobs

Consider splitting workflows:

```yaml
jobs:
  build:
    # Build job
  test:
    needs: build
    # Test job
  deploy:
    needs: [build, test]
    # Deploy job
```

### Conditional Execution

Skip unnecessary steps:

```yaml
- name: Run tests
  if: github.event_name == 'pull_request'
```

## Cost Management

### GitHub Actions Minutes

- Free tier: 2000 minutes/month
- These workflows use approximately:
  - Backend build: 3-5 minutes
  - Frontend build: 2-4 minutes
  - Deploy: 1-2 minutes each

### GHCR Storage

- Free for public repositories
- Private repositories: Free up to storage limits
- Clean up old images periodically

### Optimization Tips

1. Use `actions/cache` for dependencies
2. Use smaller base images (alpine variants)
3. Combine RUN commands in Dockerfile
4. Use multi-stage builds
5. Set appropriate workflow triggers (path filters)

## Further Reading

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GHCR Documentation](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

## Support

For issues or questions:
1. Check [CICD_SETUP.md](../../CICD_SETUP.md)
2. Review workflow logs in Actions tab
3. Check GitHub Actions documentation
4. Open an issue in the repository
