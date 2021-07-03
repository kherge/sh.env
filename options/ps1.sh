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
    PS1="\[\e[90m\][\t]\[\e[0m\] \[\e[32m\]\W\[\e[0m\] \[\e[35m\]\$\[\e[0m\] "
}

###
# Cleans up.
##
__env_option_ps1_disable()
{
    # Restore the original prompt.
    if ! PS1="$(__env_config_get ps1.prompt)"; then
        return 1
    fi

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