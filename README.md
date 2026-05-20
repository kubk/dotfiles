### Set up dotfiles on a new machine:
- `cd ~/projects && git clone git@github.com:kubk/dotfiles.git`

### Set up scripts
- Make sure you have a `.env` file in your dotfiles directory with your OpenAI API key (see `.env.example` for format)
- Run clipboard grammar as `~/projects/dotfiles/clipboard-grammar.sh`

### Set up npm

- `npm config set ignore-scripts true --global`

### Load aliases from both zsh and bash:

- Add `source ~/projects/dotfiles/aliases` to your `~/.zshrc` or `~/.bashrc`

### Set up a new symlinks:

- `mv ~/.vimrc ~/projects/dotfiles/.vimrc`
- `ln -s ~/projects/dotfiles/.vimrc ~/.vimrc`

### Codex skills

- Store custom Codex skills in `~/projects/dotfiles/.codex/skills/<skill-name>`
- Sync them into Codex with `~/projects/dotfiles/.codex/link-skills.sh`
- This links custom skills into `~/.codex/skills` without replacing Codex's built-in `.system` skills
- Current custom skills in this repo: `cmux-browser` and `exhaustive-checks`

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
