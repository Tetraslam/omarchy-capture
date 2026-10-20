# Capture for Omarchy

One key, type a thought, Enter, and it's at the top of a note in your Obsidian vault. No window to switch to, nothing else on screen.

- Opens on the first target every time; **Tab** cycles to the next (a todo list, a notes file, ...).
- **Enter** saves and closes, **Esc** throws it away.
- Task targets get a `- [ ] ` checkbox; line targets get the text as is. New entries go first, below any frontmatter.
- Writes are atomic plain file edits, so they work offline, and Obsidian (and Obsidian Sync) picks them up like any other change.

## Install

```bash
omarchy plugin add https://github.com/tetraslam/omarchy-capture --enable
```

Bind it in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + N", "Quick capture", hl.dsp.global("capture:toggle"))
```

## Targets

Without a config it writes to `0-inbox/todo.md` (tasks) and `0-inbox/notes.md` in `~/Documents/tetrawiki/tetrawiki`. Point it at your own vault with `~/.config/omarchy-capture/config.json`:

```json
{
  "targets": [
    { "label": "todo", "file": "~/vault/inbox/todo.md", "format": "task" },
    { "label": "notes", "file": "~/vault/inbox/notes.md", "format": "line" }
  ]
}
```

The file is watched, so edits apply immediately.

## License

MIT
