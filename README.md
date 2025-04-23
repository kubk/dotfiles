### Set up dotfiles on a new machine:
- `cd ~/projects && git clone git@github.com:kubk/dotfiles.git`

### Set up scripts
- Make sure you have a `.env` file in your dotfiles directory with your OpenAI API key (see `.env.example` for format)
- `sudo ln -s ~/projects/dotfiles/ai-concat.sh /usr/local/bin/ai-concat.sh`
- Run clipboard grammar as `~/projects/dotfiles/clipboard-grammar.sh`

### Load aliases from both zsh and bash:

- Add `source ~/projects/dotfiles/aliases` to your `~/.zshrc` or `~/.bashrc`

### Set up a new symlink example:

- `mv ~/.vimrc ~/projects/dotfiles/.vimrc`
- `ln -s ~/projects/dotfiles/.vimrc ~/.vimrc`

### Set up Vimium

- Hit `?` in Vim mode > Option > Custom key mappings > Insert the `vimium` file

### VSCode

#### Fix zoom

- Open VS Code
- Press Cmd+Shift+P (Mac), Type "Preferences: Open User Settings (JSON)" and select it
- Add "window.zoomLevel": 2
  

