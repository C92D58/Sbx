# Plugin Development

Plugins extend sbx without modifying core code.

## Quick Start

Create a directory under `plugins/<name>/` with a `plugin.sh`:

```bash
mkdir -p plugins/my-plugin
```

## plugin.sh Structure

```bash
#!/bin/bash
# Plugin: My Plugin
# Description: Does something useful

plugin_info() {
    echo "my-plugin|1.0.0|Does something useful"
}

plugin_init() {
    # Called at startup
    # Register commands, hooks, menu items here
    :
}
```

## API Reference

### `plugin_info()`

Must return a pipe-delimited string: `name|version|description`

Used by `sbx plugin list` and `sbx plugin <name>`.

### `plugin_init()`

Called when sbx starts. Use this to:
- Register custom commands
- Add menu items
- Set up hooks
- Initialize plugin state

## Installation

Plugins are installed by placing them in the plugins directory:

```
/etc/sbx/sh/plugins/
├── warp/
│   └── plugin.sh
├── telegram/
│   └── plugin.sh
└── my-plugin/
    └── plugin.sh
```

## Coming Soon

- Hook system for lifecycle events (`pre_start`, `post_stop`, `on_config_change`)
- Remote plugin registry with `sbx plugin install <url>`
- Plugin configuration UI
- Plugin dependency management
