<p align="right">
  <b>English</b> | <a href="README.md">繁體中文</a>
</p>

# sbx — Next Generation sing-box Manager

> Modern sing-box Management Framework — pure Bash, themed, plugin-ready.

[![License](https://img.shields.io/badge/license-GPL--3.0-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%7C%20ARM64-green)]()
[![Bash](https://img.shields.io/badge/pure-bash-blue)]()

---

## Features

✓ **Pure Bash, zero deps** · ✓ **6 Themes** · ✓ **Bilingual** (EN / 繁中) · ✓ **Plugin Ready** · ✓ **Health Scoring** · ✓ **Atomic JSON** writes

---

## Quick Start

```bash
bash <(curl -sL https://raw.githubusercontent.com/C92D58/Sbx/main/install.sh)
```

**Local install:**

```bash
git clone https://github.com/C92D58/Sbx.git && cd Sbx
bash install.sh -l
```

---

## Core Commands

| Command | Description |
|---------|-------------|
| `sbx` | Interactive dashboard |
| `sbx add <protocol>` | Add config (reality / tuic / hy2 / trojan / ss …) |
| `sbx check` | Health check with scoring |
| `sbx theme` | Theme switching |

📖 [Full Command Reference](docs/commands.md)

---

## Dashboard

```
  sbx v2.0  ▶  running
  Next Generation sing-box Manager

  [1] Create    [2] Manage
  [3] Tools     [4] System    [5] Settings
  [0] Exit
```

---

## Supported Protocols

VLESS-REALITY · VLESS-WS-TLS · VLESS-H2-TLS · VMess-WS-TLS · Trojan-WS-TLS · TUIC · Hysteria2 · Shadowsocks · AnyTLS · SOCKS5

---

## Documentation

[Commands](docs/commands.md) · [DNS](docs/dns.md) · [Themes](docs/themes.md) · [Plugins](docs/plugins.md)

---

## Security

`jq --arg` injection-safe · `tmp + mv` atomic writes · `mktemp -d` secure temp

---

## Credits

sing-box core [SagerNet/sing-box](https://github.com/SagerNet/sing-box) · Author **WAHSUN** · [GPL-3.0](LICENSE)
