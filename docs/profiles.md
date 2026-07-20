# Profile System

Profiles let you save and switch between complete configuration sets in one command.

## Use Cases

- **Location-based**: Switch configs when traveling (`home`, `office`, `travel`)
- **Region-based**: Different server regions (`hk`, `us`, `jp`, `sg`)
- **Environment**: Separate `production`, `testing`, `fallback` configs
- **Pre-upgrade snapshots**: Save before making changes

## Commands

### Save a profile

```bash
sbx profile save hk
```

Saves the current entire configuration:
- `config.json` (main config)
- `conf/*.json` (all protocol configs)
- `Caddyfile` (Caddy config, if used)

### List profiles

```bash
sbx profile list
```

### Switch profiles

```bash
sbx profile switch us
```

What happens:
1. Current config is auto-backed up as `_auto-backup-<timestamp>`
2. Services are stopped
3. Profile files are restored
4. Services are restarted

### Delete a profile

```bash
sbx profile delete old-config
```

## Storage

Profiles are stored at `/etc/sbx/profiles/<name>/`:

```
/etc/sbx/profiles/hk/
├── config.json          # Main sing-box config
├── conf/                # Individual protocol configs
│   ├── 18347.json
│   └── 29451.json
├── Caddyfile            # Caddy config (if Caddy is used)
├── caddy_conf/          # Caddy site configs
└── .created             # Timestamp
```

## Example Workflow

```bash
# Set up config for Hong Kong
sbx add reality
sbx dns nextdns abc123
sbx profile save hk

# Set up config for US
sbx del 18347
sbx add tuic
sbx dns cf
sbx profile save us

# Switch between them
sbx profile switch hk    # Hong Kong config
sbx profile switch us    # US config
```
