# .zshrc

# Add `~/bin` to the `$PATH`
# export PATH="$HOME/bin:$PATH";
# export PATH="$PATH:/usr/local/sbin"
# export PATH="$HOME/.cargo/bin:$PATH";
# INSTALL: mkdir -p "$HOME/.zsh"
# INSTALL: git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
fpath+=$HOME/.zsh/pure

autoload -U +X bashcompinit && bashcompinit
autoload -U +X compinit && compinit

# INSTALL: git clone https://github.com/lukechilds/zsh-nvm.git ~/.zsh-nvm
[[ -s "~/.zsh-nvm/zsh-nvm.plugin.zsh" ]] && source ~/.zsh-nvm/zsh-nvm.plugin.zsh

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
  # echo "Sourcing $file"
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

autoload -U promptinit; promptinit
prompt pure

# place this after nvm initialization!
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Add tab completion for many brew commands
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH

  autoload -Uz compinit
  compinit
fi

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &> /dev/null; then
	complete -o default -o nospace -F _git g;
fi;

# heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH=/Users/tomfuertes/Library/Caches/heroku/autocomplete/zsh_setup && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

# rvm
# [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

# rbenv
# eval "$(rbenv init - zsh)"
