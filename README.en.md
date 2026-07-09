<p align="right">
  <b>English</b> | <a href="README.md">繁體中文</a>
</p>

# sbx

> sing-box management script — streamlined, multi-language, Matrix-styled UI.

---

## Quick Start

```bash
# Install (requires root on Linux VPS)
bash <(curl -sL https://raw.githubusercontent.com/c92d58/sbx/main/install.sh)

# Or locally
git clone https://github.com/c92d58/sbx.git
cd sbx
bash install.sh
```

The installer will prompt you to select language (English / 繁體中文).

---

## Features

### Protocol Management

| Command | Description |
|---------|-------------|
| `sbx add reality` | Add VLESS-REALITY (default) |
| `sbx add tuic` | Add TUIC |
| `sbx add trojan` | Add Trojan |
| `sbx add hy2` | Add Hysteria2 |
| `sbx add ss` | Add Shadowsocks 2022 |
| `sbx add anytls` | Add AnyTLS |
| `sbx add socks` | Add SOCKS5 |
| `sbx del <name>` | Delete config |
| `sbx info [name]` | View config details |
| `sbx change <name> port 8443` | Change port / uuid / host / path / key / sni |

Config files are auto-named with random 5-digit numbers for brevity.

### DNS — NextDNS Multi-Server

```bash
sbx dns nextdns CONFIG_ID [DEVICE_NAME]
```

Configures **NextDNS** (DoH) as primary, with **Cloudflare H3** and **Google H3** as fallback. Chinese domains (`geosite-cn`) route through the local resolver automatically.

Optional device name for identification in NextDNS analytics dashboard:

```bash
sbx dns nextdns abc123 185-vps
```

Also supports single-server presets: `sbx dns cf`, `sbx dns gg`, `sbx dns 11`, etc.

### Speed Test

```bash
sbx speed vps          # VPS bandwidth test (Cloudflare 10MB download)
sbx speed <name>       # Test specific config (port check + bandwidth)
sbx speed              # Test all configs
```

### Health Check

```bash
sbx check [name]       # Validate: file integrity + port listening + core status
```

### Backup & Restore

```bash
sbx backup             # Create /root/sbx-backup-*.tar.gz
sbx backup list        # List backups
sbx restore <file>     # Restore from backup (auto-backups current config first)
```

### Traffic Stats

```bash
sbx traffic [name]     # Show active TCP connections per config
```

### Language Switch

```bash
sbx lang zh-TW         # Switch to 繁體中文
sbx lang en            # Switch to English
```

### Other

| Command | Description |
|---------|-------------|
| `sbx bbr` | Enable BBR TCP congestion control |
| `sbx log` | View / configure log level |
| `sbx status` | Service status |
| `sbx update core` | Update sing-box core from SagerNet |
| `sbx reinstall` | Reinstall script |
| `sbx uninstall` | Uninstall completely |
| `sbx qr <name>` | Generate QR code for config |

---

## UI Style

Matrix-inspired terminal UI — monochrome green on black, no background colors, clean alignment:

```
> sbx v1.0 / sing-box v1.12.0 >> running
WAHSUN

> 18347
协议 (protocol)           VLESS-REALITY
地址 (address)            185.201.227.246
端口 (port)               8443
...

[!] error message (red)
[-] warning notice (dim green)
>> success message (bright green)
```

---

## Directory Structure

```
/etc/sbx/
├── bin/sing-box          # core binary (from SagerNet/sing-box)
├── conf/*.json           # per-protocol config files
├── config.json           # main config (includes conf/*.json)
├── sh/                   # script files
│   └── src/              # modules
│       ├── core.sh       # main dispatcher
│       ├── dns.sh        # DNS management
│       ├── speed.sh      # speed test
│       ├── check.sh      # health check
│       ├── backup.sh     # backup & restore
│       ├── traffic.sh    # traffic stats
│       ├── lang/         # language packs
│       │   ├── en.sh     # English
│       │   └── zh-TW.sh  # 繁體中文
│       └── ...
├── lang                  # language selection file
└── bin/tls.*             # temporary TLS certificates
```

---

## Credits

- **sing-box core**: [SagerNet/sing-box](https://github.com/SagerNet/sing-box)
- **Author**: WAHSUN

---

## License

GPL-3.0
