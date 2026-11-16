# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="" # Starship initializes the prompt below.

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Keep world-writable folders blue and make executable filenames bright green.
export LS_COLORS="${LS_COLORS}:ow=01;34:ex=01;92:"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# custom configs

# Let Starship display the active Conda environment.
export CONDA_CHANGEPS1=false

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ujjwal/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/ujjwal/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/ujjwal/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/ujjwal/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias icat='kitten icat'

path+=/opt/cuda/bin
path+=/opt/cuda/nsight_compute

# configured cd on exit. Note that the file has been changed 7-6-2025 to umask ^Q and use ^G
# if [ -f /usr/share/nnn/quitcd/quitcd.bash_sh_zsh ]; then
#     source /usr/share/nnn/quitcd/quitcd.bash_sh_zsh
# fi


### These lines are for the NNN file manager -- 8/2/2025

# export NNN_FIFO='/tmp/nnn.fifo'
# export NNN_PLUG='p:preview-tui'
# export VISUAL=nvim
# export EDITOR=nvim
#
# n ()
# {
#     # Block nesting of nnn in subshells
#     [ "${NNNLVL:-0}" -eq 0 ] || {
#         echo "nnn is already running"
#         return
#     }
#
#     # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
#     # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
#     # see. To cd on quit only on ^G, remove the "export" and make sure not to
#     # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
#     #      NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
#     NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
#
#     # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
#     # stty start undef
#     # stty stop undef
#     # stty lwrap undef
#     # stty lnext undef
#
#     # The command builtin allows one to alias nnn to n, if desired, without
#     # making an infinitely recursive alias
#     command nnn "$@"
#
#     [ ! -f "$NNN_TMPFILE" ] || {
#         . "$NNN_TMPFILE"
#         rm -f -- "$NNN_TMPFILE" > /dev/null
#     }
# }
# ###########3

# zsh syntax highlighter
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Match the bright green used for executable filenames in ls.
ZSH_HIGHLIGHT_STYLES[arg0]='fg=10,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=10,bold,underline'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=10,bold,underline'

[ -f "/home/ujjwal/.ghcup/env" ] && . "/home/ujjwal/.ghcup/env" # ghcup-env

export PATH="/home/ujjwal/.local/share/gem/ruby/3.4.0/bin:$PATH"


# yazi cd on exit
function n() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}


alias books="cd ~/files/books"
export EDITOR='nvim'
export PATH="$HOME/.local/bin:$PATH"
typeset -U path PATH

# Starship prompt. Customize ~/.config/starship.toml.
eval "$(starship init zsh)"
