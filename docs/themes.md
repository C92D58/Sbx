# Theme System

sbx supports 6 color themes. Switch at any time — no restart required.

## Available Themes

| Theme | Style | Command |
|-------|-------|---------|
| **Matrix** | Classic green-on-black (default) | `sbx theme matrix` |
| **Catppuccin** | Warm pastel — Mocha variant | `sbx theme catppuccin` |
| **Nord** | Cool arctic tones | `sbx theme nord` |
| **Dracula** | Vibrant purple-dark | `sbx theme dracula` |
| **Gruvbox** | Warm retro | `sbx theme gruvbox` |
| **Tokyo Night** | Neon on deep dark | `sbx theme tokyo-night` |

## Usage

```bash
# List all themes
sbx theme list

# Show current theme
sbx theme

# Switch theme
sbx theme dracula
```

## How It Works

Themes are shell scripts in `/etc/sbx/sh/themes/` that export color variables:

```bash
export c_bright='\e[92m'       # primary text
export c_green='\e[32m'        # body text
export c_dim='\e[2m\e[32m'     # dim / decorations
export c_red='\e[91m'          # errors only
export c_none='\e[0m'          # reset
export c_accent='\e[96m'       # accent color
export c_border='\e[2m\e[32m'  # borders
```

## Creating Custom Themes

Create a new file in `/etc/sbx/sh/themes/<name>.sh`:

```bash
# themes/mytheme.sh
export c_bright='\e[38;2;200;200;200m'    # RGB true color
export c_green='\e[38;2;100;200;100m'
export c_dim='\e[38;2;80;80;80m'
export c_red='\e[38;2;255;80;80m'
export c_none='\e[0m'
export c_accent='\e[38;2;100;150;255m'
export c_border='\e[38;2;60;60;60m'
```

Then switch to it:
```bash
sbx theme mytheme
```

Both ANSI 16-color codes and 24-bit RGB (`\e[38;2;R;G;Bm`) are supported.
