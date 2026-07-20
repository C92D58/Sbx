# sbx Profiles

Profiles allow you to save and switch between complete configuration sets.

## Usage

```bash
# Save current configuration as a profile
sbx profile save home

# List all profiles
sbx profile list

# Switch to a different profile (auto-backs up current)
sbx profile switch office

# Delete a profile
sbx profile delete old-config
```

## Structure

Each profile stores:
- `config.json` — main sing-box configuration
- `conf/` — individual protocol configs
- `Caddyfile` — Caddy web server config (if used)
- `.created` — timestamp

## Use Cases

- **Location-based**: `home`, `office`, `travel`
- **Region-based**: `hk`, `us`, `jp`, `sg`
- **Environment**: `production`, `testing`, `fallback`
- **Snapshot before changes**: `sbx profile save before-upgrade`
