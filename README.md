<p align="right">
  <a href="README.en.md">English</a> | <b>繁體中文</b>
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
| ✓ **Pure Bash** | 零依賴，僅需 Bash + jq + curl |
| ✓ **Beautiful CLI** | Matrix 主題 + 6 種配色方案 |
| ✓ **Multi-language** | 繁體中文 / English 完整雙語 |
| ✓ **Plugin Ready** | 可擴展架構，不修改核心 |
| ✓ **Profile System** | 一鍵切換整組配置（Home / HK / US…） |
| ✓ **Health Scoring** | 視覺化健康分數 + 系統診斷 |
| ✓ **Atomic JSON** | 安全配置寫入 (`tmp + mv` 模式) |
| ✓ **Modern Architecture** | 模組化目錄，清晰的框架邊界 |

---

## 快速安裝

```bash
# 一鍵安裝（需要 Linux VPS root 權限）
bash <(curl -sL https://raw.githubusercontent.com/c92d58/Sbx/main/install.sh)
```

安裝時會提示選擇語言，並自動檢測作業系統、下載依賴和 sing-box 核心。

---

## 核心命令

| 命令 | 說明 |
|------|------|
| `sbx` | 進入互動儀表板（Dashboard） |
| `sbx create` | 互動式建立配置 |
| `sbx add <protocol>` | 快速添加配置（支援 reality / tuic / hy2 / trojan / ss 等） |
| `sbx dns <preset>` | DNS 設定（NextDNS / Cloudflare / Google…） |
| `sbx doctor` | 系統診斷（Kernel / BBR / DNS / TLS…） |
| `sbx bench` | 協議延遲基準測試 |
| `sbx check` | 健康檢查（含視覺化分數） |
| `sbx profile` | 設定檔管理（儲存 / 切換 / 刪除） |
| `sbx theme` | 主題切換（6 種配色） |
| `sbx plugin` | 插件管理 |
| `sbx matrix` | 進入母體 — Matrix 數位雨特效 |

完整命令手冊：[docs/commands.md](docs/commands.md)

---

## 儀表板

執行 `sbx` 進入互動儀表板：

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

所有功能從儀表板觸達——不必記憶命令。

---

## 系統診斷

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

## 協議基準測試

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

## 主題系統

```bash
sbx theme matrix         # 經典綠色（預設）
sbx theme catppuccin     # Catppuccin Mocha
sbx theme nord           # Nord
sbx theme dracula        # Dracula
sbx theme gruvbox        # Gruvbox
sbx theme tokyo-night    # Tokyo Night
sbx theme list           # 列出所有主題
```

---

## 設定檔管理

```bash
sbx profile save hk      # 儲存當前配置為 profile
sbx profile switch us    # 一鍵切換整組配置
sbx profile list         # 列出所有 profile
sbx profile delete old   # 刪除 profile
```

---

## 支援的協議

| 協議 | 傳輸層 | TLS | 命令 |
|------|--------|-----|------|
| VLESS-REALITY | TCP / H2 | Reality | `sbx add reality` |
| VLESS-WS-TLS | WebSocket | TLS (Caddy) | `sbx add vws` |
| VLESS-H2-TLS | HTTP/2 | TLS (Caddy) | `sbx add vh2` |
| VLESS-HTTPUpgrade-TLS | HTTPUpgrade | TLS (Caddy) | `sbx add vhu` |
| VMess-WS-TLS | WebSocket | TLS (Caddy) | `sbx add wss` |
| VMess-H2-TLS | HTTP/2 | TLS (Caddy) | `sbx add h2` |
| Trojan-WS-TLS | WebSocket | TLS (Caddy) | `sbx add tws` |
| Trojan-H2-TLS | HTTP/2 | TLS (Caddy) | `sbx add th2` |
| TUIC | QUIC | 內建 TLS | `sbx add tuic` |
| Hysteria2 | QUIC | 內建 TLS | `sbx add hy2` |
| Shadowsocks | TCP | 無 | `sbx add ss` |
| AnyTLS | TCP | ACME / 自簽 | `sbx add anytls` |
| SOCKS5 | TCP | 無 | `sbx add socks` |
| Direct | TCP | 無 | `sbx add door` |

---

## 目錄結構

```
/etc/sbx/sh/
├── core/                  # 核心框架
│   ├── init.sh            # 初始化
│   ├── dispatcher.sh      # CLI 路由
│   ├── theme.sh           # 主題引擎
│   └── plugin.sh          # 插件系統
├── modules/
│   ├── network/           # DNS / 測速 / 協議
│   ├── service/           # systemd / Caddy / BBR
│   ├── tools/             # 備份 / 檢查 / 流量 / 日誌 / 醫生 / 基準測試
│   └── ui/                # 儀表板 / Matrix / 主題 UI
├── themes/                # 6 種配色主題
├── plugins/               # 可擴展插件
├── profiles/              # 設定檔快照
└── lang/                  # 語言包
```

---

## 技術細節

- **核心**：SagerNet/sing-box，自動獲取最新版本
- **初始化系統**：支援 systemd 和 OpenRC
- **作業系統**：Ubuntu / Debian / CentOS / Alpine / SUSE
- **架構**：x86_64 / ARM64
- **加速**：自動啟用 BBR（kernel ≥ 4.9）
- **NTP**：自動同步時間
- **雙語**：完整繁體中文 + English 語言包

---

## 安全

- 使用 `jq --arg` 安全傳遞變數（防 JSON 注入）
- 配置文件原子化寫入（`tmp + mv` 模式防截斷）
- IP 解析使用 `sed` 安全提取（非 `eval`/`export`）
- 安全的臨時目錄建立（`mktemp -d`）

---

## 文件

- [完整命令手冊](docs/commands.md)
- [DNS 配置](docs/dns.md)
- [主題指南](docs/themes.md)
- [插件開發](docs/plugins.md)
- [Profile 使用](docs/profiles.md)

---

## 致謝

- **sing-box 核心**：[SagerNet/sing-box](https://github.com/SagerNet/sing-box)
- **作者**：WAHSUN

---

## 許可證

[GPL-3.0](LICENSE)
