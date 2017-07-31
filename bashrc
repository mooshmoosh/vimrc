#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

alias vimdiff='nvim -d'

alias chd='chaido done'
alias chn='chaido new'
alias ch='chaido'

alias sql='q -O -T -d, -H'

PATH=$PATH:/home/wmischlewski/gitrepos/hackerscripts
PATH=$PATH:/home/wmischlewski/large-bin

if [ "$IN_NVIM_TERMINAL" != "YES" ]
then
    [ -z $TMUX ] && tmux
fi
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre/

function vim() {
    if [ "$IN_NVIM_TERMINAL" != "YES" ]
    then
        nvim $@
    else
        nvr --remote $@
    fi
}

alias thumb="python3 -c 'print(\"\U0001F44D\")' | xclip -in -selection \"clipboard\""
alias panda="python3 -c 'print(\"\U0001F43C\")' | xclip -in -selection \"clipboard\""
