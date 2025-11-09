# Modsynth Modules Manifest

> Meta-repository for managing Modsynth modules using Android AOSP-style manifest system

## Overview

This repository serves as the central coordination point for all Modsynth modules. Instead of cloning all 32 repositories individually, you use this manifest system to selectively sync only the modules you need.

## Quick Start

```bash
# Clone this repository
git clone https://github.com/modsynth/modules-manifest.git
cd modules-manifest

# Sync all modules
./scripts/sync.sh

# Or sync specific profile
./scripts/sync.sh --profile minimal
./scripts/sync.sh --profile phase-1

# Check status of synced modules
./scripts/status.sh
```

## Prerequisites

- `git` - Version control
- `jq` - JSON processor for parsing manifest
  - macOS: `brew install jq`
  - Ubuntu: `sudo apt-get install jq`

## Repository Structure

```
modules-manifest/
├── manifest.json           # Central module registry
├── scripts/
│   ├── sync.sh            # Sync modules from manifest
│   ├── update-module.sh   # Update module versions
│   └── status.sh          # Check module status
├── modules/               # Synced modules (gitignored)
│   ├── infrastructure/
│   ├── backend/
│   ├── frontend/
│   └── documentation/
└── README.md
```

## Module Categories

### Infrastructure (3 modules)
- `module-catalog-mcp` - MCP Server for module search
- `claude-code-templates` - Slash command templates
- `shared-configs` - Shared configs (ESLint, Prettier, TypeScript)

### Backend (13 modules)
- `auth-module` - JWT + OAuth2.0 authentication
- `db-module` - Database abstraction layer (GORM)
- `cache-module` - Redis cache wrapper
- `messaging-module` - RabbitMQ/Kafka abstraction
- `monitoring-module` - Prometheus + Grafana
- `logging-module` - Structured logging (Zap/Logrus)
- `api-gateway` - API Gateway pattern
- `file-storage-module` - S3/MinIO abstraction
- `notification-module` - Email/SMS/Push notifications
- `task-scheduler` - Cron job scheduler
- `search-module` - Elasticsearch integration
- `payment-module` - Stripe/PayPal integration
- `analytics-module` - Analytics data collection

### Frontend (12 modules)
- `ui-components` - React + Tailwind CSS components
- `api-client` - REST API client (Axios)
- `auth-client` - Authentication client
- `state-management` - Redux Toolkit
- `form-validation` - React Hook Form + Zod
- `routing` - React Router
- `error-handling` - Error Boundary
- `websocket-client` - WebSocket client
- `i18n` - Internationalization (i18next)
- `analytics-client` - Frontend analytics
- `chart-components` - Chart.js components
- `table-components` - TanStack Table components

### Documentation (3 modules)
- `docs-dev` - Architecture and development docs
- `docs-site` - Docusaurus documentation site
- `examples` - Sample projects

## Profiles

Profiles let you sync predefined sets of modules for different scenarios:

### `full`
All 32 modules including optional ones

```bash
./scripts/sync.sh --profile full
```

### `minimal`
Only required core modules (8 modules)

```bash
./scripts/sync.sh --profile minimal
```

Includes: shared-configs, module-catalog-mcp, auth-module, db-module, cache-module, ui-components, api-client, docs-dev

### `phase-1`
Phase 1 development modules (6 modules)

```bash
./scripts/sync.sh --profile phase-1
```

Includes: auth-module, db-module, cache-module, ui-components, api-client, shared-configs

### `backend-only`
Backend modules + infrastructure

```bash
./scripts/sync.sh --profile backend-only
```

### `frontend-only`
Frontend modules + infrastructure

```bash
./scripts/sync.sh --profile frontend-only
```

## Usage Examples

### Sync all modules
```bash
./scripts/sync.sh
```

### Sync by profile
```bash
./scripts/sync.sh --profile minimal
./scripts/sync.sh --profile phase-1
```

### Sync by category
```bash
./scripts/sync.sh --category backend
./scripts/sync.sh --category frontend
```

### Sync specific modules
```bash
./scripts/sync.sh auth-module db-module
./scripts/sync.sh ui-components api-client
```

