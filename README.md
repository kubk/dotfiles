### Set up dotfiles on a new machine:
- `cd ~/projects && git clone git@github.com:kubk/dotfiles.git`

### Set up a new symlink example:

- `mv ~/.vimrc ~/projects/dotfiles/.vimrc`
- `ln -s ~/projects/dotfiles/.vimrc ~/.vimrc`

### Load aliases from both zsh and bash:

- Add `source ~/projects/dotfiles/aliases` to your `~/.zshrc` or `~/.bashrc`

