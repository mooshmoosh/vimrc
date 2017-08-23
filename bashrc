#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '
shopt -s checkwinsize

alias vimdiff='nvim -d'

alias chd='chaido done'
alias ch='chaido'
alias chn='chaido new'

alias sql='q -O -T -d, -H'

if [ "$IN_NVIM_TERMINAL" != "YES" ]
then
    [ -z $TMUX ] && tmux
fi

function vim() {
    if [ "$IN_NVIM_TERMINAL" != "YES" ]
    then
        nvim $@
    else
        nvr --remote $@
    fi
}

PATH=$PATH:/home/wmischlewski/gitrepos/hackerscripts
PATH=$PATH:/home/wmischlewski/large-bin

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre/

function wget() {
    wget --ca-certificate=/home/wmischlewski/cert_backups/fortigate/bundle.crt $@
}

alias  thumb="python3 -c 'print(\"\U0001F44D\")' | xclip -in -selection \"clipboard\""
alias  panda="python3 -c 'print(\"\U0001F43C\")' | xclip -in -selection \"clipboard\""
alias bottle="python3 -c 'print(\"\U0001F37E\")' | xclip -in -selection \"clipboard\""

alias clip="xclip -in -selection \"clipboard\""
