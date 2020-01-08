#-- clear Global PATH variable to unshadow the Universal PATH
#-- NOTE: set --show PATH
set -ge PATH

type -q exa; and alias ls=exa
type -q bat; and alias cat=bat

type -q lesspipe; and eval (lesspipe)
