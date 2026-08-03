<p align="right">
  <a href="README.en.md">English</a> | <b>繁體中文</b>
</p>

# sbx — Next Generation sing-box Manager

> Modern sing-box Management Framework — 純 Bash、主題化、插件可擴展。

[![License](https://img.shields.io/badge/license-GPL--3.0-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%7C%20ARM64-green)]()
[![Bash](https://img.shields.io/badge/pure-bash-blue)]()

---

## 特性

✓ **純 Bash 零依賴** · ✓ **6 種主題** · ✓ **雙語**（繁中/EN）· ✓ **Plugin 擴展** · ✓ **Health 評分** · ✓ **Atomic JSON** 安全寫入

---

## 快速安裝

> ⚠️ **Repo 目前為 private** — 安裝與升級都需 GitHub Token 認證。

```bash
# 1. 設定 GitHub Token（repo 為 private，需有 repo 讀取權限）
export GITHUB_TOKEN=ghp_xxxx

# 2. 快速安裝（curl 帶 token 抓取 install.sh）
bash <(curl -sL -H "Authorization: token $GITHUB_TOKEN" https://raw.githubusercontent.com/C92D58/Sbx/main/install.sh)
```

**本地安裝（不需 token）：**

```bash
git clone https://github.com/C92D58/Sbx.git && cd Sbx
bash install.sh -l
```

> 伺服器已安裝的版本，升級前先 `export GITHUB_TOKEN=ghp_xxxx`（`sbx update sh` 內部下載亦需 token）。

---

## 核心命令

| 命令 | 說明 |
|------|------|
| `sbx` | 互動儀表板 |
| `sbx add <protocol>` | 添加配置（reality / tuic / hy2 / trojan / ss …） |
| `sbx dns <preset>` | DNS 設定 |
| `sbx check` | 健康檢查（含評分） |
| `sbx theme` | 主題切換 |

📖 [完整命令手冊](docs/commands.md)

---

## 儀表板

```
  sbx v2.0  ▶  running
  Next Generation sing-box Manager

  [1] Create    [2] Manage    [3] DNS
  [4] Tools     [5] System    [6] Settings
  [0] Exit
```

---

## 支援協議

VLESS-REALITY · VLESS-WS-TLS · VLESS-H2-TLS · VMess-WS-TLS · Trojan-WS-TLS · TUIC · Hysteria2 · Shadowsocks · AnyTLS · SOCKS5

---

## 文件

[命令手冊](docs/commands.md) · [DNS 配置](docs/dns.md) · [主題指南](docs/themes.md) · [插件開發](docs/plugins.md)

---

## 安全

`jq --arg` 防注入 · `tmp + mv` 原子寫入 · `mktemp -d` 安全暫存

---

## 致謝

sing-box 核心 [SagerNet/sing-box](https://github.com/SagerNet/sing-box) · 作者 **WAHSUN** · [GPL-3.0](LICENSE)
