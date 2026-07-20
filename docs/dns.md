# DNS Configuration

sbx supports flexible DNS configuration with multi-server fallback.

## Quick Presets

```bash
sbx dns cf          # Cloudflare H3
sbx dns gg          # Google H3
sbx dns 11          # 1.1.1.1 (UDP)
sbx dns 88          # 8.8.8.8 (UDP)
sbx dns family      # Cloudflare Family (malware filtering)
sbx dns none        # Clear DNS
```

## Custom DNS

```bash
sbx dns set h3://dns.example.com/dns-query
sbx dns set tls://dns.example.com
sbx dns set https://dns.example.com/dns-query
sbx dns set tcp://10.0.0.1
sbx dns set udp://10.0.0.1
```

## NextDNS Multi-Server

NextDNS provides the most feature-rich setup with three-tier fallback:

```bash
sbx dns nextdns <config_id>              # Basic
sbx dns nextdns <config_id> <device>     # With device name
```

Example:
```bash
sbx dns nextdns abc123
sbx dns nextdns abc123 my-vps-tokyo
```

### Architecture

```
NextDNS (DoH, primary)
    ↓ (fallback)
Cloudflare (H3)
    ↓ (fallback)
Google (H3)
    ↓ (fallback)
Local resolver (for geosite-cn)
```

`geosite-cn` domains automatically route to the local resolver.

## DNS in config.json

All DNS settings modify `/etc/sbx/config.json` directly using `jq` for atomic writes.
