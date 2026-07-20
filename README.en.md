<p align="right">
  <b>English</b> | <a href="README.md">繁體中文</a>
</p>

# sbx — Next Generation sing-box Manager

> Modern sing-box Management Framework — Matrix-themed CLI, plugin-ready, multi-profile.

[![License](https://img.shields.io/badge/license-GPL--3.0-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%7C%20ARM64-green)]()
[![Bash](https://img.shields.io/badge/pure-bash-blue)]()

---

## Why sbx?

| | |
|---|---|
| ✓ **Pure Bash** | Zero dependencies beyond bash + jq + curl |
| ✓ **Beautiful CLI** | Matrix theme + 6 color schemes |
| ✓ **Multi-language** | Full English / 繁體中文 support |
| ✓ **Plugin Ready** | Extensible without touching core |
| ✓ **Profile System** | One-command full config switching |
| ✓ **Health Scoring** | Visual health scores + system diagnostics |
| ✓ **Atomic JSON** | Safe config writes (`tmp + mv` pattern) |
| ✓ **Modern Architecture** | Modular directory, clear framework boundaries |

---

## Quick Start

```bash
# One-line install (requires Linux VPS root)
bash <(curl -sL https://raw.githubusercontent.com/c92d58/Sbx/main/install.sh)
```

Choose your language during install. The script auto-detects your OS, downloads dependencies and the sing-box core.

---

## Core Commands

| Command | Description |
|---------|-------------|
| `sbx` | Launch interactive dashboard |
| `sbx create` | Interactive config creation |
| `sbx add <protocol>` | Quick add (reality / tuic / hy2 / trojan / ss…) |
| `sbx dns <preset>` | DNS setup (NextDNS / Cloudflare / Google…) |
| `sbx doctor` | System diagnostics (Kernel / BBR / DNS / TLS…) |
| `sbx bench` | Protocol latency benchmark |
| `sbx check` | Health check with visual scoring |
| `sbx profile` | Profile management (save / switch / delete) |
| `sbx theme` | Theme switching (6 color schemes) |
| `sbx plugin` | Plugin management |
| `sbx matrix` | Enter the Matrix — digital rain |

Full reference: [docs/commands.md](docs/commands.md)

---

## Dashboard

Run `sbx` to enter the dashboard:

```
┌─────────────────────────────────────────────┐
│  ▐▌ ▀█▀ █▀▄ ▀ ▀   sbx v2.0  >> running    │
│  ▐▌  █  █▀  ▀█▀   modern sing-box manager  │
└─────────────────────────────────────────────┘

  Health: 98/100 ★★★★★  3 configs

  [1] Create       [2] Manage
  [3] DNS          [4] Tools
  [5] Profiles     [6] System
  [7] Themes       [8] Plugins
  [9] Help         [0] Exit

  [m] Matrix
```

All features accessible from the dashboard — no need to memorize commands.

---

## Doctor

```bash
$ sbx doctor

  Kernel          5.15.0        PASS
  System Time     synced        PASS
  BBR             enabled       PASS
  Firewall        open          PASS
  Certificate     valid         PASS
  Port            3 listening   PASS
  DNS             resolving     PASS
  sing-box        running       PASS

  >> Your server is healthy.
```

---

## Benchmark

```bash
$ sbx bench

  CONFIG     PROTO    PORT     LATENCY
  ----------------------------------------
  18347      vless    8443     12 ms
  29451      tuic     9001     8 ms
  35712      hy2      50001    15 ms

  >> Recommended: 29451 (tuic :9001) (8 ms)
```

---

## Themes

```bash
sbx theme matrix         # Classic green (default)
sbx theme catppuccin     # Catppuccin Mocha
sbx theme nord           # Nord
sbx theme dracula        # Dracula
sbx theme gruvbox        # Gruvbox
sbx theme tokyo-night    # Tokyo Night
sbx theme list           # List all themes
```

---

## Profiles

```bash
sbx profile save hk      # Save current config
sbx profile switch us    # One-command full switch
sbx profile list         # List all profiles
sbx profile delete old   # Delete a profile
```

---

## Supported Protocols

| Protocol | Transport | TLS | Command |
|----------|-----------|-----|---------|
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

## Architecture

```
/etc/sbx/sh/
├── core/                  # Framework core
├── modules/
│   ├── network/           # DNS / Speed / Protocols
│   ├── service/           # systemd / Caddy / BBR
│   ├── tools/             # Backup / Check / Traffic / Log / Doctor / Bench
│   └── ui/                # Dashboard / Matrix / Theme UI
├── themes/                # 6 color schemes
├── plugins/               # Extensible plugins
├── profiles/              # Config snapshots
└── lang/                  # Language packs
```

---

## Documentation

- [Full Command Reference](docs/commands.md)
- [DNS Configuration](docs/dns.md)
- [Theme Guide](docs/themes.md)
- [Plugin Development](docs/plugins.md)
- [Profile Usage](docs/profiles.md)

---

## Technical Details

- **Core**: SagerNet/sing-box, latest from GitHub Releases
- **Init system**: systemd + OpenRC
- **OS**: Ubuntu / Debian / CentOS / Alpine / openSUSE
- **Arch**: x86_64 / ARM64
- **Acceleration**: Auto BBR (kernel ≥ 4.9)
- **NTP**: Auto time-sync
- **Bilingual**: Full English + 繁體中文

---

## Security

- `jq --arg` safe variable passing (JSON injection prevention)
- Atomic config writes (`tmp + mv` pattern)
- Safe IP parsing via `sed` (no `eval`/`export`)
- Secure temp dir creation (`mktemp -d`)

---

## Credits

- **sing-box core**: [SagerNet/sing-box](https://github.com/SagerNet/sing-box)
- **Author**: WAHSUN

---

## License

[GPL-3.0](LICENSE)
