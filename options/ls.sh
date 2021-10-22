#!/bin/sh
################################################################################
# Better List Option                                                           #
#                                                                              #
# Detects which version of `ls` is available and creates an alias with some    #
# useful options enabled. Any options not supported will not be included in    #
# the alias.                                                                   #
################################################################################

# shellcheck disable=SC2139
# shellcheck disable=SC3043

###
# Creates the alias.
##
__env_option_ls_activate()
{
    local COMMAND

    if ! COMMAND="$(__env_config_get ls.alias)"; then
        return 1
    fi

    alias la="ll -a"
    alias ll="$COMMAND"
}

###
# Cleans up.
##
__env_option_ls_disable()
{
    # Delete the alias.
    unset la
    unset ll

    # Delete the setting.
    if ! __env_config_set ls.alias ""; then
        return 1
    fi
}

###
# Configures the alias.
##
__env_option_ls_enable()
{
    local COMMAND

    # Using BSD version?
    if ! ls --help > /dev/null 2>&1; then
        __env_debug "using BSD version"

        COMMAND="ls -G -l"

    # Use GNU version?
    else
        __env_debug "using GNU version"

        COMMAND="ls --color=auto --group-directories-first --hide-control-chars --time-style=long-iso -l"
    fi

    if ! __env_config_set ls.alias "$COMMAND"; then
        return 1
    fi

    return 0
}
