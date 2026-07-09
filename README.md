<p align="right">
  <a href="README.en.md">English</a> | <b>繁體中文</b>
</p>

# sbx

> sing-box 管理腳本 — 簡潔高效、多語言、矩陣風格 UI。

---

## 快速安裝

```bash
# 安裝 (需要 Linux VPS root 權限)
bash <(curl -sL https://raw.githubusercontent.com/c92d58/sbx/main/install.sh)

# 或本地安裝
git clone https://github.com/c92d58/sbx.git
cd sbx
bash install.sh
```

安裝時會提示選擇語言（繁體中文 / English）。

---

## 功能列表

### 協議管理

| 命令 | 說明 |
|------|------|
| `sbx add reality` | 添加 VLESS-REALITY（默認） |
| `sbx add tuic` | 添加 TUIC |
| `sbx add trojan` | 添加 Trojan |
| `sbx add hy2` | 添加 Hysteria2 |
| `sbx add ss` | 添加 Shadowsocks 2022 |
| `sbx add anytls` | 添加 AnyTLS |
| `sbx add socks` | 添加 SOCKS5 |
| `sbx del <name>` | 刪除配置 |
| `sbx info [name]` | 查看配置詳情 |
| `sbx change <name> port 8443` | 更改端口 / UUID / 域名 / 路徑 / 密鑰等 |

配置檔案自動以隨機 5 位數字命名，簡短好記。

### DNS — NextDNS 多伺服器

```bash
sbx dns nextdns CONFIG_ID [設備名稱]
```

設定 **NextDNS**（DoH）為主伺服器，**Cloudflare H3** 和 **Google H3** 為備援。中國域名（`geosite-cn`）自動走本地解析器。

可選設備名稱，方便在 NextDNS 後台識別查詢來源：

```bash
sbx dns nextdns abc123 185-vps
```

也支援單伺服器預設：`sbx dns cf`、`sbx dns gg`、`sbx dns 11` 等。

### 測速

```bash
sbx speed vps          # VPS 頻寬測速（Cloudflare 10MB 下載）
sbx speed <name>       # 指定配置測速（端口檢查 + 頻寬）
sbx speed              # 全部配置測速
```

### 健康檢查

```bash
sbx check [name]       # 檢查：檔案完整性 + 端口監聽 + 核心狀態
```

### 備份還原

```bash
sbx backup             # 建立 /root/sbx-backup-*.tar.gz
sbx backup list        # 列出所有備份
sbx restore <file>     # 還原（自動先備份當前配置）
```

### 流量統計

```bash
sbx traffic [name]     # 顯示每個配置的 TCP 連線數
```

### 切換語言

```bash
sbx lang zh-TW         # 切換到繁體中文
sbx lang en            # 切換到英文
```

### 其他命令

| 命令 | 說明 |
|------|------|
| `sbx bbr` | 啟用 BBR TCP 擁塞控制 |
| `sbx log` | 查看 / 設定日誌等級 |
| `sbx status` | 查看服務狀態 |
| `sbx update core` | 更新 sing-box 核心（來自 SagerNet） |
| `sbx reinstall` | 重裝腳本 |
| `sbx uninstall` | 完全卸載 |
| `sbx qr <name>` | 生成配置 QR 碼 |
| `sbx lang` | 切換介面語言 |

---

## UI 風格

矩陣風格終端界面 — 全綠色文字、無背景色、對齊整潔：

```
> sbx v1.0 / sing-box v1.12.0 >> running
WAHSUN

> 18347
協議 (protocol)           VLESS-REALITY
地址 (address)            185.201.227.246
端口 (port)               8443
...

[!] 錯誤訊息（紅字）
[-] 警告提示（暗綠字）
>> 成功提示（亮綠字）
```

---

## 目錄結構

```
/etc/sbx/
├── bin/sing-box          # 核心二進位（來自 SagerNet/sing-box）
├── conf/*.json           # 每個協議一個設定檔
├── config.json           # 主設定檔（引入 conf/*.json）
├── sh/                   # 腳本檔案
│   └── src/              # 模組
│       ├── core.sh       # 主調度器
│       ├── dns.sh        # DNS 管理
│       ├── speed.sh      # 測速
│       ├── check.sh      # 健康檢查
│       ├── backup.sh     # 備份還原
│       ├── traffic.sh    # 流量統計
│       ├── lang/         # 語言包
│       │   ├── en.sh     # English
│       │   └── zh-TW.sh  # 繁體中文
│       └── ...
├── lang                  # 語言選擇檔案
└── bin/tls.*             # 臨時 TLS 憑證
```

---

## 致謝

- **sing-box 核心**: [SagerNet/sing-box](https://github.com/SagerNet/sing-box)
- **作者**: WAHSUN

---

## 許可證

GPL-3.0
