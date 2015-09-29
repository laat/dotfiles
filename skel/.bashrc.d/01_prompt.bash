#!/bin/bash
function prompt_command {
    local White='\e[0;37m'        # White
    local Gray='\e[38;5;8m'       # Gray
    local BWhite='\e[1;37m'       # Bold White
    local BIRed='\e[1;91m'        # Bold Intensive Red
    local BIBlue='\e[1;94m'       # Bold Intensive Blue

    local Color_Off='\e[0m'       # Text Reset

    case "$TERM" in
        xterm-color) local color_prompt=yes;;
        xterm-256color) local color_prompt=yes;;
    esac

    if [ "$(whoami)" = root ]; then
        local user_color=$BRed
    else
        local user_color=$BWhite
    fi


    if [ "$color_prompt" = yes ]; then
        PS1="${user_color}\u${BWhite}@${White}\h:${BIBlue}\W/${Color_Off} ${Gray}\t${Color_Off}\n\$ "
    else
        PS1="\u@\h:\W/\n\$ "
    fi
}

PROMPT_COMMAND=prompt_command
