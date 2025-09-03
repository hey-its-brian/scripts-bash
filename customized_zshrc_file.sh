# Should be saved as .zshrc in home directory
# Must have Oh My ZSH installed & ZSH console activated


# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_DISABLE_COMPFIX=true

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="half-life"

zstyle ':omz:update' mode auto      # update automatically without asking
zstyle ':omz:update' frequency 10


eval $(thefuck --alias)
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(git
ruby
rails
1password
aliases
aws
brew
colorize
common-aliases
docker
github
history
iterm2
jira
kubectl
kubectx
macos
ssh
sublime
sudo
thefuck
vscode
z
alias-finder)

source $ZSH/oh-my-zsh.sh

###############################################################
# User configuration

# For a full list of active aliases, run `alias`.
alias k8=" sh ~/.scripts/k8_login_script.sh"
alias kpvt="kubectx dchbx-pvt-eks-cluster"
alias kprod="kubectx dchbx-prod-eks-cluster"
alias kpreprod="kubectx dchbx-preprod-eks-cluster"
alias ck="git checkout -b"
alias gc="git commit -m"
alias gp="git push origin"
alias gm="git switch main"
alias pr="gh pr create"

export PATH="$PATH:$HOME/.rvm/bin"

export GPG_TTY=$(tty)
