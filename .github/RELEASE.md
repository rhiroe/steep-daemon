# Release Process

This document describes how to release a new version of steep-daemon.

## Overview

This project uses automated GitHub Actions for:
- **Release Drafter**: Automatically generates draft releases and CHANGELOG from merged PRs
- **Trusted Publishing**: Secure, passwordless gem publishing to RubyGems.org
- **Automated Versioning**: Development versions use `.dev` suffix

## Version Management

Development versions use a `.dev` suffix (e.g., `0.1.0.dev`). When releasing:
1. The `.dev` suffix is removed to create the release version (e.g., `0.1.0`)
2. A git tag is created for the release
3. The version is automatically bumped to the next dev version (e.g., `0.1.1.dev`)

## Release Drafter

[Release Drafter](https://github.com/marketplace/actions/release-drafter) automatically creates and updates a draft release with:
- Changelog based on merged PRs
- Categorized changes (Features, Bug Fixes, Documentation, etc.)
- Automatic version number suggestions based on PR labels
- Auto-labeling based on branch names and file changes

### PR Labels

Use these labels on your PRs for automatic categorization:
- `major`, `breaking`: Major version bump (1.0.0 → 2.0.0)
- `minor`, `feature`, `enhancement`: Minor version bump (1.0.0 → 1.1.0)
- `patch`, `bug`, `fix`, `chore`: Patch version bump (1.0.0 → 1.0.1)

The auto-labeler will add these based on:
- Branch names: `feat/...`, `fix/...`, `chore/...`
- PR titles containing: "feat", "fix", "bug", "chore"
- Changed files: `*.md` → documentation, `.github/**/*` → maintenance

## Automated Release via GitHub Actions

### 1. Bump Version

Go to the [Bump Version workflow](../../actions/workflows/bump-version.yml) and click "Run workflow":

- **version_type**: Choose `patch`, `minor`, or `major`
  - `patch`: Bug fixes (0.1.0.dev → 0.1.0 → 0.1.1.dev)
  - `minor`: New features (0.1.0.dev → 0.2.0 → 0.2.1.dev)
  - `major`: Breaking changes (0.1.0.dev → 1.0.0 → 1.0.1.dev)
- **custom_version**: (Optional) Override with a specific version like `1.2.3`

The workflow will:
1. Remove `.dev` suffix from current version
2. Calculate the release version number
3. Update `lib/steep/daemon/version.rb` with release version
4. Generate a CHANGELOG entry from commit messages
5. Run tests to verify everything works
6. Create a commit with the release version
7. Create and push a git tag (e.g., `v0.1.0`)
8. Bump version to next dev version (e.g., `0.1.1.dev`)
9. Create and push a commit with the dev version

### 2. Automatic Publishing

Once the tag is pushed, the [Release Gem workflow](../../actions/workflows/release.yml) automatically:
1. Runs tests and RuboCop
2. Builds the gem
3. Publishes to RubyGems.org (requires `RUBYGEMS_API_KEY` secret)
4. Creates a GitHub Release with auto-generated release notes

## Manual Release (Alternative)

If you prefer to release manually:

### 1. Update Version for Release

Edit `lib/steep/daemon/version.rb` to remove `.dev` suffix:

```ruby
module Steep
  module Daemon
    VERSION = "0.2.0"  # Remove .dev for release
  end
end
```

### 2. Update CHANGELOG

Add an entry to `CHANGELOG.md`:

```markdown
## [v0.2.0] - 2026-02-15

### Added
- New feature description

### Changed
- Updated feature description

### Fixed
- Bug fix description
```

### 3. Commit and Tag

```bash
git add lib/steep/daemon/version.rb CHANGELOG.md
git commit -m "Release v0.2.0"
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin main
git push origin v0.2.0
```

### 4. Bump to Next Dev Version

After releasing, update to the next dev version:

```ruby
module Steep
  module Daemon
    VERSION = "0.2.1.dev"  # Next dev version
  end
end
```

```bash
git add lib/steep/daemon/version.rb
git commit -m "Bump version to 0.2.1.dev"
git push origin main
```

### 5. Build and Publish

```bash
# Build the gem
gem build steep-daemon.gemspec

# Publish to RubyGems (requires authentication)
gem push steep-daemon-0.2.0.gem
```

### 6. Create GitHub Release

Go to [Releases](../../releases) and create a new release:
- Tag: Select the tag you just pushed (e.g., `v0.2.0`)
- Title: `v0.2.0`
- Description: Copy from CHANGELOG.md
- Attach the `.gem` file

## Prerequisites

### Option 1: Trusted Publishing (Recommended) 🔒

Trusted Publishing uses OIDC for secure, passwordless authentication. **No API key needed!**

Setup on RubyGems.org:
1. Go to your gem's page on [RubyGems.org](https://rubygems.org)
2. Navigate to "Trusted publishing"
3. Click "Add a new publisher"
4. Configure:
   - **Repository owner**: Your GitHub username/org
   - **Repository name**: steep-daemon
   - **Workflow filename**: release.yml
   - **Environment name**: (leave blank)

That's it! The `rubygems/release-gem@v1` action will automatically authenticate using OIDC.

### Option 2: API Key (Fallback)

If Trusted Publishing is not available:

1. **RUBYGEMS_API_KEY**
   - Go to [RubyGems.org API Keys](https://rubygems.org/profile/api_keys)
   - Create a new API key with "Push rubygems" scope
   - Add it as a repository secret in GitHub Settings → Secrets → Actions

The release workflow will automatically fall back to using the API key if Trusted Publishing is not configured.

### GitHub Permissions

Ensure your GitHub Actions have the necessary permissions:
- `contents: write` - To create releases and push tags
- `id-token: write` - For Trusted Publishing (OIDC)

## Troubleshooting

### Workflow fails to push

If the bump-version workflow fails with permission errors:
1. Go to Settings → Actions → General
2. Under "Workflow permissions", select "Read and write permissions"
3. Enable "Allow GitHub Actions to create and approve pull requests"

### RubyGems authentication fails

1. Verify the `RUBYGEMS_API_KEY` secret is set correctly
2. Check that the API key has "Push rubygems" permissions
3. Ensure you're the owner or have push access to the gem

### Tests fail during release

The release workflow will not publish if tests fail. Fix the failing tests and push the fix, then re-run the workflow.

## Post-Release

After a successful release:

1. Verify the gem appears on [RubyGems.org](https://rubygems.org/gems/steep-daemon)
2. Check the [GitHub Release](../../releases) was created
3. Test installation: `gem install steep-daemon`
4. Update any documentation if needed
