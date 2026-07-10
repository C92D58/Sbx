<p align="right">
  <b>English</b> | <a href="README.md">繁體中文</a>
</p>

# sbx

> sing-box management script — Matrix-themed terminal UI, bilingual, streamlined.

[![License](https://img.shields.io/badge/license-GPL--3.0-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%7C%20ARM64-green)]()

---

## Quick Start

```bash
# One-liner install (requires root on Linux VPS)
bash <(curl -sL https://raw.githubusercontent.com/c92d58/sbx/main/install.sh)

# Or local install
git clone https://github.com/c92d58/sbx.git
cd sbx
bash install.sh
```

The installer prompts for language (English / 繁體中文), auto-detects your OS, and downloads all dependencies plus the sing-box core binary.

---

## Command Reference

### Protocol Management

| Command | Description |
|---------|-------------|
| `sbx add reality` | Add VLESS-REALITY (default) |
| `sbx add tuic` | Add TUIC (congestion_control enabled) |
| `sbx add trojan` | Add Trojan (TLS / no-TLS) |
| `sbx add hy2` | Add Hysteria2 |
| `sbx add ss` | Add Shadowsocks (2022 ciphers supported) |
| `sbx add anytls` | Add AnyTLS (ACME auto-TLS supported) |
| `sbx add socks` | Add SOCKS5 (username / password auth) |
| `sbx add `*ws/h2/hu* | Add TLS protocols (auto Caddy reverse proxy) |
| `sbx del <name>` | Delete config |
| `sbx info [name]` | View config details |
| `sbx url <name>` | Show config share URL |
| `sbx qr <name>` | Generate QR code for config |
| `sbx change <name> ...` | Change port / uuid / host / path / key / sni / cipher |

Config files are auto-named with random 5-digit numbers. Each protocol is a standalone JSON file for easy management.

**`sbx change` supported fields:**

```
port      passwd    id/uuid    host      path
method    key       sni        web       new
door-addr door-port full       user
```

```bash
sbx change 18347 port 8443           # Change port
sbx change 18347 id auto             # Auto-generate new UUID
sbx change 18347 key auto            # Auto-generate new keypair
sbx change 18347 full auto           # Reset all parameters at once
sbx fix 18347                        # Alias for full
sbx fix-all                          # Batch fix all configs
```

### DNS Management

```bash
sbx dns nextdns CONFIG_ID [DEVICE]    # NextDNS (DoH) + CF H3 + Google H3 fallback
sbx dns cf                            # Cloudflare H3
sbx dns gg                            # Google H3
sbx dns 11                            # 1.1.1.1 (UDP)
sbx dns 88                            # 8.8.8.8 (UDP)
sbx dns family                        # Cloudflare Family (malware filtering)
sbx dns set <address>                 # Custom DNS (h3:// tls:// https:// tcp:// udp://)
sbx dns none                          # Clear DNS configuration
```

**NextDNS multi-server example:**

```bash
sbx dns nextdns abc123               # Basic setup
sbx dns nextdns abc123 185-vps       # With device name (identifiable in NextDNS dashboard)
```

Three-tier DNS fallback: NextDNS (primary) → Cloudflare H3 → Google H3. `geosite-cn` domains automatically use local DNS resolver.

### Speed Test

```bash
sbx speed vps          # VPS bandwidth test (Cloudflare Speedtest 10MB)
sbx speed <name>       # Specific config (port check + bandwidth)
sbx speed              # All configs
```

### Health Check

```bash
sbx check [name]       # Validates: file integrity + port listening + core status
```

Reports a three-item checklist per config. All green = config is healthy.

### Traffic Stats

```bash
sbx traffic [name]     # Show active TCP connections per config
```

### Backup & Restore

```bash
sbx backup             # Create /root/sbx-backup-*.tar.gz
sbx backup list        # List all backups with file sizes
sbx restore <file>     # Restore from backup (auto-backs up current config first)
```

### Log Management

```bash
sbx log                # Live tail of access log
sbx log info           # Set log level
sbx log warn           # Only warnings and above
sbx log error          # Errors only
sbx log none           # Disable logging
sbx log del            # Delete all log files
```

Log levels: `trace` > `debug` > `info` > `warn` > `error` > `fatal` > `panic`

### Service Control

```bash
sbx status             # Show sing-box / Caddy service status
sbx start              # Start sing-box
sbx stop               # Stop sing-box
sbx restart            # Restart sing-box
sbx start caddy        # Start Caddy
sbx stop caddy         # Stop Caddy
sbx restart caddy      # Restart Caddy
sbx t                  # Test run (diagnose startup failures)
```

### Updates

```bash
sbx update core        # Update sing-box core (from SagerNet)
sbx update sh           # Update management script
sbx update caddy        # Update Caddy web server
sbx U                   # Quick script update (alias for update sh)
sbx reinstall           # Reinstall script
```

### Other Commands

| Command | Description |
|---------|-------------|
| `sbx bbr` | Enable BBR TCP congestion control (kernel ≥ 4.9) |
| `sbx lang zh-TW` | Switch to Traditional Chinese |
| `sbx lang en` | Switch to English |
| `sbx version` | Show version information |
| `sbx ip` | Show server public IP |
| `sbx pbk` | Generate reality keypair |
| `sbx ss2022` | Generate Shadowsocks 2022 compatible password |
| `sbx get-port` | Find an available port |
| `sbx debug <name>` | Dump config debug info |
| `sbx gen ...` | Dry-run — print JSON without writing |
| `sbx no-auto-tls ...` | Add config without automatic TLS |
| `sbx import` | Import configs from Xray / V2Ray |
| `sbx fix-config.json` | Rebuild main config file |
| `sbx fix-caddyfile` | Rebuild Caddyfile |
| `sbx bin ...` | Run sing-box core binary commands directly |
| `sbx matrix` | Enter the Matrix — hacker aesthetic effects |
| `sbx uninstall` | Uninstall completely (optional: remove Caddy) |

---

## Matrix Effects

```bash
sbx matrix             # Full intro: digital rain → ASCII logo → typewriter status → pulse line
sbx matrix rain        # 8-second digital rain animation only
sbx matrix logo        # ASCII art banner only
```

Also accessible from the main menu (`m` key). Effects include:

- **Matrix Rain** — katakana character cascading waterfall (adapts to terminal size)
- **ASCII Logo** — Brand banner built with `▐▌ ░▒▓█` block characters
- **Typewriter Effect** — Characters appear one by one
- **Glitch Reveal** — Scrambled characters resolve into legible text
- **Pulse Line** — Scanning line across terminal width

---

## UI Style

Matrix-themed — monochrome green on black, no background colors, clean tabular alignment:

```
┌─────────────────────────────────────────────┐
│  ▀█▀ █▀▄ ▀ ▀   sbx v1.0  >> running    │
│   █  █▀  ▀█▀   sing-box manager          │
└─────────────────────────────────────────────┘

[1] config   [2] dns        [3] tools
[4] system   [5] help       [m] matrix

>>

> 18347
protocol              VLESS-REALITY  ← dim label  bright value
address               185.201.227.246
port                  8443
...
> URL
vless://...@185.201.227.246:8443?...  ← bright share link

[!] error message  (red — critical only)
[-] warning notice (dim green — decoration / hints)
>> success message (bright green — operation OK)
```

---

## Directory Structure

### After installation (`/etc/sbx/`)

```
/etc/sbx/
├── bin/
│   ├── sing-box          # core binary (SagerNet/sing-box)
│   ├── tls.cer           # temporary TLS certificate
│   └── tls.key           # temporary TLS key
├── conf/
│   └── *.json            # per-protocol config (e.g., 18347.json)
├── config.json           # main config (imports conf/*.json)
├── sh/                   # script directory
│   ├── sbx.sh            # entry point
│   ├── install.sh        # installer
│   ├── src/              # modules
│   │   ├── core.sh       # main dispatcher (CLI + menu)
│   │   ├── init.sh       # init (variables / language / environment)
│   │   ├── dns.sh        # DNS management
│   │   ├── speed.sh      # speed test
│   │   ├── check.sh      # health check
│   │   ├── backup.sh     # backup & restore
│   │   ├── traffic.sh    # traffic stats
│   │   ├── log.sh        # log management
│   │   ├── matrix.sh     # Matrix visual effects
│   │   ├── bbr.sh        # BBR congestion control
│   │   ├── caddy.sh      # Caddy TLS integration
│   │   ├── download.sh   # core/script downloader
│   │   ├── systemd.sh    # systemd/OpenRC service
│   │   ├── import.sh     # config import
│   │   ├── help.sh       # help & about
│   │   └── lang/         # language packs
│   │       ├── en.sh     # English
│   │       └── zh-TW.sh  # Traditional Chinese
│   └── tools/
│       └── qr.html       # QR code generator
└── lang                  # language selection file
```

---

## Supported Protocols

| Protocol | Transport | TLS Support | Command |
|----------|-----------|-------------|---------|
| VLESS-REALITY | TCP / H2 | Reality | `sbx add reality` |
| VLESS-WS-TLS | WebSocket | TLS (Caddy) | `sbx add vws` |
| VLESS-H2-TLS | HTTP/2 | TLS (Caddy) | `sbx add vh2` |
| VLESS-HTTPUpgrade-TLS | HTTPUpgrade | TLS (Caddy) | `sbx add vhu` |
| VMess-WS-TLS | WebSocket | TLS (Caddy) | `sbx add wss` |
| VMess-H2-TLS | HTTP/2 | TLS (Caddy) | `sbx add h2` |
| Trojan-WS-TLS | WebSocket | TLS (Caddy) | `sbx add tws` |
| Trojan-H2-TLS | HTTP/2 | TLS (Caddy) | `sbx add th2` |
| TUIC | QUIC | Built-in TLS | `sbx add tuic` |
| Hysteria2 | QUIC | Built-in TLS | `sbx add hy2` |
| Shadowsocks | TCP | None | `sbx add ss` |
| AnyTLS | TCP | ACME / Self-signed | `sbx add anytls` |
| SOCKS5 | TCP | None | `sbx add socks` |
| Direct | TCP | None | `sbx add door` |

---

## Technical Details

- **Core**: Uses SagerNet/sing-box, auto-fetches latest from GitHub Releases
- **Init system**: Supports both systemd and OpenRC
- **Operating systems**: Ubuntu / Debian / CentOS / Alpine / openSUSE
- **Architecture**: x86_64 / ARM64
- **Acceleration**: Auto-enables BBR (kernel ≥ 4.9)
- **NTP**: Auto time-sync via Apple NTP server
- **Bilingual**: Full English + Traditional Chinese language packs, selectable at install
- **Import**: Supports importing from Xray / V2Ray configurations

## Security

- Uses `jq --arg` for safe variable passing (prevents JSON injection)
- Atomic config writes (`tmp + mv` pattern to prevent truncation)
- IP parsing via `sed` extraction (not `eval` / `export`)
- Safe temporary directory creation (`mktemp -d`)
- Runs as root by default (standard VPS practice)

---

## Credits

- **sing-box core**: [SagerNet/sing-box](https://github.com/SagerNet/sing-box)
- **Author**: WAHSUN

---

## License

[GPL-3.0](LICENSE)
