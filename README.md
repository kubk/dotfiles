### Set up dotfiles on a new machine:
- `cd ~/projects && git clone git@github.com:kubk/dotfiles.git`

### Set up scripts

- Make sure you have a `.env` file in your dotfiles directory with your Vercel AI Gateway API key (see `.env.example` for format)
- Run clipboard grammar as `~/projects/dotfiles/clipboard-grammar.sh`
- Make the MCP cleanup scripts globally available:

```sh
ln -s ~/projects/dotfiles/kill-chrome-mcp.sh ~/.local/bin/kill-chrome-mcp.sh
ln -s ~/projects/dotfiles/kill-pg-mcp.sh ~/.local/bin/kill-pg-mcp.sh
ln -s ~/projects/dotfiles/kill-all-mcp.sh ~/.local/bin/kill-all-mcp.sh
```

### Set up npm

- `npm config set ignore-scripts true --global`

### Load aliases from both zsh and bash:

- Add `source ~/projects/dotfiles/aliases` to your `~/.zshrc` or `~/.bashrc`

### Set up a new symlinks:

- `mv ~/.vimrc ~/projects/dotfiles/.vimrc`
- `ln -s ~/projects/dotfiles/.vimrc ~/.vimrc`
- `mkdir -p ~/.config`
- `ln -s ~/projects/dotfiles/.config/nvim ~/.config/nvim`

### Neovim

Install these before using the Neovim config:

- `@vtsls/language-server` installed globally with npm
- `fzf` and `ripgrep`
- `lazy.nvim` at `~/.local/share/nvim/lazy/lazy.nvim`

`lazy-lock.json` pins and installs the editor plugins, but it cannot install
Neovim, command-line tools, the TypeScript language server, or `lazy.nvim`
itself.

- `Space e` → toggle the file tree
- `Ctrl+h` → move to the file tree / left window
- `Ctrl+l` → move to the editor / right window
- `Space p` → fuzzy-search all project files (`.gitignore` is respected)
- In insert mode, `Tab` → select/accept an autocomplete suggestion
- In insert mode, `Shift+Tab` → move backward through snippet placeholders
- In insert mode, `Ctrl+Space` → manually open autocomplete or documentation

### Codex skills

- Store custom Codex skills in `~/projects/dotfiles/.codex/skills/<skill-name>`
- Sync them into Codex with `~/projects/dotfiles/.codex/link-skills.sh`
- This links custom skills into `~/.codex/skills` without replacing Codex's built-in `.system` skills
- Current custom skills in this repo: `cmux-browser` and `exhaustive-checks`

### Cmux

- Press `Cmd+Shift+P`, search for **Show Listening Ports in Sidebar**, and toggle it off

### Spotlight

- Exclude `~/projects` from indexing in **System Settings → Spotlight → Search Privacy**

### Set up Vimium

- Hit `?` in Vim mode > Option > Custom key mappings > Insert the `vimium` file

### Git
- `git config --global core.editor "vim"`
- `git config --global push.autoSetupRemote true`

### Raycast app hotkeys

- Disable/override default macOS shortcut
  - `System Settings > Keyboard > Keyboard Shortcuts > Window > Minimize` → re-assign `Cmd+M` to an impossible shortcut
- Main app shortcuts
  - `Cmd+G` → Google Chrome
  - `Cmd+E` → Telegram
  - `Cmd+M` → Cmux
  - `Cmd+E` → Apple Notes
- To set this in Raycast
  - Open settings with `Cmd+,`
  - Go to **Extensions**
  - Find the app extension and set the desired key in **Hotkey**