### Check module status
```bash
./scripts/status.sh
```

Shows:
- Current branch/tag
- Clean or modified status
- Modified files (if any)
- Last commit
- Summary statistics

### Update module version
```bash
./scripts/update-module.sh auth-module v1.2.0
```

This updates the version in manifest.json. Then:
1. Review: `git diff manifest.json`
2. Sync: `./scripts/sync.sh auth-module`
3. Commit: `git add manifest.json && git commit -m "chore: update auth-module to v1.2.0"`

## Common Workflows

### Starting a new project

```bash
# 1. Clone modules-manifest
git clone https://github.com/modsynth/modules-manifest.git
cd modules-manifest

# 2. Sync minimal set
./scripts/sync.sh --profile minimal

# 3. Start developing
# Your modules are now in modules/*/
```

### Adding a new module to your project

```bash
# Sync just the module you need
./scripts/sync.sh payment-module

# Or edit manifest.json and sync
./scripts/sync.sh
```

### Updating all modules

```bash
# Pull latest versions
./scripts/sync.sh

# Check what changed
./scripts/status.sh
```

### Working on a specific module

```bash
# Sync the module
./scripts/sync.sh auth-module

# Make changes in modules/backend/auth-module/
cd modules/backend/auth-module
git checkout -b feature/new-oauth-provider
# ... make changes ...
git commit -am "feat: add Google OAuth provider"
git push origin feature/new-oauth-provider

# Create PR in the auth-module repository
```

## Manifest Schema

```json
{
  "version": "1.0.0",
  "description": "Manifest description",
  "updated": "2025-11-09",
  "modules": {
    "category-name": [
      {
        "name": "module-name",
        "repo": "https://github.com/modsynth/module-name.git",
        "path": "modules/category/module-name",
        "version": "v0.1.0",
        "required": true,
        "description": "Module description",
        "techStack": ["Go", "PostgreSQL"],
        "dependencies": ["other-module"]
      }
    ]
  },
  "profiles": {
    "profile-name": {
      "description": "Profile description",
      "includes": ["module-1", "module-2", "category/*"]
    }
  }
}
```

## Version Management

Modules use [Semantic Versioning](https://semver.org/):

- `v1.0.0` - Major release
- `v1.1.0` - Minor release (new features)
- `v1.0.1` - Patch release (bug fixes)

The sync script checks out specific version tags. If a version tag doesn't exist yet, it stays on the default branch.

## Module Dependencies

Some modules depend on others. The manifest tracks these relationships:

```json
{
  "name": "auth-module",
  "dependencies": ["cache-module"]
}
```

Make sure to sync dependencies when you sync a module.

## Tips

1. **Don't commit modules/** - It's in `.gitignore`. Only `manifest.json` is tracked.

2. **Use profiles** - They save time and keep your setup clean.

3. **Check status regularly** - `./scripts/status.sh` shows what's modified.

4. **Update incrementally** - Update one module at a time to avoid breaking changes.

5. **Module development** - Work directly in `modules/*/` and create PRs in the individual repos.

## Troubleshooting

### `jq: command not found`
Install jq:
- macOS: `brew install jq`
- Ubuntu: `sudo apt-get install jq`

### `Version not found`
The version tag doesn't exist yet in the repository. The script will stay on the default branch.

### `Failed to clone`
Check:
- Repository exists on GitHub
- You have access (public repos or proper auth for private)
- Network connection

### Module shows as modified
Run `./scripts/status.sh` to see what files changed. If unintentional:
```bash
cd modules/category/module-name
git checkout .
```

## Contributing

To add a new module to the manifest:

1. Create the repository on GitHub
2. Edit `manifest.json` to add the module
3. Commit and push the manifest change
4. Others can now sync it with `./scripts/sync.sh module-name`

## License

MIT License - See individual module repositories for their licenses.

## Links

- [Modsynth Organization](https://github.com/modsynth)
- [Development Documentation](modules/documentation/docs-dev)
- [Architecture Guide](modules/documentation/docs-dev/MODULAR_ARCHITECTURE.md)
