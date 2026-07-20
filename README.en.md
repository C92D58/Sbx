<p align="right">
  <b>English</b> | <a href="README.md">繁體中文</a>
</p>

# sbx — Next Generation sing-box Manager

> Modern sing-box Management Framework — Matrix CLI, plugin-ready, multi-profile.

[![License](https://img.shields.io/badge/license-GPL--3.0-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%7C%20ARM64-green)]()
[![Bash](https://img.shields.io/badge/pure-bash-blue)]()

---

## Why sbx?

✓ **Pure Bash** — zero deps · ✓ **6 Themes** — Matrix / Catppuccin / Nord / Dracula / Gruvbox / Tokyo Night · ✓ **Bilingual** — EN / 繁體中文 · ✓ **Plugin Ready** · ✓ **Profile System** · ✓ **Health Scoring + Diagnostics** · ✓ **Atomic JSON** writes

---

## Quick Start

```bash
bash <(curl -sL https://raw.githubusercontent.com/c92d58/Sbx/main/install.sh)
```

---

## Core Commands

| Command | Description |
|---------|-------------|
| `sbx` | Interactive dashboard |
| `sbx add <protocol>` | Add config (reality / tuic / hy2 / trojan / ss …) |
| `sbx dns <preset>` | DNS setup |
| `sbx doctor` | System diagnostics |
| `sbx bench` | Protocol latency benchmark |
| `sbx check` | Health check with scoring |
| `sbx profile` | Profile management |
| `sbx theme` | Theme switching |
| `sbx matrix` | Enter the Matrix |

📖 [Full Command Reference](docs/commands.md)

---

## Dashboard

```
  sbx v2.0  ▶  running
  Next Generation sing-box Manager
  ─────────────────────────────────
  By: WAHSUN

  Health: 98/100 ★★★★★  3 configs

  [1] Create       [2] Manage       [3] DNS
  [4] Tools        [5] Profiles     [6] System
  [7] Themes       [8] Plugins      [9] Help
  [0] Exit         [m] Matrix
```

---

## Doctor

```bash
$ sbx doctor
  Kernel 5.15  PASS    BBR enabled  PASS    DNS resolving  PASS
  Time synced  PASS    Firewall     PASS    sing-box       PASS
  >> Your server is healthy.
```

---

## Supported Protocols

VLESS-REALITY · VLESS-WS-TLS · VLESS-H2-TLS · VLESS-HTTPUpgrade-TLS · VMess-WS-TLS · VMess-H2-TLS · Trojan-WS-TLS · Trojan-H2-TLS · TUIC · Hysteria2 · Shadowsocks · AnyTLS · SOCKS5 · Direct

---

## Documentation

- [Commands](docs/commands.md) · [DNS](docs/dns.md) · [Themes](docs/themes.md) · [Plugins](docs/plugins.md) · [Profiles](docs/profiles.md)

---

## Security

`jq --arg` injection-safe · `tmp + mv` atomic writes · `mktemp -d` secure temp

---

## Credits

sing-box core [SagerNet/sing-box](https://github.com/SagerNet/sing-box) · Author **WAHSUN** · [GPL-3.0](LICENSE)
