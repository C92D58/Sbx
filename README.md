<p align="right">
  <a href="README.en.md">English</a> | <b>繁體中文</b>
</p>

# sbx

> sing-box 管理腳本 — Matrix 黑客帝國風格、雙語界面、簡潔高效。

[![License](https://img.shields.io/badge/license-GPL--3.0-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Linux%20x86__64%20%7C%20ARM64-green)]()

---

## 快速安裝

```bash
# 一鍵安裝（需要 Linux VPS root 權限）
bash <(curl -sL https://raw.githubusercontent.com/c92d58/Sbx/main/install.sh)

# 或本地安裝
git clone https://github.com/c92d58/Sbx.git
cd sbx
bash install.sh
```

安裝時會提示選擇語言（繁體中文 / English），並自動檢測作業系統、下載依賴和 sing-box 核心。

---

## 命令總覽

### 協議管理

| 命令 | 說明 |
|------|------|
| `sbx add reality` | 添加 VLESS-REALITY（預設） |
| `sbx add tuic` | 添加 TUIC（支援 congestion_control） |
| `sbx add trojan` | 添加 Trojan（TLS / no-TLS） |
| `sbx add hy2` | 添加 Hysteria2 |
| `sbx add ss` | 添加 Shadowsocks（支援 2022 加密） |
| `sbx add anytls` | 添加 AnyTLS（支援 ACME 自動 TLS） |
| `sbx add socks` | 添加 SOCKS5（用戶名 / 密碼驗證） |
| `sbx add `*ws/h2/hu* | 添加 TLS 協議（自動配置 Caddy） |
| `sbx del <name>` | 刪除配置 |
| `sbx info [name]` | 查看配置詳情 |
| `sbx url <name>` | 顯示配置分享連結 |
| `sbx qr <name>` | 生成配置 QR 碼 |
| `sbx change <name> ...` | 更改端口 / UUID / 域名 / 路徑 / 密鑰 / SNI / 加密等 |

配置檔案以隨機 5 位數字命名，簡短好記。支援一次添加多個配置，每個配置獨立管理。

**`sbx change` 支援的更改項：**

```
port      passwd    id/uuid    host      path
method    key       sni        web       new
door-addr door-port full       user
```

```bash
sbx change 18347 port 8443           # 更改端口
sbx change 18347 id auto             # 自動生成新 UUID
sbx change 18347 key auto            # 自動生成新密鑰對
sbx change 18347 full auto           # 一鍵重置所有參數
sbx fix 18347                        # 等同 full
sbx fix-all                          # 批次修復全部配置
```

### DNS 管理

```bash
sbx dns nextdns CONFIG_ID [裝置名稱]   # NextDNS (DoH) + CF H3 + Google H3 備援
sbx dns cf                            # Cloudflare H3
sbx dns gg                            # Google H3
sbx dns 11                            # 1.1.1.1 (UDP)
sbx dns 88                            # 8.8.8.8 (UDP)
sbx dns family                        # Cloudflare Family (惡意軟體過濾)
sbx dns set <address>                 # 自訂 DNS（支援 h3:// tls:// https:// tcp:// udp://）
sbx dns none                          # 清除 DNS 設定
```

**NextDNS 多伺服器範例：**

```bash
sbx dns nextdns abc123               # 基本設定
sbx dns nextdns abc123 185-vps       # 附加裝置名稱（在 NextDNS 後台識別來源）
```

DNS 配置採用三層備援：NextDNS（主）→ Cloudflare H3 → Google H3，`geosite-cn` 域名自動走本地 DNS。

### 測速

```bash
sbx speed vps          # VPS 頻寬測速（Cloudflare Speedtest 10MB）
sbx speed <name>       # 指定配置測速（端口檢查 + 頻寬）
sbx speed              # 全部配置測速
```

### 健康檢查

```bash
sbx check [name]       # 檢查：檔案完整性 + 端口監聽 + 核心狀態
```

輸出每個配置的檔案校驗、端口監聽、核心執行三項狀態，全部通過則顯示 `全部正常`。

### 流量統計

```bash
sbx traffic [name]     # 顯示每個配置的活躍 TCP 連線數
```

### 備份還原

```bash
sbx backup             # 建立備份 /root/sbx-backup-*.tar.gz
sbx backup list        # 列出所有備份（含檔案大小）
sbx restore <file>     # 還原備份（自動先備份當前配置）
```

### 日誌管理

```bash
sbx log                # 即時查看日誌（tail -f）
sbx log info           # 設定日誌等級
sbx log warn           # 僅顯示警告及以上
sbx log error          # 僅顯示錯誤
sbx log none           # 關閉日誌
sbx log del            # 刪除所有日誌檔案
```

日誌等級：`trace` > `debug` > `info` > `warn` > `error` > `fatal` > `panic`

### 服務控制

```bash
sbx status             # 查看 sing-box / Caddy 服務狀態
sbx start              # 啟動 sing-box
sbx stop               # 停止 sing-box
sbx restart            # 重啟 sing-box
sbx start caddy        # 啟動 Caddy
sbx stop caddy         # 停止 Caddy
sbx restart caddy      # 重啟 Caddy
sbx t                  # 測試運行（診斷啟動失敗）
```

### 更新

```bash
sbx update core        # 更新 sing-box 核心（來自 SagerNet）
sbx update sh           # 更新管理腳本
sbx update caddy        # 更新 Caddy web 伺服器
sbx U                   # 快速更新腳本（等同 update sh）
sbx reinstall           # 重裝腳本
```

### 其他命令

| 命令 | 說明 |
|------|------|
| `sbx bbr` | 啟用 BBR TCP 擁塞控制（需 kernel ≥ 4.9） |
| `sbx lang zh-TW` | 切換至繁體中文 |
| `sbx lang en` | 切換至 English |
| `sbx version` | 顯示版本資訊 |
| `sbx ip` | 顯示伺服器 IP |
| `sbx pbk` | 生成 reality 金鑰對 |
| `sbx ss2022` | 生成 Shadowsocks 2022 相容密碼 |
| `sbx get-port` | 取得可用端口 |
| `sbx debug <name>` | 輸出配置 Debug 資訊 |
| `sbx gen ...` | 生成 JSON 預覽（不寫入檔案） |
| `sbx no-auto-tls ...` | 添加無自動 TLS 的配置 |
| `sbx import` | 從 Xray / V2Ray 匯入配置 |
| `sbx fix-config.json` | 重建主配置檔 |
| `sbx fix-caddyfile` | 重建 Caddyfile |
| `sbx bin ...` | 直接執行 sing-box 核心指令 |
| `sbx matrix` | 進入母體 — Matrix 黑客帝國特效 |
| `sbx uninstall` | 完全卸載（含 Caddy 選擇項） |

---

## Matrix 特效

```bash
sbx matrix             # 完整入場：數字雨 → ASCII Logo → 打字機狀態 → 脈衝掃描線
sbx matrix rain        # 僅播放 8 秒數字雨動畫
sbx matrix logo        # 僅顯示 ASCII Art 橫幅
```

主選單中按 `m` 也可觸發。特效包含：

- **Matrix Rain** — 片假名字元綠色瀑布（自適應終端尺寸）
- **ASCII Logo** — `▐▌ ░▒▓█` 字元構成的品牌橫幅
- **Typewriter Effect** — 逐字打字機效果
- **Glitch Reveal** — 亂碼故障過渡至清晰文字
- **Pulse Line** — 掃描線橫跨終端

---

## UI 風格

Matrix 黑客帝國主題——全綠色文字、黑色背景、無背景色塊、對齊整潔：

```
┌─────────────────────────────────────────────┐
│  ▀█▀ █▀▄ ▀ ▀   sbx v1.0  >> running    │
│   █  █▀  ▀█▀   sing-box manager          │
└─────────────────────────────────────────────┘

[1] 配置     [2] DNS        [3] 工具
[4] 系統     [5] 幫助       [m] 母體

>>

> 18347
協議 (protocol)      VLESS-REALITY    ← 暗綠標籤 亮綠值
地址 (address)       185.201.227.246
端口 (port)          8443
...
> URL
vless://...@185.201.227.246:8443?...   ← 亮綠分享連結

[!] 錯誤訊息（紅字，僅用於關鍵錯誤）
[-] 警告提示（暗綠字，裝飾與提示）
>> 成功提示（亮綠字，操作成功）
```

---

## 目錄結構

### 安裝後 (`/etc/sbx/`)

```
/etc/sbx/
├── bin/
│   ├── sing-box          # 核心二進位（SagerNet/sing-box）
│   ├── tls.cer           # 臨時 TLS 證書
│   └── tls.key           # 臨時 TLS 密鑰
├── conf/
│   └── *.json            # 每個協議一個配置檔（如 18347.json）
├── config.json           # 主配置（引入 conf/*.json）
├── sh/                   # 腳本目錄
│   ├── sbx.sh            # 主入口
│   ├── install.sh        # 安裝腳本
│   ├── src/              # 模組
│   │   ├── core.sh       # 主調度器 (CLI + 選單)
│   │   ├── init.sh       # 初始化 (變數 / 語言 / 環境)
│   │   ├── dns.sh        # DNS 管理
│   │   ├── speed.sh      # 測速
│   │   ├── check.sh      # 健康檢查
│   │   ├── backup.sh     # 備份還原
│   │   ├── traffic.sh    # 流量統計
│   │   ├── log.sh        # 日誌管理
│   │   ├── matrix.sh     # Matrix 特效
│   │   ├── bbr.sh        # BBR 擁塞控制
│   │   ├── caddy.sh      # Caddy TLS 整合
│   │   ├── download.sh   # 核心/腳本下載
│   │   ├── systemd.sh    # systemd/OpenRC 服務
│   │   ├── import.sh     # 配置匯入
│   │   ├── help.sh       # 幫助
│   │   └── lang/         # 語言包
│   │       ├── en.sh     # English
│   │       └── zh-TW.sh  # 繁體中文
│   └── tools/
│       └── qr.html       # QR 碼生成器
└── lang                  # 語言選擇檔
```

---

## 支援的協議

| 協議 | 傳輸層 | TLS 支援 | 命令 |
|------|--------|----------|------|
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

## 技術細節

- **核心**：使用 SagerNet/sing-box，自動從 GitHub Releases 獲取最新版本
- **初始化系統**：支援 systemd 和 OpenRC
- **作業系統**：Ubuntu / Debian / CentOS / Alpine / SUSE
- **架構**：x86_64 / ARM64
- **加速**：自動啟用 BBR（kernel ≥ 4.9）
- **NTP**：自動同步時間（Apple NTP 伺服器）
- **雙語**：完整繁體中文 + English 語言包，安裝時可選，隨時可切換
- **導入**：支援從 Xray / V2Ray 配置匯入

---

## 安全

- 使用 `jq --arg` 安全傳遞變數（防 JSON 注入）
- 配置文件原子化寫入（`tmp + mv` 模式防截斷）
- IP 解析使用 `sed` 安全提取（非 `eval`/`export`）
- 安全的臨時目錄建立（`mktemp -d`）
- 預設以 root 執行（VPS 環境標準做法）

---

## 致謝

- **sing-box 核心**：[SagerNet/sing-box](https://github.com/SagerNet/sing-box)
- **作者**：WAHSUN

---

## 許可證

[GPL-3.0](LICENSE)
