# sbx — Full Command Reference

## Dashboard

| Command | Description |
|---------|-------------|
| `sbx` | Launch interactive dashboard |
| `sbx main` | Enter dashboard loop (same as `sbx`) |

## Protocol Management

| Command | Description |
|---------|-------------|
| `sbx create` | Interactive config creation (guided protocol selection) |
| `sbx add reality` | Add VLESS-REALITY |
| `sbx add tuic` | Add TUIC (congestion_control enabled) |
| `sbx add trojan` | Add Trojan (TLS / no-TLS) |
| `sbx add hy2` | Add Hysteria2 |
| `sbx add ss` | Add Shadowsocks (2022 ciphers supported) |
| `sbx add anytls` | Add AnyTLS (ACME auto-TLS) |
| `sbx add socks` | Add SOCKS5 |
| `sbx add vws` | Add VLESS-WS-TLS |
| `sbx add vh2` | Add VLESS-H2-TLS |
| `sbx add vhu` | Add VLESS-HTTPUpgrade-TLS |
| `sbx add wss` | Add VMess-WS-TLS |
| `sbx add h2` | Add VMess-H2-TLS |
| `sbx add tws` | Add Trojan-WS-TLS |
| `sbx add th2` | Add Trojan-H2-TLS |
| `sbx add door` | Add Direct (dokodemo-door) |
| `sbx add <protocol> [args]` | Add with inline args |

### Config Management

| Command | Description |
|---------|-------------|
| `sbx del <name>` | Delete config |
| `sbx info [name]` | View config details |
| `sbx url <name>` | Show share URL |
| `sbx qr <name>` | Generate QR code |
| `sbx change <name> <field> [value]` | Change config field |
| `sbx fix <name>` | Full reset config |
| `sbx fix-all` | Batch fix all configs |
| `sbx debug <name>` | Debug dump config |
| `sbx gen ...` | Dry-run JSON (no write) |
| `sbx no-auto-tls ...` | Add without auto TLS |

### Change Fields

```
port      host      path      passwd    id/uuid
method    key       sni       web       new
door-addr door-port full      user
```

## Diagnostics

| Command | Description |
|---------|-------------|
| `sbx doctor` | Full system diagnostics |
| `sbx bench [name]` | Protocol latency benchmark |
| `sbx check [name]` | Health check with score |
| `sbx speed [name\|vps]` | Speed test |

## Profiles

| Command | Description |
|---------|-------------|
| `sbx profile list` | List profiles |
| `sbx profile save <name>` | Save current as profile |
| `sbx profile switch <name>` | Switch to profile |
| `sbx profile delete <name>` | Delete profile |

## Themes

| Command | Description |
|---------|-------------|
| `sbx theme` | Show current theme |
| `sbx theme list` | List available themes |
| `sbx theme <name>` | Switch theme |

Available: `matrix`, `catppuccin`, `nord`, `dracula`, `gruvbox`, `tokyo-night`

## Plugins

| Command | Description |
|---------|-------------|
| `sbx plugin list` | List installed plugins |
| `sbx plugin <name>` | Show plugin info |
| `sbx plugin remove <name>` | Remove plugin |

## Service Control

| Command | Description |
|---------|-------------|
| `sbx status` | Service status |
| `sbx start [caddy]` | Start services |
| `sbx stop [caddy]` | Stop services |
| `sbx restart [caddy]` | Restart services |
| `sbx t` | Test run |

## Updates

| Command | Description |
|---------|-------------|
| `sbx update core [ver]` | Update sing-box core |
| `sbx update sh` | Update script |
| `sbx update caddy [ver]` | Update Caddy |
| `sbx U` | Quick script update |
| `sbx reinstall` | Reinstall script |

## Utilities

| Command | Description |
|---------|-------------|
| `sbx bbr` | Enable BBR |
| `sbx lang zh-TW\|en` | Switch language |
| `sbx version` | Version info |
| `sbx ip` | Server IP |
| `sbx pbk` | Generate reality keypair |
| `sbx ss2022` | Generate ss2022 password |
| `sbx get-port` | Find available port |
| `sbx backup [list]` | Backup configs |
| `sbx restore <file>` | Restore backup |
| `sbx log [level]` | Log management |
| `sbx traffic [name]` | Traffic stats |
| `sbx import` | Import from Xray/V2Ray |
| `sbx fix-config.json` | Rebuild main config |
| `sbx fix-caddyfile` | Rebuild Caddyfile |
| `sbx bin ...` | Run sing-box binary |
| `sbx matrix [rain\|logo]` | Matrix effects |
| `sbx uninstall` | Uninstall |
| `sbx h, help` | Show help |
