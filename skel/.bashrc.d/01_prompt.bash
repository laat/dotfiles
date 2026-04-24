#!/bin/bash
function prompt_command {
    local White='\e[0;37m'        # White
    local Gray='\e[38;5;8m'       # Gray
    local BWhite='\e[1;37m'       # Bold White
    local BIRed='\e[1;91m'        # Bold Intensive Red
    local BIBlue='\e[1;94m'       # Bold Intensive Blue

    local Color_Off='\e[0m'       # Text Reset

    if [ "$(tput colors 2>/dev/null || printf 0)" -ge 8 ]; then
        local color_prompt=yes
    fi

    if [ "$(whoami)" = root ]; then
        local user_color=$BIRed
    else
        local user_color=$BWhite
    fi


    if [ "$color_prompt" = yes ]; then
        PS1="${BIBlue}\W/${Color_Off} ${Gray}[\t]${Color_Off}\n\$ "
    else
        PS1="\u@\h:\W/\n\$ "
    fi
}

PROMPT_COMMAND=prompt_command
