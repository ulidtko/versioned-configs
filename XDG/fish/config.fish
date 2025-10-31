#-- clear Global PATH variable to unshadow the Universal PATH
#-- then re-export the Universal PATH
#-- NOTE: set --show PATH
set -ge PATH
set -Ux PATH $PATH

#-- on Darwin, source /etc/paths
test -r /etc/paths && set --universal PATH (/bin/cat /etc/paths) || true

type -q exa; and alias ls='exa --icons'
type -q bat; and alias cat=bat

type -q lesspipe; and eval (lesspipe)

complete --command aws --no-files \
         --arguments '(begin; \
                set -lx COMP_SHELL fish; \
                set -lx COMP_LINE (commandline); \
                aws_completer | sed \'s/ $//\'; \
            end)'

#-- unpack k to kubectl
abbr --global k kubectl
