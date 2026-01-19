### Set up dotfiles on a new machine:
- `cd ~/projects && git clone git@github.com:kubk/dotfiles.git`

### Set up scripts
- Make sure you have a `.env` file in your dotfiles directory with your OpenAI API key (see `.env.example` for format)
- Run clipboard grammar as `~/projects/dotfiles/clipboard-grammar.sh`

### Load aliases from both zsh and bash:

- Add `source ~/projects/dotfiles/aliases` to your `~/.zshrc` or `~/.bashrc`

### Set up a new symlinks:

- `mv ~/.vimrc ~/projects/dotfiles/.vimrc`
- `ln -s ~/projects/dotfiles/.vimrc ~/.vimrc`
- `ln -s ~/projects/dotfiles/.claude/commands ~/.claude/commands`

### Set up Vimium

- Hit `?` in Vim mode > Option > Custom key mappings > Insert the `vimium` file

### Git
- `git config --global core.editor "vim"`
- `git config --global push.autoSetupRemote true`

### VSCode

#### Fix zoom

- Press Cmd+Shift+P, Type "Preferences: Open User Settings (JSON)" and select it
- Add "window.zoomLevel": 2
  
#### Shortcut to maximize / minimize Terminal

- Press Cmd+Shift+P, Type "Keyboard shorcuts" > "Toggle Maximized Panel" and send Cmd+Shift+W as a shortcut

### Run VSCode from terminal
- `Cmd + Shift + P`, type 'Install', select 'Install 'code' command in PATH'

#### Make Shift+Enter work with Claude Code

- Run Claude inside VSCode terminal, then `/terminal-setup`

#### Disable Screen Reader sounds

- Press Cmd+Shift+P, Type "Preferences: Open User Settings (JSON)" and select it
- Add `"editor.accessibilitySupport": "off"`

#### Enable Confirm Before Close

- Cmd+, then type "Window close" > Always

