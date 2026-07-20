# sbx Plugin System

Plugins extend sbx without modifying core code.

## Plugin Structure

```
plugins/<name>/
└── plugin.sh          # entry point (required)
```

## plugin.sh API

Each plugin must define two functions:

### `plugin_info()`
Returns a pipe-delimited string: `name|version|description`

```bash
plugin_info() {
    echo "my-plugin|1.0.0|Does something useful"
}
```

### `plugin_init()`
Called at startup. Register hooks, commands, or menu items here.

```bash
plugin_init() {
    # Add to menu, register command handlers, etc.
}
```

## Coming Soon

- Hook system for lifecycle events (pre-start, post-stop, etc.)
- Plugin registry with `sbx plugin install <url>`
- Plugin configuration UI
