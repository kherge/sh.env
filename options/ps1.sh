#!/bin/sh
################################################################################
# Prompt Option                                                                #
#                                                                              #
# Customizes the prompt with a simple, compact, colorful one.                  #
################################################################################

###
# Replaces the prompt.
##
__env_option_ps1_activate()
{
    if [ "$BASH_VERSION" != '' ]; then
        PS1="\[\e[90m\][\t]\[\e[0m\] \[\e[32m\]\W\[\e[0m\] \[\e[35m\]\$\[\e[0m\] "
    elif [ "$ZSH_VERSION" != '' ]; then
        PS1="%F{8}[%D{%H:%M:%S}]%F{none} %F{green}[%C]%F{none} %F{magenta}$%F{none} "
    else
        __env_debug "ps1: BASH or ZSH is required"

        return 1
    fi
}

###
# Cleans up.
##
__env_option_ps1_disable()
{
    local ORIGINAL

    # Restore the original prompt.
    if ! ORIGINAL="$(__env_config_get ps1.prompt)"; then
        return 1
    fi

    PS1="$ORIGINAL"

    # Clean up settings.
    if ! __env_config_set ps1.prompt ""; then
        return 1
    fi
}

###
# Sets the priority.
##
__env_option_ps1_enable()
{
    # Should be enabled before Starship.
    __ENV_PRIORITY=98

    # Backup the original prompt.
    if ! __env_config_set ps1.prompt "$PS1"; then
        return 1
    fi
}
