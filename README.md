<p align="right">
  <a href="README.en.md">English</a> | <b>繁體中文</b>
</p>

# sbx — Next Generation sing-box Manager

> Modern sing-box Management Framework — Matrix CLI, plugin-ready, multi-profile.

[![License](https://img.shields.io/badge/license-GPL--3.0-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%7C%20ARM64-green)]()
[![Bash](https://img.shields.io/badge/pure-bash-blue)]()

---

## Why sbx?

✓ **Pure Bash** — 零依賴 · ✓ **6 種主題** — Matrix / Catppuccin / Nord / Dracula / Gruvbox / Tokyo Night · ✓ **雙語** — 繁體中文 / English · ✓ **Plugin 可擴展** · ✓ **Profile 一鍵切換** · ✓ **Health 評分 + 系統診斷** · ✓ **Atomic JSON** 安全寫入

---

## 快速安裝

```bash
bash <(curl -sL https://raw.githubusercontent.com/c92d58/Sbx/main/install.sh)
```

---

## 核心命令

| 命令 | 說明 |
|------|------|
| `sbx` | 互動儀表板 |
| `sbx add <protocol>` | 添加配置（reality / tuic / hy2 / trojan / ss …） |
| `sbx dns <preset>` | DNS 設定 |
| `sbx doctor` | 系統診斷 |
| `sbx bench` | 協議延遲基準測試 |
| `sbx check` | 健康檢查（含評分） |
| `sbx profile` | 設定檔管理 |
| `sbx theme` | 主題切換 |
| `sbx matrix` | Matrix 數位雨 |

📖 [完整命令手冊](docs/commands.md)

---

## 儀表板

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

## 系統診斷

```bash
$ sbx doctor
  Kernel 5.15  PASS    BBR enabled  PASS    DNS resolving  PASS
  Time synced  PASS    Firewall     PASS    sing-box       PASS
  >> Your server is healthy.
```

---

## 支援協議

VLESS-REALITY · VLESS-WS-TLS · VLESS-H2-TLS · VLESS-HTTPUpgrade-TLS · VMess-WS-TLS · VMess-H2-TLS · Trojan-WS-TLS · Trojan-H2-TLS · TUIC · Hysteria2 · Shadowsocks · AnyTLS · SOCKS5 · Direct

---

## 文件

- [命令手冊](docs/commands.md) · [DNS 配置](docs/dns.md) · [主題指南](docs/themes.md) · [插件開發](docs/plugins.md) · [Profile 使用](docs/profiles.md)

---

## 安全

`jq --arg` 防注入 · `tmp + mv` 原子寫入 · `mktemp -d` 安全暫存

---

## 致謝

sing-box 核心 [SagerNet/sing-box](https://github.com/SagerNet/sing-box) · 作者 **WAHSUN** · [GPL-3.0](LICENSE)
